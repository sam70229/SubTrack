//
//  CurrencyViewModel.swift
//  SubTrack
//
//  Created by Sam on 2025/3/27.
//
import SwiftUI


class CurrencyViewModel: ObservableObject {
    @Published var selectedCurrencyCode: String = ""
    @Published var currencies: [CurrencyInfo] = []
    
    init() {
        self.loadAvailableCurrencies()
    }
    
    private func loadAvailableCurrencies() {
        // Start with all locale identifiers
        let allLocales = Locale.availableIdentifiers.map { Locale(identifier: $0) }
        
        // Get unique currency codes with their symbols and names
        var currencySet = Set<String>()
        
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
            
            self.currencies.append(CurrencyInfo(
                id: currencyCode,
                code: currencyCode,
                symbol: symbol,
                name: currencyName,
                exampleFormatted: exampleValue
            ))
        }
    }
    
    func loadSelectedCurrencyCode(_ code: String) {
        self.selectedCurrencyCode = code
    }
    
    // Get the current NumberFormatter for the selected currency
    func currencyFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        // Find the first locale that uses our selected currency
        if let locale = Locale.availableIdentifiers
            .map({ Locale(identifier: $0) })
            .first(where: { $0.currency?.identifier == selectedCurrencyCode }) {
            formatter.locale = locale
        }
        
        return formatter
    }
    
    // Format a value using the selected currency
    func format(value: Double) -> String {
        return currencyFormatter().string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
