//
//  iCloudMigrationHelper.swift
//  SubTrack
//
//  Created by Sam on 2025/6/10.
//

//
// Without CloudKit:
// User → SwiftData → Local SQLite Database
//
// With CloudKit:
// User → SwiftData → Local SQLite Database → CloudKit Sync → iCloud
//                            ↑                                  ↓
//                            ←──────── Sync Changes ────────────
//
// ┌─────────────────────────────────────────────────────────────┐
// │                      LOCAL-ONLY MODE                        │
// ├─────────────────────────────────────────────────────────────┤
// │  App → SwiftData → Local SQLite (LocalOnly.sqlite)          │
// │                                                             │
// │  ✓ Fast access                                              │
// │  ✓ Works offline                                            │
// │  ✗ No sync between devices                                  │
// └─────────────────────────────────────────────────────────────┘
//
// ┌─────────────────────────────────────────────────────────────-┐
// │                      iCLOUD SYNC MODE                        │
// ├─────────────────────────────────────────────────────────────-┤
// │  App → SwiftData → Local SQLite (CloudKit.sqlite) ←→ iCloud  │
// │                            ↓                           ↑     │
// │                     (Still stored locally)      (Sync Layer) │
// │                                                              │
// │  ✓ Fast access (reads from local)                            │
// │  ✓ Works offline (uses local cache)                          │
// │  ✓ Syncs between devices                                     │
// │  ✓ Automatic conflict resolution                             │
// └─────────────────────────────────────────────────────────────-┘
//
import SwiftUI
import SwiftData


@MainActor
class iCloudMigrationHelper {
    
    static func migrateData(from sourceContainer: ModelContainer, to destinationContainer: ModelContainer) async throws {
        let sourceContext = ModelContext(sourceContainer)
        let destinationContext = ModelContext(destinationContainer)
        
        let subscriptions = try await fetchAllSubscriptions(from: sourceContext)
        var subscriptionMapping: [UUID: Subscription] = [:]
        
        for subscription in subscriptions {
            let newSubscription = Subscription(
                id: subscription.id,
                name: subscription.name,
                subscriptionDescription: subscription.subscriptionDescription,
                price: subscription.price,
                currencyCode: subscription.currencyCode,
                period: subscription.period,
                firstBillingDate: subscription.firstBillingDate,
                tags: subscription.tags,
                creditCard: nil, // We'll set this after migrating credit cards
                icon: subscription.icon,
                colorHex: subscription.colorHex,
                isActive: subscription.isActive,
                createdAt: subscription.createdAt
            )
            destinationContext.insert(newSubscription)
            subscriptionMapping[subscription.id] = newSubscription
        }
        
        // Migrate Credit Cards
//        let creditCards = try await
    }
    
    private static func fetchAllSubscriptions(from content: ModelContext) async throws -> [Subscription] {
        let descriptor = FetchDescriptor<Subscription>()
        return try content.fetch(descriptor)
    }
    
    private static func fetchAllCreditCards(from content: ModelContext) async throws -> [CreditCard] {
        let descriptor = FetchDescriptor<CreditCard>()
        return try content.fetch(descriptor)
    }
    
    private static func fetchAllBillingRecords(from content: ModelContext) async throws -> [BillingRecord] {
        let descriptor = FetchDescriptor<BillingRecord>()
        return try content.fetch(descriptor)
    }
    
    // Safe cleanup - only removes the OLD storage mode's data after successful migration
    static func cleanupAfterMigration(oldStorageMode: ModelContainerManager.StorageMode) async throws {
        // IMPORTANT: This only cleans up the storage mode you're migrating FROM
        // The new storage mode (whether local or CloudKit) remains active
        
        let context = ModelContext(ModelContainerManager.createContainer(useiCloud: oldStorageMode == .iCloudSync))
        
        // Verify the new storage has data before cleaning old storage
        let subscriptionCount = try context.fetchCount(FetchDescriptor<Subscription>())
        
        if subscriptionCount > 0 {
            // Safe to clean up old storage
            ModelContainerManager.cleanupOldStorage(for: oldStorageMode)
            print("Successfully cleaned up old \(oldStorageMode) storage")
        } else {
            throw DataMigrationError.migrationFailed("New storage appears empty, not cleaning up old data")
        }
    }
}

