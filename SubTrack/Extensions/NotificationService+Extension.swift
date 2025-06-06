//
//  NotificationService+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/6/2.
//
import SwiftUI

extension NotificationService {
    
    // Schedule a test notification in 10 seconds
    func scheduleTestNotification() async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Test Notification 🎉"
        content.body = "Notifications are working! Your payment reminders will appear like this."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        
        try await notificationCenter.add(request)
    }
}
