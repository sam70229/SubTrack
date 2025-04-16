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
    var category: [Category]?
    var icon: String
    var colorHex: String
    var isActive: Bool
    var createdAt: Date
    var creditCard: CreditCard?
    
    var nextBillingDate: Date {
        calculateNextBillingDate()
    }
    
    @Relationship(deleteRule: .cascade, inverse: \BillingRecord.subscription)
    var billingRecords: [BillingRecord] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        subscriptionDescription: String? = nil,
        price: Decimal,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        billingCycle: BillingCycle,
        firstBillingDate: Date,
        category: [Category]? = nil,
        creditCard: CreditCard? = nil,
        icon: String,
        colorHex: String,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.subscriptionDescription = subscriptionDescription
        self.price = price
        self.currencyCode = currencyCode
        self.billingCycle = billingCycle
        self.firstBillingDate = firstBillingDate
        self.category = category
        self.creditCard = creditCard
        self.icon = icon
        self.colorHex = colorHex
        self.isActive = isActive
        self.createdAt = createdAt
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
    
    func totalAmountTillToday() -> Decimal {
        return billingRecords.filter { $0.isPaid && $0.billingDate <= Date() }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Format the total amount with the subscription's currency
    func formattedTotalAmount() -> String {
        let total = totalAmountTillToday()
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        // Find a locale that uses this currency
        if let locale = Locale.availableIdentifiers
            .map({ Locale(identifier: $0) })
            .first(where: { $0.currency?.identifier == currencyCode }) {
            formatter.locale = locale
        }
        
        return formatter.string(from: NSDecimalNumber(decimal: total)) ?? "\(total)"
    }
    
    func generateBillingHistory() {
        let today = Date()
        var currentDate = firstBillingDate

        if currentDate > today || !isActive {
            return
        }

        while currentDate <= today {
            let existingRecord = billingRecords.first {
                Calendar.current.isDate($0.billingDate, inSameDayAs: currentDate)
            }
            
            if existingRecord == nil {
                let record = BillingRecord(
                    subscriptionId: id,
                    billingDate: currentDate,
                    amount: price,
                    currencyCode: currencyCode
                )
                billingRecords.append(record)
            }
            
            currentDate = billingCycle.calculateNextDate(from: currentDate)
        }
    }
    
    // Update future billing records if price changes
    func updateFutureBillingRecords() {
        let today = Date()
        
        // Update all future billing records with the new price
        for record in billingRecords {
            if record.billingDate > today {
                record.amount = price
                record.currencyCode = currencyCode
            }
        }
        
        // Generate any new billing records with the updated price
        generateBillingHistory()
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
