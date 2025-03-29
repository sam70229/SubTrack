//
//  CalendarDate.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//
import Foundation
import SwiftUI


struct CalendarDate: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    var subscriptions: [Subscription] = []
    var isCurrentMonth: Bool = true
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CalendarDate, rhs: CalendarDate) -> Bool {
        lhs.id == rhs.id
    }
}
