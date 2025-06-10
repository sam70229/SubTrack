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
    
}

