//
//  BillingCycle.swift
//  SubTrack
//
//  Created by Sam on 2025/5/6.
//
import SwiftUI


enum BillingCycle: Int, Codable, CaseIterable, Identifiable {
    case monthly = 0       // Every 1 month
    case semimonthly = 1   // Twice a month (e.g., 1st and 15th)
    case bimonthly = 2     // Every 2 months
    case quarterly = 3     // Every 3 months
    case semiannually = 4  // Every 6 months
    case annually = 5      // Every 12 months
    case biennially = 6    // Every 2 years
    case custom = 7
    
    var id: Int { self.rawValue }
    
    var description: String {
        switch self {
        case .monthly: return String(localized: "Monthly")
        case .semimonthly: return String(localized: "Semimonthly")
        case .quarterly: return String(localized: "Quarterly")
        case .bimonthly: return String(localized: "Bimonthly")
        case .semiannually: return String(localized: "Semiannually")
        case .annually: return String(localized: "Annually")
        case .biennially: return String(localized: "Biennially")
        case .custom: return String(localized: "Custom")
        }
    }
    
    // Add function to calculate next date from current date
    func calculateNextDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .semimonthly:
            return calendar.date(byAdding: .day, value: 15, to: date)!
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)!
        case .bimonthly:
            return calendar.date(byAdding: .month, value: 2, to: date)!
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)!
        case .semiannually:
            return calendar.date(byAdding: .month, value: 6, to: date)!
        case .annually:
            return calendar.date(byAdding: .year, value: 1, to: date)!
        case .biennially:
            return calendar.date(byAdding: .year, value: 2, to: date)!
        case .custom:
            // For custom billing cycles, we'd need more UI options
            return date
        }
    }
}
