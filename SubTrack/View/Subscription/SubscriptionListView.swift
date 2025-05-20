//
//  SubscriptionListView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI
import SwiftData

enum SortedMethod: String, CaseIterable {
    case Price = "Price"
    case Period = "Period"
    case Name = "Name"
    
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
    @State private var showSortPicker: Bool = false
    @State private var sortedMethod: SortedMethod = .Price
    
    var body: some View {
        VStack {
            if sorted {
                sortHeader
            }

            List(sortedSubscriptions()) { subscription in
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
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
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
            }
        }
        .sheet(isPresented: $showAddSubscription) {
            NavigationStack {
                AddSubscriptionView()
            }
        }
        .sheet(isPresented: $showSortPicker) {
            VStack {
                ForEach(SortedMethod.allCases, id: \.self) { option in
                    Text(LocalizedStringKey(option.rawValue))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.secondary)
                        )
                        .padding(.horizontal)
                        .onTapGesture {
                            sortedMethod = option
                            showSortPicker = false
                        }
                }
            }
            .presentationDetents([.height(200)])
        }
        .navigationDestination(item: $selectedSubscription) { subscription in
            SubscriptionDetailView(subscription: subscription)
        }
    }
    
    func swipeToDelete(_ subscription: Subscription) {
        modelContext.delete(subscription)
    }
    
    private var sortHeader: some View {
        HStack {
            Text("sorted by")

            Button {
                showSortPicker = true
            } label: {
                Text(sortedMethod.rawValue)
            }
            .font(.body)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
    
    private func sortedSubscriptions() -> [Subscription] {
        if !sorted {
            return subscriptions
        }
        switch sortedMethod {
        case .Price:
            return subscriptions.sorted { exchangeRates.convert(
                $0.price,
                from: $0.currencyCode,
                to: appSettings.currencyCode) ?? $0.price > exchangeRates.convert(
                    $1.price,
                    from: $1.currencyCode,
                    to: appSettings.currencyCode) ?? $1.price }
        case .Name:
            return subscriptions.sorted { $0.name < $1.name }
        case .Period:
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
