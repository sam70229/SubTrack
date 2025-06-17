//
//  StorageManage.swift
//  SubTrack
//
//  Created by Sam on 2025/6/10.
//
import Foundation
import CloudKit


struct StorageInfo {
    let localOnlySize: Int64
    let cloudKitLocalSize: Int64
    let isUsingCloudKit: Bool
    let backupSize: Int64
    let lastBackupDate: Date?
    
    var currentStorageSize: Int64 {
        isUsingCloudKit ? cloudKitLocalSize : localOnlySize
    }
    
    var formattedCurrentSize: String {
        ByteCountFormatter.string(fromByteCount: currentStorageSize, countStyle: .file)
    }
    
    var formattedBackupSize: String {
        ByteCountFormatter.string(fromByteCount: backupSize, countStyle: .file)
    }
    
    var explanation: String {
        if isUsingCloudKit {
            return "Your data is stored locally and synced with iCloud. The local copy ensures fast access and offline availability."
        } else {
            return "Your data is stored only on this device. Enable iCloud Sync to access it on all your devices."
        }
    }
    
    var backupExplanation: String {
        if let lastBackupDate = lastBackupDate {
            return "Last backup was created on \(lastBackupDate.formatted(date: .abbreviated, time: .shortened)). Backups are stored in your iCloud Drive."
        } else {
            return "No backup has been created yet. Create a backup to safeguard your data."
        }
    }
}


class StorageManager {
    static let shared = StorageManager()
    
    private init() {}
    
    func getStorageInfo(containerManager: ModelContainerManager) async throws -> StorageInfo {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let localOnlyURL = documentsPath.appendingPathComponent("LocalOnly.sqlite")
        let cloudKitURL = documentsPath.appendingPathComponent("CloudKit.sqlite")
        
        let localOnlySize = FileManager.default.fileSize(at: localOnlyURL)
        let cloudKitSize = FileManager.default.fileSize(at: cloudKitURL)
        
        let backupDate = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
        let backupSize = UserDefaults.standard.object(forKey: "lastBackupSize") as? Int64 ?? 0
        
        return await StorageInfo(
            localOnlySize: localOnlySize,
            cloudKitLocalSize: cloudKitSize,
            isUsingCloudKit: containerManager.currentStorageMode == .iCloudSync,
            backupSize: backupSize,
            lastBackupDate: backupDate
        )
    }
    
    func cleaniCloudBackups(olderThan days: Int = 30) async throws {
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
            .appendingPathComponent("SubTrack_Backups") else {
            return
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: iCloudURL,
                includingPropertiesForKeys: [.creationDateKey]
            )
            
            for file in files {
                if file.pathExtension == "json" && file.lastPathComponent != "SubTrack_Backup.json" {
                    let resourceValues = try file.resourceValues(forKeys: [.creationDateKey])
                    if let creationDate = resourceValues.creationDate, creationDate < cutoffDate {
                        try FileManager.default.removeItem(at: file)
                        logInfo("Cleaned up old backup: \(file.lastPathComponent)")
                    }
                }
            }
        } catch {
            logError("Error cleaning up old backups: \(error)")
            throw error
        }
    }
    
    func checkiCloudAvailability() async -> Bool {
        return await withCheckedContinuation { continuation in
            CKContainer.default().accountStatus { status, error in
                continuation.resume(returning: status == .available)
            }
        }
    }
    
    func getiCloudQuotaInfo() async throws -> (used: Int64, available: Int64)? {
        // Note: iOS doesn't provide direct access to iCloud quota information
        // This is a placeholder for future implementation if Apple provides this API
        return nil
    }
}
