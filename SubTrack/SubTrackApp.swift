//
//  SubTrackApp.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//

import SwiftUI
import SwiftData
import Firebase
import FirebaseFirestore


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        return true
    }
}

@main
struct SubTrackApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var appUsageManager = AppUsageManager()
    
    // Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create a shared model container for the entire app
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Define your schema with all model types
            let schema = Schema([
                Subscription.self,
                Category.self
                // Add other model types as needed
            ])
            
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appSettings)
            // Inject the model container into the SwiftUI environment
                .modelContainer(modelContainer)
                .preferredColorScheme(appSettings.colorScheme)
                .environmentObject(appUsageManager)
        }
    }
}
