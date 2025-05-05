//
//  Calendar+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/5/2.
//
import Foundation

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        return self.date(from: self.dateComponents([.year, .month], from: date)) ?? date
    }
}
