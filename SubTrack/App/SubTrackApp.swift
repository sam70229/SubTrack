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
    @StateObject private var modelContainerManager: ModelContainerManager
    
    // Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create a shared model container for the entire app
//    let modelContainer: ModelContainer
    
    init() {
        // TODO: - Register custom transformers for CloudKit
//        TagArrayTransformer.register()
//        ColorOptionArrayTransformer.register()
        
        
        let manager = ModelContainerManager()
        _modelContainerManager = StateObject(wrappedValue: manager)
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appSettings)
                .environmentObject(appUsageManager)
                .environmentObject(exchangeRates)
                .environmentObject(modelContainerManager)
                .environmentObject(notificationService)
                //.modelContainer(modelContainer)  // Inject the model container into the SwiftUI environment
                .modelContainer(modelContainerManager.modelContainer)
                .preferredColorScheme(appSettings.colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .iCloudSyncPreferenceChanged)) { _ in
                    Task {
                        await modelContainerManager.recreateContainer(useiCloud: appSettings.iCloudSyncEnabled)
                    }
                }
        }
    }
}
