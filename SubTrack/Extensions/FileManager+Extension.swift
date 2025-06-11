//
//  FileManager+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/6/10.
//
import Foundation


extension FileManager {
    func fileSize(at url: URL) -> Int64 {
        guard let attributes = try? attributesOfItem(atPath: url.path) else {
            return 0
        }
        return attributes[.size] as? Int64 ?? 0
    }
}
