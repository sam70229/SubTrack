//
//  iCloudSettingsView.swift
//  SubTrack
//
//  Created by Sam on 2025/6/9.
//
import SwiftUI
import CloudKit


struct iCloudSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var modelContainerManager: ModelContainerManager
    
    @State private var showingMigrationAlert: Bool = false
    @State private var showingDisableAlert: Bool = false
    @State private var showingBackupAlert: Bool = false
    @State private var showingRestoreAlert: Bool = false
    @State private var showingRestoreConfirmation: Bool = false
    @State private var showingError: Bool = false
    
    @State private var isMigrating: Bool = false
    @State private var migrationProgress: Double = 0
    
    @State private var errorMessage: String = ""
    @State private var iCloudStatus: String = ""
    @State private var containerIdentifier: String = ""
    @State private var availableBackups: [URL] = []
    
    var body: some View {
        Form {
            iCloudSyncSection
            
            // TODO: - Find a proper way to do this, cz now this backup code is chaos
//            iCloudBackupSection
            
            privacyNote
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshData()
        }
        .onAppear {
            Task {
                await refreshData()
            }
        }
        .alert("Enable iCloud Sync?", isPresented: $showingMigrationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Enable") {
                Task {
                    await enableiCloudSync()
                }
            }
        } message: {
            Text("Your local data will be uploaded to iCloud and synced across all your devices. This may take a few moments.")
        }
        .alert("Disable iCloud Sync?", isPresented: $showingDisableAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                Task {
                    await disableiCloudSync()
                }
            }
        } message: {
            Text("Your data will remain on iCloud but this device will use local storage only. You can re-enable sync anytime to access your iCloud data.")
        }
        .alert("Create Backup?", isPresented: $showingBackupAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Backup") {
                Task {
                    await performBackup()
                }
            }
        } message: {
            Text("This will create a backup of all your subscription data in your iCloud Drive.")
        }
        .alert("Restore from Backup?", isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                showingRestoreConfirmation = true
            }
        } message: {
            Text("This will restore your data from the latest backup. Your current data will be replaced.")
        }
        .alert("⚠️ Confirm Restore", isPresented: $showingRestoreConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Replace Data", role: .destructive) {
                Task {
                    await performRestore()
                }
            }
        } message: {
            Text("This action cannot be undone. All current data will be replaced with the backup data.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var iCloudSyncSection: some View {
        Section {
            Toggle("Sync with iCloud", isOn: Binding(
                get: { appSettings.iCloudSyncEnabled },
                set: { newValue in
                    if newValue {
                        showingMigrationAlert = true
                    } else {
                        showingDisableAlert = true
                    }
                }
            ))
            
            if appSettings.iCloudSyncEnabled {
                Label("Your data is synced across all your devices", systemImage: "checkmark.icloud")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Label("Data is stored locally on this device only", systemImage: "iphone")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        } footer: {
            Text("When enabled, your subscriptions will sync across all devices signed into the same iCloud account.")
        }
    }
    
    private var iCloudBackupSection: some View {
        Section {
            Toggle("Backup to iCloud", isOn: $appSettings.iCloudBackupEnabled)
            
            if appSettings.iCloudBackupEnabled {
                Button {
                    showingBackupAlert = true
                } label: {
                    HStack {
                        Label("Backup to iCloud", systemImage: "icloud.and.arrow.up")

                        Spacer()

                        if modelContainerManager.isBackingUp {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(modelContainerManager.isBackingUp)
                
                Button {
                    showingRestoreAlert = true
                } label: {
                    HStack {
                        Label("Restore from Backup", systemImage: "icloud.and.arrow.down")

                        Spacer()

                        if modelContainerManager.isRestoring {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(modelContainerManager.isRestoring)
                
                let backupDate = UserDefaults.standard.object(forKey: "backupDate") as? Date
                let backupSize = UserDefaults.standard.object(forKey: "backupSize") as? Int64
                
                SyncStatusRow(title: "Last Backup", systemImage: "clock") {
                    Text(backupDate?.formatted(date: .abbreviated, time: .shortened) ?? "Never") // You can implement actual sync tracking
                        .foregroundColor(.secondary)
                }
                
                SyncStatusRow(title: "Backup Size", systemImage: "internaldrive") {
                    Text(ByteCountFormatter.string(fromByteCount: backupSize ?? 0, countStyle: .file))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var privacyNote: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Privacy Note", systemImage: "lock.shield")
                    .font(.headline)
                
                Text("Your subscription data is private and encrypted. Only you can access your data through your iCloud account.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func refreshData() async {
        await getiCloudStatus()
        // TODO: - Find a proper way to do this, cz now this backup code is chaos
        loadAvailableBackups()
    }
    
    private func getiCloudStatus() async {
        let (statusString, containerID): (String, String) = await withCheckedContinuation { continuation in
            CKContainer.default().accountStatus { status, error in
                let statusString: String
                switch status {
                case .available:
                    statusString = "Available"
                case .noAccount:
                    statusString = "No Account"
                case .restricted:
                    statusString = "Restricted"
                case .couldNotDetermine:
                    statusString = "Could Not Determine"
                case .temporarilyUnavailable:
                    statusString = "Temporarily Unavailable"
                @unknown default:
                    statusString = "Unknown"
                }
                let containerID = CKContainer.default().containerIdentifier ?? "Unknown"
                continuation.resume(returning: (statusString, containerID))
            }
        }
        await MainActor.run {
            self.iCloudStatus = statusString
            self.containerIdentifier = containerID
        }
    }
    
    func loadAvailableBackups() {
        availableBackups = modelContainerManager.getAvailableBackups()
    }
    
    func enableiCloudSync() async {
        appSettings.iCloudSyncEnabled = true
        await modelContainerManager.recreateContainer(useiCloud: true)
    }
    
    func disableiCloudSync() async {
        appSettings.iCloudSyncEnabled = false
        await modelContainerManager.recreateContainer(useiCloud: false)
    }
    
    func performBackup() async {
        do {
            try await modelContainerManager.backupToiCloud()
            await refreshData()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    func performRestore() async {
        do {
            try await modelContainerManager.restoreFromiCloudBackup()
            await refreshData()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}


struct SyncStatusRow<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundColor(.primary)
            Spacer()
            content()
        }
    }
}


struct MigrationOverlay: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Migrating to iCloud...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(width: 200)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
        }
    }
}


#Preview {
    iCloudSettingsView()
        .environmentObject(AppSettings())
}

