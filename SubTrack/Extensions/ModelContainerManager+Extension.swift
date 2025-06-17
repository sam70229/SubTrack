//
//  ModelContainerManager+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/6/11.
//
import Foundation
import SwiftData

enum DataMigrationError: Error {
    case migrationFailed(String)
}


extension ModelContainerManager {
    
    /// Creates a backup of the current data before migration
    func createBackup() async throws {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw DataMigrationError.migrationFailed("Cannot access documents directory")
        }
        
        let backupDir = documentsPath.appendingPathComponent("Backups")
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let sourceFileName = currentStorageMode == .localOnly ? "LocalOnly.sqlite" : "CloudKit.sqlite"
        let sourceURL = documentsPath.appendingPathComponent(sourceFileName)
        let backupURL = backupDir.appendingPathComponent("\(sourceFileName).\(timestamp).backup")
        
        // Copy main database file
        if FileManager.default.fileExists(atPath: sourceURL.path) {
            try FileManager.default.copyItem(at: sourceURL, to: backupURL)
            
            // Copy associated files
            let extensions = ["shm", "wal"]
            for ext in extensions {
                let sourceFile = sourceURL.appendingPathExtension(ext)
                let backupFile = backupURL.appendingPathExtension(ext)
                if FileManager.default.fileExists(atPath: sourceFile.path) {
                    try FileManager.default.copyItem(at: sourceFile, to: backupFile)
                }
            }
        }
    }
    
    /// Restores data from a backup
    func restoreFromBackup(backupURL: URL) async throws {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw DataMigrationError.migrationFailed("Cannot access documents directory")
        }
        
        let targetFileName = currentStorageMode == .localOnly ? "LocalOnly.sqlite" : "CloudKit.sqlite"
        let targetURL = documentsPath.appendingPathComponent(targetFileName)
        
        // Remove existing files
//        ModelContainerManager.cleanupOldStorage(for: currentStorageMode)
        
        // Copy backup files
        try FileManager.default.copyItem(at: backupURL, to: targetURL)
        
        // Copy associated files
        let extensions = ["shm", "wal"]
        for ext in extensions {
            let backupFile = backupURL.appendingPathExtension(ext)
            let targetFile = targetURL.appendingPathExtension(ext)
            if FileManager.default.fileExists(atPath: backupFile.path) {
                try FileManager.default.copyItem(at: backupFile, to: targetFile)
            }
        }
        
        // Recreate container
        modelContainer = Self.createContainer(useiCloud: currentStorageMode == .iCloudSync)
    }
    
    /// Lists available backups
    func listBackups() -> [URL] {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        let backupDir = documentsPath.appendingPathComponent("Backups")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            return files.filter { $0.pathExtension == "backup" }
                .sorted { (url1, url2) in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            return []
        }
    }
    
    /// Cleans up old backups, keeping only the most recent ones
    func cleanupOldBackups(keepCount: Int = 5) async throws {
        let backups = listBackups()
        
        if backups.count > keepCount {
            let backupsToDelete = backups.suffix(from: keepCount)
            
            for backupURL in backupsToDelete {
                try FileManager.default.removeItem(at: backupURL)
                
                // Remove associated files
                let extensions = ["shm", "wal"]
                for ext in extensions {
                    let file = backupURL.appendingPathExtension(ext)
                    if FileManager.default.fileExists(atPath: file.path) {
                        try FileManager.default.removeItem(at: file)
                    }
                }
            }
        }
    }
}
