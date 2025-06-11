//
//  StorageManage.swift
//  SubTrack
//
//  Created by Sam on 2025/6/10.
//
import Foundation


struct StorageInfo {
    let localOnlySize: Int64
        let cloudKitLocalSize: Int64
        let isUsingCloudKit: Bool
        
        var currentStorageSize: Int64 {
            isUsingCloudKit ? cloudKitLocalSize : localOnlySize
        }
        
        var formattedCurrentSize: String {
            ByteCountFormatter.string(fromByteCount: currentStorageSize, countStyle: .file)
        }
        
        var explanation: String {
            if isUsingCloudKit {
                return "Your data is stored locally and synced with iCloud. The local copy ensures fast access and offline availability."
            } else {
                return "Your data is stored only on this device. Enable iCloud Sync to access it on all your devices."
            }
        }
}
