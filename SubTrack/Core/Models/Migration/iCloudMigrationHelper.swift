//
//  iCloudMigrationHelper.swift
//  SubTrack
//
//  Created by Sam on 2025/6/10.
//
//  This helper is for advanced users: if you need to manually migrate data from a local-only store to iCloud (e.g., if users switch between storage modes and you want to copy their data), you can use migration logic here. For most users with CloudKit enabled, iCloud will automatically sync and restore data when the app is reinstalled, and ModelContainerManager provides backup/restore/export features.
//
import SwiftData
import CloudKit

@MainActor
class iCloudMigrationHelper {
    /// Example migration stub: migrate all `Subscription` data (and related models) from a local container to an iCloud-enabled container.
    ///
    /// Use this ONLY if you support manual switching of storage modes and want to migrate all user data.
    static func migrateLocalToCloudKit(localContainer: ModelContainer, iCloudContainer: ModelContainer) async throws {
        
        guard await checkiCloudAvailability() else {
            return
        }
        
        // Fetch all relevant objects from local context
        let localContext = ModelContext(localContainer)
        let iCloudContext = ModelContext(iCloudContainer)
        // Implement migration logic here if needed, for now this is left as a manual stub
        // Example (pseudocode):
        // let allSubscriptions = try localContext.fetch(FetchDescriptor<Subscription>())
        // for sub in allSubscriptions { ... iCloudContext.insert(copy) ... }
        // try iCloudContext.save()
        // See ModelContainerManager for backup/export/restore functionality.
    }
    
    private static func checkiCloudAvailability() async -> Bool {
        await withCheckedContinuation { continuation in
            CKContainer.default().accountStatus { status, error in
                continuation.resume(returning: status == .available)
            }
        }
    }
}
