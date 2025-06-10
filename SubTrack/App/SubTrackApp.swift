//
//  SubTrackApp.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//


// Without CloudKit:
// User → SwiftData → Local SQLite Database
//
// With CloudKit:
// User → SwiftData → Local SQLite Database → CloudKit Sync → iCloud
//                            ↑                                  ↓
//                            ←──────── Sync Changes ────────────

import SwiftUI
import SwiftData
import Supabase

@main
struct SubTrackApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var appUsageManager = AppUsageManager()
    @StateObject private var exchangeRates = ExchangeRateRepository()
    @StateObject private var notificationService = NotificationService()
    
    // Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create a shared model container for the entire app
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Define your schema with all model types
            let schema = Schema([
                Subscription.self,
                BillingRecord.self,
                CreditCard.self
                // Add other model types as needed
            ])
            
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .automatic
            )
            
//            modelContainer = try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: config)
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appSettings)
                .environmentObject(appUsageManager)
                .environmentObject(exchangeRates)
                .environmentObject(notificationService)
                .modelContainer(modelContainer)  // Inject the model container into the SwiftUI environment
                .preferredColorScheme(appSettings.colorScheme)
        }
    }
}
