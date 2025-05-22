//
//  Date+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/5/15.
//
import SwiftUI

extension Date {
   static func getDaysBetween(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        return abs(calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0)
    }
}
