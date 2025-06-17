//
//  DateFormatter+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/6/11.
//
import Foundation


extension DateFormatter {
    static let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
