//
//  ModelContainerManager.swift
//  SubTrack
//
//  Created by Sam on 2025/6/10.
//
import SwiftUI
import SwiftData
import CloudKit

// MARK: - Pure Codable Structures for Backup

struct ColorOptionBackup: Codable {
    let name: String
    let hex: String
}

struct SubscriptionBackup: Codable {
    let id: UUID
    let name: String
    let subscriptionDescription: String?
    let price: Decimal
    let currencyCode: String
    let period: Int
    let firstBillingDate: Date
    let tagIDs: [UUID]
    let icon: String
    let creditCardID: UUID?
    let colorHex: String
    let isActive: Bool
    let createdAt: Date
    let billingRecordIDs: [UUID]
}

struct BillingRecordBackup: Codable {
    let id: UUID
    let subscriptionId: UUID
    let billingDate: Date
    let amount: Decimal
    let currencyCode: String
    let isPaid: Bool
}

struct CreditCardBackup: Codable {
    let id: UUID
    let name: String
    let last4Digits: String
    // Changed from [String] to [ColorOptionBackup] to store both name and hex
    let colors: [ColorOptionBackup]
}

struct TagBackup: Codable {
    let id: UUID
    let name: String
}

struct BackupData: Codable {
    let subscriptions: [SubscriptionBackup]
    let billingRecords: [BillingRecordBackup]
    let creditCards: [CreditCardBackup]
    let tags: [TagBackup]
    let backupDate: Date
    let appVersion: String
}

// MARK: - ModelContainerManager
@MainActor
class ModelContainerManager: ObservableObject {
    enum StorageMode {
        case localOnly
        case iCloudSync
        var description: String {
            switch self {
            case .localOnly: return "Local Storage"
            case .iCloudSync: return "iCloud Sync"
            }
        }
    }
    enum MigrationState {
        case idle, migrating(Double), completed, failed(Error)
    }
    @Published var modelContainer: ModelContainer
    @Published var migrationState: MigrationState = .idle
    @Published var currentStorageMode: StorageMode
    @Published var isBackingUp: Bool = false
    @Published var isRestoring: Bool = false
    @Published var lastBackupDate: Date?
    @Published var lastBackupSize: Int64 = 0
    private static let backupFileName = "SubTrack_Backup.json"
    
    init() {
        let useiCloud = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        self.modelContainer = Self.createContainer(useiCloud: useiCloud)
        self.currentStorageMode = useiCloud ? .iCloudSync : .localOnly
        self.loadBackupInfo()
    }
    
    static func createContainer(useiCloud: Bool) -> ModelContainer {
        do {
            let schema = Schema([Subscription.self, BillingRecord.self, CreditCard.self, Tag.self])
            let config: ModelConfiguration
            if useiCloud {
                config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .automatic)
            } else {
                config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
            }
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Backup
    @MainActor
    func backupToiCloud() async throws {
        guard await checkiCloudAvailability() else {
            throw NSError(domain: "iCloud unavailable", code: 1)
        }
        isBackingUp = true
        defer { isBackingUp = false }
        do {
            let backupData = try await exportAllData()
            let jsonData = try JSONEncoder().encode(backupData)
            guard let iCloudURL = getICloudDocumentsURL() else {
                throw NSError(domain: "iCloud URL unavailable", code: 2)
            }
            let backupDirectoryURL = iCloudURL.appendingPathComponent("SubTrack_Backups")
            try FileManager.default.createDirectory(at: backupDirectoryURL, withIntermediateDirectories: true)
            let latestBackupURL = backupDirectoryURL.appendingPathComponent(Self.backupFileName)
            try jsonData.write(to: latestBackupURL)
            lastBackupDate = backupData.backupDate
            lastBackupSize = Int64(jsonData.count)
            saveBackupInfo()
        } catch {
            throw error
        }
    }
    
    // MARK: - Restore
    @MainActor
    func restoreFromiCloudBackup() async throws {
        guard await checkiCloudAvailability() else {
            throw NSError(domain: "iCloud unavailable", code: 1)
        }
        isRestoring = true
        defer { isRestoring = false }
        do {
            guard let iCloudURL = getICloudDocumentsURL() else {
                throw NSError(domain: "iCloud URL unavailable", code: 2)
            }
            let backupFileURL = iCloudURL.appendingPathComponent("SubTrack_Backups").appendingPathComponent(Self.backupFileName)
            guard FileManager.default.fileExists(atPath: backupFileURL.path) else {
                throw NSError(domain: "Backup file not found", code: 3)
            }
            let jsonData = try Data(contentsOf: backupFileURL)
            let backupData = try JSONDecoder().decode(BackupData.self, from: jsonData)
            try await clearAllData()
            try await importBackupData(backupData)
        } catch { throw error }
    }
    
    // MARK: - Export/Import Data
    private func exportAllData() async throws -> BackupData {
        let context = modelContainer.mainContext
        let subscriptions = try context.fetch(FetchDescriptor<Subscription>())
        let billingRecords = try context.fetch(FetchDescriptor<BillingRecord>())
        let creditCards = try context.fetch(FetchDescriptor<CreditCard>())
        let tags = try context.fetch(FetchDescriptor<Tag>())
        let subscriptionBackups = subscriptions.map { s in
            SubscriptionBackup(
                id: s.id,
                name: s.name,
                subscriptionDescription: s.subscriptionDescription,
                price: s.price,
                currencyCode: s.currencyCode,
                period: s.period.rawValue,
                firstBillingDate: s.firstBillingDate,
                tagIDs: s.tags?.compactMap { $0.id } ?? [],
                icon: s.icon,
                creditCardID: s.creditCard?.id,
                colorHex: s.colorHex,
                isActive: s.isActive,
                createdAt: s.createdAt,
                billingRecordIDs: s.billingRecords?.compactMap { $0.id } ?? []
            )
        }
        let billingRecordBackups = billingRecords.map { r in
            BillingRecordBackup(
                id: r.id,
                subscriptionId: r.subscriptionId,
                billingDate: r.billingDate,
                amount: r.amount,
                currencyCode: r.currencyCode,
                isPaid: r.isPaid
            )
        }
        let creditCardBackups = creditCards.map { c in
            // Export colors as array of ColorOptionBackup including both name and hex
            CreditCardBackup(
                id: c.id,
                name: c.name,
                last4Digits: c.last4Digits,
                colors: c.colors.map { ColorOptionBackup(name: $0.name, hex: $0.hex) }
            )
        }
        let tagBackups = tags.map { t in
            TagBackup(id: t.id, name: t.name)
        }
        return BackupData(
            subscriptions: subscriptionBackups,
            billingRecords: billingRecordBackups,
            creditCards: creditCardBackups,
            tags: tagBackups,
            backupDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }
    
    private func clearAllData() async throws {
        let context = modelContainer.mainContext
        try context.delete(model: Subscription.self)
        try context.delete(model: BillingRecord.self)
        try context.delete(model: CreditCard.self)
        try context.delete(model: Tag.self)
        try context.save()
    }
    
    private func importBackupData(_ backupData: BackupData) async throws {
        let context = modelContainer.mainContext
        
        // Import tags first to map them for subscription linking
        var tagMap = [UUID: Tag]()
        for t in backupData.tags {
            let tag = Tag(id: t.id, name: t.name)
            context.insert(tag)
            tagMap[t.id] = tag
        }
        
        // Import credit cards with full color info (both name and hex)
        var cardMap = [UUID: CreditCard]()
        for c in backupData.creditCards {
            // Rebuild colors using both name and hex from backup
            let colorOptions = c.colors.map { ColorOption(name: $0.name, hex: $0.hex) }
            let card = CreditCard(id: c.id, name: c.name, last4Digits: c.last4Digits, colors: colorOptions)
            context.insert(card)
            cardMap[c.id] = card
        }
        
        // Import subscriptions, fixing argument order: creditCard precedes icon
        var subscriptionMap = [UUID: Subscription]()
        for s in backupData.subscriptions {
            let tags = s.tagIDs.compactMap { tagMap[$0] }
            let card = s.creditCardID.flatMap { cardMap[$0] }
            
            // Convert period string back to Period enum, fallback to .monthly
            let periodEnum = Period(rawValue: s.period) ?? .monthly
            
            // Insert subscription with corrected initializer argument order
            let sub = Subscription(
                id: s.id,
                name: s.name,
                subscriptionDescription: s.subscriptionDescription,
                price: s.price,
                currencyCode: s.currencyCode,
                period: periodEnum,
                firstBillingDate: s.firstBillingDate,
                tags: tags,
                creditCard: card,      // creditCard before icon as per constructor
                icon: s.icon,
                colorHex: s.colorHex,
                isActive: s.isActive,
                createdAt: s.createdAt
            )
            context.insert(sub)
            subscriptionMap[s.id] = sub
        }
        
        // Import billing records with fixed initializer argument order matching model
        for r in backupData.billingRecords {
            // The billingRecord initializer expects subscriptionId, so no change needed
            let record = BillingRecord(
                id: r.id,
                subscriptionId: r.subscriptionId,
                billingDate: r.billingDate,
                amount: r.amount,
                currencyCode: r.currencyCode,
                isPaid: r.isPaid
            )
            context.insert(record)
        }
        
        try context.save()
    }
    
    // MARK: - iCloud Helper
    private func checkiCloudAvailability() async -> Bool {
        return await withCheckedContinuation { continuation in
            CKContainer.default().accountStatus { status, error in
                continuation.resume(returning: status == .available)
            }
        }
    }
    
    private func getICloudDocumentsURL() -> URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }
    
    // MARK: - Backup Info
    private func loadBackupInfo() {
        lastBackupDate = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
        lastBackupSize = UserDefaults.standard.object(forKey: "lastBackupSize") as? Int64 ?? 0
    }
    
    private func saveBackupInfo() {
        UserDefaults.standard.set(lastBackupDate, forKey: "lastBackupDate")
        UserDefaults.standard.set(lastBackupSize, forKey: "lastBackupSize")
    }
    
    // MARK: - Utility
    func getAvailableBackups() -> [URL] {
        guard let iCloudURL = getICloudDocumentsURL() else { return [] }
        let backupDirectoryURL = iCloudURL.appendingPathComponent("SubTrack_Backups")
        do {
            let files = try FileManager.default.contentsOfDirectory(at: backupDirectoryURL, includingPropertiesForKeys: [.creationDateKey])
            return files.filter { $0.pathExtension == "json" }
                .sorted { file1, file2 in
                    let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
        } catch { return [] }
    }
    
    /// Recreate the SwiftData model container using the chosen storage mode (local or iCloud).
    @MainActor
    func recreateContainer(useiCloud: Bool) async {
        // Only recreate if mode is different
        let newMode: StorageMode = useiCloud ? .iCloudSync : .localOnly
        if currentStorageMode != newMode {
            // Optionally perform backup here if needed
            currentStorageMode = newMode
            modelContainer = Self.createContainer(useiCloud: useiCloud)
            // Optionally reload backup info
            loadBackupInfo()
        }
    }
}
