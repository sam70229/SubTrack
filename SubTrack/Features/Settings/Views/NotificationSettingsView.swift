//
//  NotificationSettingsView.swift
//  SubTrack
//
//  Created by Sam on 2025/6/2.
//
import SwiftUI
import SwiftData


struct NotificationSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    @Query private var subscriptions: [Subscription]
    @StateObject private var notificationService = NotificationService.shared
    
    @State private var showingPermissionAlert = false
    @State private var isRefreshing = false
    
    var enabledNotificationSubscriptions: [Subscription] {
        subscriptions.filter { $0.isNotificationEnabled }
    }
    
    var body: some View {
        List {
            permissionSection
            
            // Global Settings
            if notificationService.isAuthorized {
                globalSettingsSection
                
                // Active Notifications
                if !enabledNotificationSubscriptions.isEmpty {
                    activeNotificationsSection
                }
                
                // Subscriptions without notifications
                let disabledSubscriptions = subscriptions.filter { !$0.isNotificationEnabled }
                if !disabledSubscriptions.isEmpty {
                    availableSubscriptionsSection(subscriptions: disabledSubscriptions)
                }
            }
            
            // Notification Testing Purpose
            Button {
                Task {
                    do {
                        try await NotificationService.shared.scheduleTestNotification()
                        // Show success message
                    } catch {
                        // Show error
                    }
                }
            } label: {
                Label("Send Test Notification", systemImage: "bell.and.waveform")
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshNotificationStatus()
        }
        .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications in Settings to receive payment reminders")
        }
    }
    
    private var permissionSection: some View {
        Section {
            HStack {
                Image(systemName: notificationService.isAuthorized ? "bell.fill" : "bell.slash.fill")
                    .foregroundStyle(notificationService.isAuthorized ? .green : .red)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Status")
                        .font(.headline)
                    
                    Text(notificationService.isAuthorized ? "Notifications are enabled." : "Notifications are disabled.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !notificationService.isAuthorized {
                    Button("Enable") {
                        Task {
                            let granted = await notificationService.requestAuthorization()
                            if !granted {
                                showingPermissionAlert = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var globalSettingsSection: some View {
        Section {
            // Quick enable all
            Button {
                enableAllNotifications()
            } label: {
                Label("Enable All Reminders", systemImage: "bell.badge")
            }
            
            // Quick disable all
            Button(role: .destructive) {
                disableAllNotifications()
            } label: {
                Label("Disable All Reminders", systemImage: "bell.slash")
            }
        } header: {
            Text("Quick Actions")
        }
    }
    
    private var activeNotificationsSection: some View {
        Section {
            ForEach(enabledNotificationSubscriptions) { subscription in
                NotificationRow(subscription: subscription)
            }
        } header: {
            Text("Active Reminders")
        } footer: {
            Text("\(enabledNotificationSubscriptions.count) subscription\(enabledNotificationSubscriptions.count == 1 ? "" : "s") with notifications enabled")
        }
    }
    
    private func availableSubscriptionsSection(subscriptions: [Subscription]) -> some View {
        Section {
            ForEach(subscriptions) { subscription in
                NotificationRow(subscription: subscription)
            }
        } header: {
            Text("Available Subscriptions")
        }
    }
    
    // MARK: - Actions
    
    private func enableAllNotifications() {
        for subscription in subscriptions {
            subscription.isNotificationEnabled = true
            subscription.notificationTiming = .three_day_before
            Task {
                await subscription.scheduleNotifications()
            }
        }
    }
    
    private func disableAllNotifications() {
        for subscription in subscriptions {
            subscription.isNotificationEnabled = false
            Task {
                await NotificationService.shared.cancelNotifications(for: subscription)
            }
        }
    }
    
    private func refreshNotificationStatus() async {
        isRefreshing = true
        notificationService.checkAuthorizationStatus()
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        isRefreshing = false
    }
}

// MARK: - Notification Row Component

struct NotificationRow: View {
    let subscription: Subscription
    @State private var isEnabled: Bool
    @State private var timing: NotificationDate
    @State private var isLoading = false
    
    init(subscription: Subscription) {
        self.subscription = subscription
        self._isEnabled = State(initialValue: subscription.isNotificationEnabled)
        self._timing = State(initialValue: subscription.notificationTiming)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main toggle row
            HStack {
                Image(systemName: subscription.icon)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(subscription.color)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(.body)
                    Text("Next Billing Date: \(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .disabled(isLoading)
                    .onChange(of: isEnabled) { _, newValue in
                        updateNotificationStatus(newValue)
                    }
            }
            
            // Timing picker (only show when enabled)
            if isEnabled {
                VStack {
                    Text("Remind me")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $timing) {
                        ForEach(NotificationDate.allCases) { option in
                            Text(LocalizedStringKey(option.description)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(isLoading)
                    .onChange(of: timing) { _, newValue in
                        updateNotificationTiming(newValue)
                    }
                }
                .padding(.leading, 36) // Align with text
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
    
    private func updateNotificationStatus(_ enabled: Bool) {
        isLoading = true
        subscription.isNotificationEnabled = enabled
        
        Task {
            await subscription.scheduleNotifications()
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func updateNotificationTiming(_ newTiming: NotificationDate) {
        isLoading = true
        subscription.notificationTiming = newTiming
        
        Task {
            await subscription.scheduleNotifications()
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
