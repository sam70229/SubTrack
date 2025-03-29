//
//  Subscription.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//
import SwiftData
import SwiftUI


@Model
class Subscription {
    var id: UUID
    var name: String
    var subscriptionDescription: String?
    var price: Decimal
    var billingCycle: BillingCycle
    var firstBillingDate: Date
    var categoryID: UUID?
    var icon: String
    var colorHex: String
    var isActive: Bool
    var creationDate: Date
    
    var nextBillingDate: Date {
        calculateNextBillingDate()
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        subscriptionDescription: String? = nil,
        price: Decimal,
        billingCycle: BillingCycle,
        firstBillingDate: Date,
        categoryID: UUID? = nil,
        icon: String,
        colorHex: String,
        isActive: Bool = true,
        creationDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.subscriptionDescription = subscriptionDescription
        self.price = price
        self.billingCycle = billingCycle
        self.firstBillingDate = firstBillingDate
        self.categoryID = categoryID
        self.icon = icon
        self.colorHex = colorHex
        self.isActive = isActive
        self.creationDate = creationDate
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    private func calculateNextBillingDate() -> Date {
        let today = Date()
        var nextDate = firstBillingDate
        while nextDate < today {
            nextDate = billingCycle.calculateNextDate(from: nextDate)
        }
        return nextDate
    }
}


enum BillingCycle: Int, Codable, CaseIterable, Identifiable {
    case monthly = 0
    case quarterly = 1
    case biannually = 2
    case annually = 3
    case custom = 4
    
    var id: Int { self.rawValue }
    
    var description: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .biannually: return "Biannually"
        case .annually: return "Annually"
        case .custom: return "Custom"
        }
    }
    
    // Add function to calculate next date from current date
    func calculateNextDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)!
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)!
        case .biannually:
            return calendar.date(byAdding: .month, value: 6, to: date)!
        case .annually:
            return calendar.date(byAdding: .year, value: 1, to: date)!
        case .custom:
            // For custom billing cycles, we'd need more UI options
            return date
        }
    }
}
