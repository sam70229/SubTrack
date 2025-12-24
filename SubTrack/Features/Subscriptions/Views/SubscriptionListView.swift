//
//  SubscriptionListView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI
import SwiftData

enum SortedMethod: String, CaseIterable {
    case price = "Price"
    case period = "Period"
    case name = "Name"

    var id: String { self.rawValue }
}


struct SubscriptionListView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var exchangeRates: ExchangeRateRepository
    // Access the model context directly from the environment
    @Environment(\.modelContext) private var modelContext
    
    // Use SwiftUI's query capabilities
    @Query private var subscriptions: [Subscription]
    
    @State private var showAddSubscription: Bool = false
    @State private var selectedSubscription: Subscription?
    @State private var isLoading = false
    
    // Sorted
    @State private var sorted: Bool = false
    @State private var sortedMethod: SortedMethod = .price
    
    // Search
    @State private var searchText: String = ""

    // Filter
    @State private var showFreeTrialsOnly: Bool = false
    @State private var filteredSubscriptions: [Subscription] = []
    
    var body: some View {
        VStack {
            if sorted {
                sortHeader
            }

            List(filteredSubscriptions) { subscription in
                Button {
                    selectedSubscription = subscription
                } label: {
                    SubscriptionListItemView(
                        subscription: subscription,
                        onSwipeToDelete: { subscription in
                            swipeToDelete(subscription)
                        }
                    )
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
            }
            .listRowSpacing(8)
        }
        .navigationTitle("Subscriptions")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showFreeTrialsOnly.toggle()
                } label: {
                    Image(systemName: showFreeTrialsOnly ? "hourglass.circle.fill" : "hourglass.circle")
                }
                .foregroundStyle(showFreeTrialsOnly ? .blue : .primary)
                .badge(showFreeTrialsOnly ? filteredSubscriptions.count : 0)

                Button {
                    sorted.toggle()
                } label :{
                    Image(systemName: sorted ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }

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
            } else if filteredSubscriptions.isEmpty {
                ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("No subscriptions match your current filters or search."))
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
        .searchable(text: $searchText, placement: .toolbar)
        .onAppear {
            updateFilteredSubscriptions()
        }
        .onChange(of: subscriptions) {
            updateFilteredSubscriptions()
        }
        .onChange(of: searchText) {
            updateFilteredSubscriptions()
        }
        .onChange(of: showFreeTrialsOnly) {
            updateFilteredSubscriptions()
        }
        .onChange(of: sorted) {
            updateFilteredSubscriptions()
        }
        .onChange(of: sortedMethod) {
            updateFilteredSubscriptions()
        }
    }
    
    func swipeToDelete(_ subscription: Subscription) {
        modelContext.delete(subscription)
    }

    private func comparePrice(_ lhs: Subscription, _ rhs: Subscription) -> Bool {
        let lhsConverted = exchangeRates.convert(
            lhs.price,
            from: lhs.currencyCode,
            to: appSettings.currencyCode
        ) ?? lhs.price

        let rhsConverted = exchangeRates.convert(
            rhs.price,
            from: rhs.currencyCode,
            to: appSettings.currencyCode
        ) ?? rhs.price

        return lhsConverted > rhsConverted
    }

    private func updateFilteredSubscriptions() {
        var result = sortedSubscriptions()

        // Filter by free trials
        if showFreeTrialsOnly {
            result = result.filter { $0.isFreeTrial }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) || (($0.tags?.contains { $0.name.localizedCaseInsensitiveContains(searchText) }) != nil)
            }
        }

        filteredSubscriptions = result
    }

    private var sortHeader: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: sortMethodIcon(sortedMethod))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("sorted by")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Menu {
                    ForEach(SortedMethod.allCases, id: \.self) { option in
                        Button {
                            sortedMethod = option
                        } label: {
                            Label(option.rawValue, systemImage: sortMethodIcon(option))
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(LocalizedStringKey(sortedMethod.rawValue))
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.thickMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func sortMethodIcon(_ method: SortedMethod) -> String {
        switch method {
        case .price:
            return "dollarsign.circle"
        case .name:
            return "textformat.abc"
        case .period:
            return "calendar"
        }
    }
    
    private func sortedSubscriptions() -> [Subscription] {
        if !sorted {
            return subscriptions
        }

        switch sortedMethod {
        case .price:
            return subscriptions.sorted { comparePrice($0, $1) }
        case .name:
            return subscriptions.sorted { $0.name < $1.name }
        case .period:
            return subscriptions.sorted { $0.period.rawValue < $1.period.rawValue }
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionListView()
            .environmentObject(AppSettings())
            .environmentObject(ExchangeRateRepository())
    }
}
