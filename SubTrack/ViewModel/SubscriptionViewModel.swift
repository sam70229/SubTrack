//
//  SubscriptionViewModel.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI


class SubscriptionViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    
    @Published var name: String = ""
    @Published var price: Decimal = 0
    @Published var billingCycle: BillingCycle = .monthly
    @Published var firstBillingDate: Date = Date()
    @Published var icon: String = "creditcard"
    @Published var colorHex: String = "#3E80F7"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let dataSource: SubscriptionDataSource
    
    init(dataSource: SubscriptionDataSource) {
        self.dataSource = dataSource
    }
    
    func fetchSubscriptions() {
        isLoading = true
        Task { @MainActor in
            subscriptions = try dataSource.fetchSubscriptions()
            isLoading = false
        }
        
    }
    
    func addSubscription(_ subscription: Subscription) {
        Task {
            do {
                try  dataSource.addSubscription(subscription)
            } catch {
                errorMessage = "Failed to add subscription: \(error)"
            }
        }
        
    }
}
