//
//  CalendarCache.swift
//  SubTrack
//
//  Created by Sam on 2025/4/26.
//
import Foundation

class CalendarCache {
    private init() {}
    static let shared = CalendarCache()
    
    // Cache structure with expiration
    private struct CachedValue<T> {
        let value: T
        let expirationTime: Date
    }
    
    // Cache storage
    private var monthlyTotalCache: [String: CachedValue<Decimal>] = [:]
    
    // Cache key generator
    private func generateMonthKey(month: Date, currency: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return "\(formatter.string(from: month))-\(currency)"
    }
    
    // Get or calculate monthly total
    func monthlyTotal(
        month: Date,
        currency: String,
        subscriptions: [Subscription],
        exchangeRates: ExchangeRateRepository,
        calculation: () -> Decimal
    ) -> Decimal {
        let key = generateMonthKey(month: month, currency: currency)
        
        // Check cache first
        if let cached = monthlyTotalCache[key], cached.expirationTime > Date() {
            return cached.value
        }
        
        // Calculate if not in cache
        let total = calculation()
        
        // Cache the result for 1 hour
        monthlyTotalCache[key] = CachedValue(
            value: total,
            expirationTime: Date().addingTimeInterval(3600)
        )
        
        return total
    }
    
    // Clear cache for specific month
    func invalidateCache(for month: Date, currency: String) {
        let key = generateMonthKey(month: month, currency: currency)
        monthlyTotalCache.removeValue(forKey: key)
//        monthlyTotalCache.removeAll(where: { $0.key == key })
    }
    
    // Clear all caches
    func clearAllCaches() {
        monthlyTotalCache.removeAll()
    }
}
