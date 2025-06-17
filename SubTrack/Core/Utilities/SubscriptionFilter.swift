//
//  SubscriptionFilter.swift
//  SubTrack
//
//  Created by Sam on 2025/4/26.
//
import Foundation


class SubscriptionFilter {
    // Cache for subscription dates to avoid recalculating
    private static var subscriptionDateCache: [UUID: Set<DateComponents>] = [:]
    
    // Clear cache - call when subscriptions change
    static func clearCache() {
        subscriptionDateCache.removeAll()
    }
    
    // Main filter method with caching
    static func filterSubscriptions(_ subscriptions: [Subscription], for date: Date) -> [Subscription] {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.day, .month, .year], from: date)
        
        return subscriptions.filter { subscription in
            // Check cache first
            if let cachedDates = subscriptionDateCache[subscription.id] {
                // Compare just the day and month components for efficiency
                let dayMonth = DateComponents(month: dateComponents.month, day: dateComponents.day)
                return cachedDates.contains(where: { $0.day == dayMonth.day && $0.month == dayMonth.month })
            }
            
            // If not in cache, calculate and store
            let matches = subscriptionOccursOnDate(subscription, date: date)
            
            // If it's the first calculation, populate the cache
            if subscriptionDateCache[subscription.id] == nil {
                updateCacheForSubscription(subscription)
            }
            
            return matches
        }
    }
    
    // Pre-calculate all dates for a subscription and store in cache
    private static func updateCacheForSubscription(_ subscription: Subscription) {
        var dates = Set<DateComponents>()
        let calendar = Calendar.current
        
        // Get the base billing date components
        let firstBillingDate = subscription.firstBillingDate
        let day = calendar.component(.day, from: firstBillingDate)
        let month = calendar.component(.month, from: firstBillingDate)
        
        // Calculate based on period
        switch subscription.period {
        case .monthly:
            // All months have the same day
            for m in 1...12 {
                dates.insert(DateComponents(month: m, day: day))
            }
            
        case .quarterly:
            // Every 3 months
            let startMonth = month
            for offset in stride(from: 0, to: 9, by: 3) {
                let m = ((startMonth - 1 + offset) % 12) + 1
                dates.insert(DateComponents(month: m, day: day))
            }
            
        case .annually:
            // Just one date per year
            dates.insert(DateComponents(month: month, day: day))
            
        case .semiannually:
            // Twice a year, 6 months apart
            let startMonth = month
            let secondMonth = ((startMonth - 1 + 6) % 12) + 1
            dates.insert(DateComponents(month: startMonth, day: day))
            dates.insert(DateComponents(month: secondMonth, day: day))
            
        case .semimonthly:
            // Twice a month (billing day and billing day + 15, wrapped to month length)
            for m in 1...12 {
                dates.insert(DateComponents(month: m, day: day))
                
                // Get the correct second day of the month (handle month length)
                let components = DateComponents(year: 2000, month: m, day: 1) // Use a non-leap year for consistency
                if let monthDate = calendar.date(from: components),
                   let monthLength = calendar.range(of: .day, in: .month, for: monthDate)?.count {
                    let secondDay = min(day + 15, monthLength)
                    dates.insert(DateComponents(month: m, day: secondDay))
                }
            }
            
        case .bimonthly:
            // Every 2 months
            let startMonth = month
            for offset in stride(from: 0, to: 10, by: 2) {
                let m = ((startMonth - 1 + offset) % 12) + 1
                dates.insert(DateComponents(month: m, day: day))
            }
            
        case .biennially:
            // Just one month every two years (we'll just track the month/day)
            dates.insert(DateComponents(month: month, day: day))
            
        case .custom:
            // For custom, we'd need more specific handling
            // For now, just add the original date
            dates.insert(DateComponents(month: month, day: day))
        }
        
        subscriptionDateCache[subscription.id] = dates
    }
    
    // Direct calculation method for a single check
    private static func subscriptionOccursOnDate(_ subscription: Subscription, date: Date) -> Bool {
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: date)
        let currentMonth = calendar.component(.month, from: date)
        
        let subscriptionDay = calendar.component(.day, from: subscription.firstBillingDate)
        
        switch subscription.period {
        case .semimonthly:
            return currentDay == subscriptionDay || currentDay == min(subscriptionDay + 15, calendar.range(of: .day, in: .month, for: date)?.count ?? 31)
            
        case .monthly:
            return currentDay == subscriptionDay
            
        case .bimonthly:
            let subscriptionMonth = calendar.component(.month, from: subscription.firstBillingDate)
            let monthDifference = (currentMonth - subscriptionMonth + 12) % 12
            return currentDay == subscriptionDay && monthDifference % 2 == 0
            
        case .quarterly:
            let subscriptionMonth = calendar.component(.month, from: subscription.firstBillingDate)
            let monthDifference = (currentMonth - subscriptionMonth + 12) % 12
            return currentDay == subscriptionDay && monthDifference % 3 == 0
            
        case .semiannually:
            let subscriptionMonth = calendar.component(.month, from: subscription.firstBillingDate)
            let monthDifference = (currentMonth - subscriptionMonth + 12) % 12
            return currentDay == subscriptionDay && monthDifference % 6 == 0
            
        case .annually:
            let subscriptionMonth = calendar.component(.month, from: subscription.firstBillingDate)
            return currentDay == subscriptionDay && currentMonth == subscriptionMonth
            
        case .biennially:
            let subscriptionMonth = calendar.component(.month, from: subscription.firstBillingDate)
            let subscriptionYear = calendar.component(.year, from: subscription.firstBillingDate)
            let currentYear = calendar.component(.year, from: date)
            let yearDifference = currentYear - subscriptionYear
            
            return currentDay == subscriptionDay &&
                   currentMonth == subscriptionMonth &&
                   yearDifference % 2 == 0
            
        case .custom:
            // For custom, we'd need more specific handling
            return false
        }
    }
}
