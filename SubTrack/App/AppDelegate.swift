//
//  AppDelegate.swift
//  SubTrack
//
//  Created by Sam on 2025/4/16.
//
import UIKit
import UserNotifications


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        
        UNUserNotificationCenter.current().delegate = self

        // Clear badge when app launches
        UNUserNotificationCenter.current().setBadgeCount(0)

        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
                
        // Handle the notification tap here
        if let subscriptionId = userInfo["subscriptionId"] as? String {
            // You can post a notification or use a coordinator to navigate to the subscription
            NotificationCenter.default.post(
                name: .openSubscriptionDetail,
                object: nil,
                userInfo: ["subscriptionId": subscriptionId]
            )
        }
        
        // Clear badge
        UNUserNotificationCenter.current().setBadgeCount(0)
        
        completionHandler()
    }
}

extension Notification.Name {
    static let openSubscriptionDetail = Notification.Name("openSubscriptionDetail")
}
