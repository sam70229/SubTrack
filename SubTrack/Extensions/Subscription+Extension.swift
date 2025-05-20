//
//  Subscription+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/5/9.
//
import Foundation

extension SchemaV1.Subscription {
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
    
    func calculateNextBillingDate() -> Date {
        let today = Date()
        var nextDate = firstBillingDate
        while nextDate < today {
            nextDate = period.calculateNextDate(from: nextDate)
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
            
            currentDate = period.calculateNextDate(from: currentDate)
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
