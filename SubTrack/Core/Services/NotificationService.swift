//
//  NotificationService.swift
//  SubTrack
//
//  Created by Sam on 2025/6/2.
//
import UserNotifications


class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized: Bool = false
    let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleNotification(for subscription: Subscription, reminderOption: NotificationDate) async throws {
        guard isAuthorized else {
            let granted = await requestAuthorization()
            guard granted else {
                throw NotificationError.notAuthorized
            }
            return
        }
        
        await cancelNotifications(for: subscription)

        let notificationDates = calculateNotificationDates(
            for: subscription,
            reminderOption: reminderOption,
            numberOfCycles: 3 // Schedule for the next 3 cycles
        )

        for (index, date) in notificationDates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Subscription Reminder"
            content.body = "Your subscription '\(subscription.name)' is due on \(date.formatted()). Price: \(formatPrice(subscription.price, currency: subscription.currencyCode))."
            content.sound = .default
            content.badge = 1
            
            // Create a unique identifier for each notification
            content.userInfo = [
                "subscriptionId": subscription.id.uuidString,
                "subscriptionName": subscription.name,
                "amount": "\(subscription.price)",
                "currency": subscription.currencyCode
            ]
            
            // Create date components for the notification
            let dateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            // Create unique identifier for each notification
            let identifier = "\(subscription.id.uuidString)-\(index)"
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            try await notificationCenter.add(request)
            logInfo("Scheduled notification for \(subscription.name) on \(date)")
        }
    }
    
    func cancelNotifications(for subscription: Subscription) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        
        let notificationIDs = pending
            .filter { $0.identifier.starts(with: subscription.id.uuidString) }
            .map { $0.identifier }
        
        if !notificationIDs.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: notificationIDs)
        }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    // MARK: - Helper Methods
    
    private func calculateNotificationDates(
        for subscription: Subscription,
        reminderOption: NotificationDate,
        numberOfCycles: Int
    ) -> [Date] {
        var dates: [Date] = []
        var nextBillingDate = subscription.nextBillingDate
        let calendar = Calendar.current
        
        for _ in 0..<numberOfCycles {
            // Calculate reminder date based on option
            let reminderDate: Date
            switch reminderOption {
            case .one_day_before:
                reminderDate = calendar.date(byAdding: .day, value: -1, to: nextBillingDate) ?? nextBillingDate
            case .three_day_before:
                reminderDate = calendar.date(byAdding: .day, value: -3, to: nextBillingDate) ?? nextBillingDate
            case .one_week_before:
                reminderDate = calendar.date(byAdding: .day, value: -7, to: nextBillingDate) ?? nextBillingDate
            }

            logInfo("reminderDate: \(reminderDate)")
            // Set notification time to 10 AM
            if let finalDate = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: reminderDate) {
                dates.append(finalDate)
            }

            // Calculate next billing date
            nextBillingDate = subscription.period.calculateNextDate(from: nextBillingDate)
        }
        
        return dates
    }
    
    private func formatPrice(_ price: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }
    
    // MARK: - Get Scheduled Notifications
    
    func getScheduledNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
    
    func getScheduledNotifications(for subscription: Subscription) async -> [UNNotificationRequest] {
        let pending = await notificationCenter.pendingNotificationRequests()
        return pending.filter { $0.identifier.starts(with: subscription.id.uuidString) }
    }
    
    func getScheduledNotificationsCount(for subscription: Subscription) async -> Int {
        let pending = await notificationCenter.pendingNotificationRequests()
        return pending.filter { $0.identifier.starts(with: subscription.id.uuidString) }.count
    }
}


enum NotificationError: Error {
    case notAuthorized
    
    var errorDescription: String {
        switch self {
        case .notAuthorized:
            return "Notification authorization is required to schedule notifications."
        }
    }
}
