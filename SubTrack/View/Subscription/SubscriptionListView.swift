//
//  SubscriptionListView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI
import SwiftData

struct SubscriptionListView: View {
    // Access the model context directly from the environment
    @Environment(\.modelContext) private var modelContext
    
    // Use SwiftUI's query capabilities
    @Query private var subscriptions: [Subscription]
    
    @State private var showAddSubscription: Bool = false
    @State private var selectedSubscription: Subscription?
    @State private var isLoading = false

    var body: some View {
        List(subscriptions) { subscription in
            Button {
                selectedSubscription = subscription
            } label: {
                SubscriptionListItemView(subscription: subscription)
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
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
            if isLoading {
                ProgressView()
            } else if subscriptions.isEmpty {
                ContentUnavailableView("No Subscriptions", systemImage: "creditcard", description: Text("Add subscriptions to start tracking."))
            }
        }
        .sheet(isPresented: $showAddSubscription) {
            NavigationStack {
                AddSubscriptionView()
            }
        }
        .navigationDestination(item: $selectedSubscription) { subscription in
            SubscriptionDetailView(subscription: subscription)
        }
    }
}

#Preview {
    SubscriptionListView()
}
