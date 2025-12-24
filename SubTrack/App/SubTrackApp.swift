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
    @StateObject private var identityManager: IdentityManager
    
    // Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // TODO: - Register custom transformers for CloudKit
//        ColorOptionArrayTransformer.register()
        
        let manager = ModelContainerManager()
        _modelContainerManager = StateObject(wrappedValue: manager)
        
        // Create IdentityManager with modelContext from container
        let context = manager.modelContainer.mainContext
        let identity = IdentityManager(modelContext: context)
        _identityManager = StateObject(wrappedValue: identity)
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appSettings)
                .environmentObject(appUsageManager)
                .environmentObject(exchangeRates)
                .environmentObject(modelContainerManager)
                .environmentObject(notificationService)
                .environmentObject(identityManager)
                .modelContainer(modelContainerManager.modelContainer)
                .preferredColorScheme(appSettings.colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .iCloudSyncPreferenceChanged)) { _ in
                    Task {
                        await modelContainerManager.recreateContainer(useiCloud: appSettings.iCloudSyncEnabled)
                    }
                }
                .task {
                    // Load device ID on app launch
                    identityManager.createDeviceID()
                }
        }
    }
}
