//
//  IdentityManager.swift
//  SubTrack
//
//  Created by Sam on 2025/6/18.
//
import SwiftUI
import SwiftData

@MainActor
final class IdentityManager: ObservableObject {
    private let modelContext: ModelContext
    @Published private(set) var deviceID: String = ""
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Loads or creates device ID from persistent storage
    /// - Throws: Database errors if fetch or save fails
    func loadDeviceID() throws {
        // Early return if already loaded
        guard deviceID.isEmpty else { return }
        
        let fetchDescriptor = FetchDescriptor<UserIdentity>()
        
        // Try to fetch existing identity
        if let existingIdentity = try modelContext.fetch(fetchDescriptor).first {
            deviceID = existingIdentity.deviceId
            logInfo("Loaded existing device ID: \(deviceID)")
        } else {
            // Migration: Check if there's an old device ID in AppStorage
            if let legacyDeviceID = UserDefaults.standard.string(forKey: "device_id"),
               !legacyDeviceID.isEmpty {
                // Migrate from AppStorage to SwiftData
                let migratedIdentity = UserIdentity(deviceId: legacyDeviceID)
                modelContext.insert(migratedIdentity)
                try modelContext.save()
                deviceID = legacyDeviceID
                logInfo("Migrated device ID from AppStorage: \(deviceID)")
                
                // Remove old value (optional - keep for backwards compatibility)
                // UserDefaults.standard.removeObject(forKey: "device_id")
            } else {
                // Create new identity
                let newID = UUID().uuidString
                let newIdentity = UserIdentity(deviceId: newID)
                modelContext.insert(newIdentity)
                try modelContext.save()
                deviceID = newID
                logInfo("Created new device ID: \(deviceID)")
            }
        }
    }
    
    /// Convenience method that doesn't throw - logs errors instead
    func createDeviceID() {
        do {
            try loadDeviceID()
        } catch {
            logError("Failed to load device ID: \(error)")
        }
    }
}
