//
//  AppUsageManager.swift
//  SubTrack
//
//  Created by Sam on 2025/4/7.
//
import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings


class AppUsageManager: ObservableObject {
    @EnvironmentObject var appSettings: AppSettings

    @Published var selection: FamilyActivitySelection = .init()
    @Published var isTracking: Bool = false
    
    private let center = DeviceActivityCenter()
    
    init() {
        // TODO: WAIT FOR APPLE APPROVAL
//        requestAuthorization()
    }
    
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                print("Failed to authorize: \(error)")
            }
        }
    }
    
    func startMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let token = DeviceActivityName("trackToken")
        let events = DeviceActivityEvent(applications: selection.applicationTokens, threshold: DateComponents(minute: 30))

        do {
            try center.startMonitoring(token, during: schedule, events: [.daily: events])
            isTracking = true
        } catch {
            print("Error starting monitoring: \(error)")
        }
    }
    
    func stopMonitoring() {
        let token = DeviceActivityName("trackToken")        
        center.stopMonitoring([token])
        isTracking = false
        
    }
}

extension DeviceActivityEvent.Name {
    static let daily = Self("daily")
}
