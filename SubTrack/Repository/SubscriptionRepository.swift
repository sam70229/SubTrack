//
//  SubscriptionRepository.swift
//  SubTrack
//
//  Created by Sam on 2025/3/31.
//
import SwiftUI
import SwiftData


// A repository class that handles business logic
class SubscriptionRepository: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchSubscriptions() -> [Subscription] {
        do {
            let descriptor = FetchDescriptor<Subscription>()
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    func addSubscription(_ subscription: Subscription) throws {
        modelContext.insert(subscription)
    }
    
    func updateSubscription(_ subscription: Subscription) throws {
        // SwiftData automatically tracks changes to existing objects
        // No need to call save()
    }
    
    func deleteSubscription(_ subscription: Subscription) throws {
        modelContext.delete(subscription)
    }
    
    func fetchSubscriptionsForDate(_ date: Date) -> [Subscription] {
        // Get the day component of the current date
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: date)
        let currentMonth = calendar.component(.month, from: date)
        //        let currentYear = calendar.component(.year, from: date)
        let subscriptions = self.fetchSubscriptions()
        
        if subscriptions.isEmpty {
            return []
        }
        // Filter subscriptions based on billing cycle and billing day
        return subscriptions.filter { subscription in
            let subscriptionDay = calendar.component(.day, from: subscription.firstBillingDate)
            
            switch subscription.billingCycle {
                
            case .semimonthly:
                // For monthly subscriptions, only check if the day matches 15 days after
                return currentDay == subscriptionDay && (currentDay - subscriptionDay) == 15
                
            case .monthly:
                // For monthly subscriptions, only check if the day matches
                return currentDay == subscriptionDay
                
            case .bimonthly:
                return currentDay == subscriptionDay && currentDay.isMultiple(of: 2)
                
            case .quarterly:
                // For quarterly, check if day matches and if month is on the quarterly schedule
                let subscriptionMonth = calendar.component(.month, from: subscription.firstBillingDate)
                let monthDifference = (currentMonth - subscriptionMonth + 12) % 12
                return currentDay == subscriptionDay && monthDifference % 3 == 0
                
            case .semiannually:
                // For semiannually, check day and if month is on the 6-month schedule
                let subscriptionMonth = calendar.component(.month, from: subscription.firstBillingDate)
                let monthDifference = (currentMonth - subscriptionMonth + 12) % 12
                return currentDay == subscriptionDay && monthDifference % 6 == 0
                
            case .annually:
                // For annual, check day and month match the original date
                let subscriptionMonth = calendar.component(.month, from: subscription.firstBillingDate)
                return currentDay == subscriptionDay && currentMonth == subscriptionMonth
                
            case .biennially:
                // For annual, check day and month match the original date
                let subscriptionMonth = calendar.component(.month, from: subscription.firstBillingDate)
                let monthDifference = (currentMonth - subscriptionMonth + 12) % 12
                return currentDay == subscriptionDay && monthDifference % 24 == 0
                
            case .custom:
                // For custom, you'd need more specific handling
                return false
            }
        }
    }
} 
