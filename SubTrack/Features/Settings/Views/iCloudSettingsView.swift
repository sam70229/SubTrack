//
//  iCloudSettingsView.swift
//  SubTrack
//
//  Created by Sam on 2025/6/9.
//
import SwiftUI


struct iCloudSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var showingMigrationAlert: Bool = false
    @State private var showingDisableAlert: Bool = false
    @State private var isMigrating: Bool = false
    @State private var migrationProgress: Double = 0
    
    var body: some View {
        Form {
            Section {
                Toggle("Sync with iCloud", isOn: Binding(
                    get: { appSettings.iCloudSyncEnabled },
                    set: { newValue in
                        if newValue {
                            showingMigrationAlert = true
                        } else {
                            showingDisableAlert = true
                        }
                    }
                ))
                
                if appSettings.iCloudSyncEnabled {
                    Label("Your data is synced across all your devices", systemImage: "checkmark.icloud")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Label("Data is stored locally on this device only", systemImage: "iphone")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } footer: {
                Text("When enabled, your subscriptions will sync across all devices signed into the same iCloud account.")
            }
            
            if appSettings.iCloudSyncEnabled {
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("iCloud Sync Status")
                            .font(.headline)
                    }
                    
                    SyncStatusRow(title: "Last Sync", systemImage: "clock") {
                        Text("Just now") // You can implement actual sync tracking
                            .foregroundColor(.secondary)
                    }
                    
                    // TODO: - Find a way to calculate this
//                    SyncStatusRow(title: "Storage Used", systemImage: "internaldrive") {
//                        Text("< 1 MB") // You can calculate actual storage
//                            .foregroundColor(.secondary)
//                    }
                } header: {
                    Text("Sync Information")
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Privacy Note", systemImage: "lock.shield")
                        .font(.headline)
                    
                    Text("Your subscription data is private and encrypted. Only you can access your data through your iCloud account.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Enable iCloud Sync?", isPresented: $showingMigrationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Enable") {
                Task {
                    await enableiCloudSync()
                }
            }
        } message: {
            Text("Your local data will be uploaded to iCloud and synced across all your devices. This may take a few moments.")
        }
        .alert("Disable iCloud Sync?", isPresented: $showingDisableAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                Task {
                    await disableiCloudSync()
                }
            }
        } message: {
            Text("Your data will remain on iCloud but this device will use local storage only. You can re-enable sync anytime to access your iCloud data.")
        }
        .overlay {
            if isMigrating {
                MigrationOverlay(progress: migrationProgress)
            }
        }
    }
    
    private func enableiCloudSync() async {
        isMigrating = true
        migrationProgress = 0
        
        // Simulate migration progress
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            migrationProgress = Double(i) / 10.0
        }
        
        appSettings.iCloudSyncEnabled = true
        isMigrating = false
    }
    
    private func disableiCloudSync() async {
        appSettings.iCloudSyncEnabled = false
    }
}


struct SyncStatusRow<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundColor(.primary)
            Spacer()
            content()
        }
    }
}


struct MigrationOverlay: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Migrating to iCloud...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(width: 200)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
        }
    }
}


#Preview {
    iCloudSettingsView()
        .environmentObject(AppSettings())
}
