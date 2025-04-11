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
    var currencyCode: String // For supporting diff country
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
        currencyCode: String = "USD",
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
        self.currencyCode = currencyCode
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
    
    // Format price with the subscription's own currency
    func formattedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        // Find a locale that uses this currency
        if let locale = Locale.availableIdentifiers
            .map({ Locale(identifier: $0) })
            .first(where: { $0.currency?.identifier == currencyCode }) {
            formatter.locale = locale
        }
        
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
    }
    
    // Get the price converted to the app's display currency
    func convertedPrice(to targetCurrencyCode: String, using exchangeRates: [String: Decimal]) -> Decimal? {
        // If already in target currency, return the price
        if currencyCode == targetCurrencyCode {
            return price
        }
        
        // Check if we have exchange rates for both currencies
        guard let sourceRate = exchangeRates[currencyCode],
              let targetRate = exchangeRates[targetCurrencyCode],
              sourceRate > 0 else {
            return nil
        }
        
        // Convert through base currency (usually USD)
        let valueInBaseCurrency = price / sourceRate
        return valueInBaseCurrency * targetRate
    }
    
    private func calculateNextBillingDate() -> Date {
        let today = Date()
        var nextDate = firstBillingDate
        while nextDate < today {
            nextDate = billingCycle.calculateNextDate(from: nextDate)
        }
        return nextDate
    }
    
    private func calculateTotalPrice(for billingDate: Date) -> Decimal {
        let today = Date()
        
        if firstBillingDate > today || !isActive {
            return 0
        }
        
        var currentDate = firstBillingDate
        var numberOfCycles: Int = 0
        
        while currentDate <= today {
            numberOfCycles += 1
            currentDate = billingCycle.calculateNextDate(from: currentDate)
        }
        
        if currentDate.timeIntervalSince(today) < 86400 && numberOfCycles > 0 {
            numberOfCycles -= 1
        }
        
        return price * Decimal(numberOfCycles)
    }
}


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
