//
//  ModelContainerManager.swift
//  SubTrack
//
//  Created by Sam on 2025/6/10.
//
import SwiftUI
import SwiftData


class ModelContainerManager: ObservableObject {
    @Published var modelContainer: ModelContainer
    
    init() {
        let useiCloud = UserDefaults.standard.bool(forKey: "iCloudSyncEnables")
        self.modelContainer = Self.createContainer(useiCloud: useiCloud)
    }
    
    static func createContainer(useiCloud: Bool) -> ModelContainer {
        do {
            let schema = Schema([Subscription.self, BillingRecord.self, CreditCard.self])
            
            let config: ModelConfiguration
            
            if useiCloud {
                // Use CloudKit configuration
                config = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true,
                    cloudKitDatabase: .automatic
                )
            } else {
                // Use local-only configuration
                config = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true,
                    cloudKitDatabase: .none // Explicitly disable CloudKit
                )
            }
            
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    @MainActor
    func recreateContainer(useiCloud: Bool) async {
        // Store reference to old container for migration
        let oldContainer = modelContainer
        let wasUsingiCloud = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        
        // Create new container with different configuration
        let newContainer = Self.createContainer(useiCloud: useiCloud)
        
        // Migrate data if switching storage types
        if wasUsingiCloud != useiCloud {
            do {
                try await iCloudMigrationHelper.migrateData(
                    from: oldContainer,
                    to: newContainer
                )
                
                // Optional: Clear old data after successful migration
                // Uncomment if you want to remove data from the old storage
                // try await DataMigrationHelper.clearSourceData(from: oldContainer)
                
                print("Data migration completed successfully")
            } catch {
                print("Data migration failed: \(error)")
                // You might want to show an alert to the user here
            }
        }
        
        // Update container
        modelContainer = newContainer
        
        // Post notification for views to refresh
        NotificationCenter.default.post(
            name: .modelContainerRecreated,
            object: nil
        )
    }
}


extension ModelContainerManager {
    
}
