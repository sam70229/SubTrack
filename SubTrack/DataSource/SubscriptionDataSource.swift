//
//  SubscriptionDataSource.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//
import SwiftUI
import SwiftData

protocol SubscriptionDataSourceProtocol {
    func fetchSubscriptions() -> [Subscription]
    func fetchSubscriptionsForDate(_ date: Date) -> [Subscription]
    func addSubscription(_ subscription: Subscription) throws
    func updateSubscription(_ subscription: Subscription) throws
    func deleteSubscription(_ subscription: Subscription) throws
}


class SubscriptionDataSource: SubscriptionDataSourceProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    @MainActor
    static let shared = SubscriptionDataSource()
    
    @MainActor
    private init() {
        self.modelContainer = try! ModelContainer(for: Subscription.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false))
        self.modelContext = modelContainer.mainContext
    }
    
    func addSubscription(_ subscription: Subscription) throws {
        modelContext.insert(subscription)
    }
    
    func updateSubscription(_ subscription: Subscription) throws {
        // Implement the update logic
        // Since SwiftData automatically tracks changes to managed objects
    }
    
    func deleteSubscription(_ subscription: Subscription) throws {
        // Implement the delete logic
        modelContext.delete(subscription)
    }
    
    func refreshContext() {
        // This method forces the context to refresh its state
        // Call this when returning to a view that displays data
        modelContext.processPendingChanges()
    }
    
    func fetchSubscriptions() -> [Subscription] {
        do {
            let descriptor = FetchDescriptor<Subscription>()
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
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
