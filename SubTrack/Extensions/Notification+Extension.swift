//
//  Notification+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/6/9.
//
import Foundation

extension Notification.Name {
    static let openSubscriptionDetail = Notification.Name("openSubscriptionDetail")
    
    // iCloud
    static let iCloudSyncPreferenceChanged = Notification.Name("iCloudSyncPreferenceChanged")
    static let modelContainerRecreated = Notification.Name("modelContainerRecreated")
    static let iCloudBackupPreferenceChanged = Notification.Name("iCloudBackupPreferenceChanged")
    static let backupCompleted = Notification.Name("backupCompleted")
    static let backupFailed = Notification.Name("backupFailed")
    static let restoreCompleted = Notification.Name("restoreCompleted")
    static let restoreFailed = Notification.Name("restoreFailed")
}
