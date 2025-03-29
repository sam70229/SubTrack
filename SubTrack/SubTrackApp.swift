//
//  SubTrackApp.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//

import SwiftUI
import SwiftData

@main
struct SubTrackApp: App {
    @StateObject private var appSettings: AppSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .environmentObject(appSettings)
    }
}
