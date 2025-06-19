//
//  IdentityManager.swift
//  SubTrack
//
//  Created by Sam on 2025/6/18.
//
import SwiftUI
import SwiftData

final class IdentityManager: ObservableObject {
    // Note: modelContext must be set before using methods
    static let shared = IdentityManager()
    
    var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    @Published var deviceID: String = ""
    
    func createDeviceID() {
        guard let modelContext = modelContext else { return }
        if deviceID != "" {
            return
        }
        
        let fetch = FetchDescriptor<UserIdentity>()
        if let exist = try? modelContext.fetch(fetch).first {
            deviceID = exist.deviceId
        } else {
            let newID = UUID().uuidString
            let newUserIdentity = UserIdentity(deviceId: newID)
            modelContext.insert(newUserIdentity)
            try? modelContext.save()
            deviceID = newID
        }
    }
}
