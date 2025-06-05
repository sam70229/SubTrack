//
//  NotificationListView.swift
//  SubTrack
//
//  Created by Sam on 2025/6/5.
//
import SwiftUI

struct NotificationListView: View {
    let subscription: Subscription
    @State private var notifications: [UNNotificationRequest] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if notifications.isEmpty {
                Text("No scheduled notifications")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(notifications, id: \.identifier) { notification in
                        if let calendarTrigger = notification.trigger as? UNCalendarNotificationTrigger {
                           Text("\(Calendar.current.date(from: calendarTrigger.dateComponents) ?? Date())")
                        }
                    }
                }
            }
        }
        .task {
            notifications = await NotificationService.shared.getScheduledNotifications(for: subscription)
            isLoading = false
        }
    }
}

