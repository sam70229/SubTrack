//
//  SubscriptionListView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI


struct SubscriptionListView: View {
    @StateObject private var subscriptionViewModel: SubscriptionViewModel = .init(dataSource: .shared)
    @State private var showAddSubscription: Bool = false

    var body: some View {
        List {
            ForEach(subscriptionViewModel.subscriptions) { subscription in
                SubscriptionListItemView(subscription: subscription)
                    .listRowSeparator(.hidden)
            }
        }
        .listRowSpacing(8)
        .navigationTitle("Subscriptions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSubscription = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if subscriptionViewModel.isLoading {
                ProgressView()
            } else if subscriptionViewModel.subscriptions.isEmpty {
                ContentUnavailableView("No Subscriptions", systemImage: "creditcard", description: Text("Add subscriptions to start tracking."))
            }
        }
        .sheet(isPresented: $showAddSubscription) {
            AddSubscriptionView()
                .presentationDetents([.medium, .large])
        }
        .refreshable {
            subscriptionViewModel.fetchSubscriptions()
        }
        .onAppear {
            subscriptionViewModel.fetchSubscriptions()
        }
    }
}
