//
//  CurrencyInfo.swift
//  SubTrack
//
//  Created by Sam on 2025/3/27.
//
import SwiftUI


struct CurrencyInfo: Identifiable, Hashable {
    let id: String // Currency code (e.g., "USD")
    let code: String // Same as id, for clarity
    let symbol: String // Currency symbol (e.g., "$")
    let name: String // Full name (e.g., "US Dollar")
    let exampleFormatted: String // Example of formatted value
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func loadAvailableCurrencies() -> [CurrencyInfo] {
        // Start with all locale identifiers
        let allLocales = Locale.availableIdentifiers.map { Locale(identifier: $0) }
        
        // Get unique currency codes with their symbols and names
        var currencySet = Set<String>()
        var currencies: [CurrencyInfo] = []
        
        for locale in allLocales {
            guard let currencyCode = locale.currency?.identifier else { continue }
            
            // Skip if we've already processed this currency
            if currencySet.contains(currencyCode) { continue }
            currencySet.insert(currencyCode)
            
            // Create formatter with the locale to get proper formatting
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = locale
            
            // Get symbol and example formatted value
            let symbol = locale.currencySymbol ?? currencyCode
            let exampleValue = formatter.string(from: 1234.56 as NSNumber) ?? "1234.56"
            
            // Get currency name (preferably in user's language)
            let currencyName = locale.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
            
            currencies.append(CurrencyInfo(
                id: currencyCode,
                code: currencyCode,
                symbol: symbol,
                name: currencyName,
                exampleFormatted: exampleValue
            ))
        }
        
        return currencies
    }

    // Helper method to get a formatter for a specific currency code
    static func formatter(for currencyCode: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        // Find the first locale that uses our selected currency
        if let locale = Locale.availableIdentifiers
            .map({ Locale(identifier: $0) })
            .first(where: { $0.currency?.identifier == currencyCode }) {
            formatter.locale = locale
        }
        
        return formatter
    }

    // Format a value using a specific currency code
    static func format(value: Double, currencyCode: String) -> String {
        return formatter(for: currencyCode).string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    static func hasDecimals(_ currencyCode: String) -> Bool {
        let nonDecimal: Set<String> = ["TWD"]
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return nonDecimal.contains(currencyCode) ? false : formatter.minimumFractionDigits > 0
    }
}
