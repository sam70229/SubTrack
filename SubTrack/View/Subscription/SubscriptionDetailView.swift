//
//  SubscriptionDetailView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/31.
//
import SwiftUI


struct SubscriptionDetailView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    var subscription: Subscription
    @State private var subscriptionRepository: SubscriptionRepository?
    @State private var categoryRepository: CategoryRepository?
    
    @State private var isEnabledNotification: Bool = false
    @State private var selectedReminder: NotificationDate = .one_day_before
    @State private var categoryName: String = "None"
    @State private var showDeleteConfirmation: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        List {

            subscriptionBasicInfoSection

            subscriptionDetailsInfoSection

            // TODO: - Support notifications before payment day
//            notificationSettingsSection
            
            priceInfoSection
            
            // Delete Subscription
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Text("Delete")
            }
        }
        .alert(item: $errorMessage) { msg in
                .init(title: Text("Error"))
            
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(title: Text("Delete Subscription"), primaryButton: .destructive(Text("Confirm"), action: {
                do {
                    try subscriptionRepository?.deleteSubscription(subscription)
                    // Then when you want to pop:
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    errorMessage = "Delete failed: \(error.localizedDescription)"
                }
            }), secondaryButton: .cancel())
        }
        .onAppear {
            subscriptionRepository = SubscriptionRepository(modelContext: modelContext)
            categoryRepository = CategoryRepository(modelContext: modelContext)
            
            loadCategoryName()
        }
    }
    
    private func loadCategoryName() {
        if let categoryID = subscription.category?.first?.id,
           let category = categoryRepository?.fetchCategory(withId: categoryID) {
            self.categoryName = category.name
        } else {
            self.categoryName = "None"
        }
    }

    // MARK: - Subscription info

    private var subscriptionBasicInfoSection: some View {
        Section {
            HStack {
                Text("Name")
                Spacer()
                Text("\(subscription.name)")
            }
            
            HStack {
                Text("Price")
                Spacer()
                Text(subscription.price, format: .currency(code: appSettings.currencyCode))
            }
            
        } header: {
            Text("Subscription")
        }
    }
    
    private var subscriptionDetailsInfoSection: some View {
        Section {
            if subscription.category?.first?.id != nil {
                HStack {
                    Text("Category")
                    Spacer()
                    Text(categoryName)
                }
            }

            HStack {
                Text("Billing Cycle")
                Spacer()
                Text(subscription.billingCycle.description)
            }

            HStack {
                Text("Starting Date")
                Spacer()
                Text(subscription.firstBillingDate, style: .date)
            }
            
            HStack {
                Text("Days to Billing")
                Spacer()
                Text("\(Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextBillingDate).day!) days")
            }
            
            if subscription.creditCard != nil {
                VStack(alignment: .leading) {
                    Text("Paying Card")
                    CreditCardView(card: subscription.creditCard!)
                        .frame(height: 200)
                }
            }

        } header: {
            Text("Subscription Details")
        }
    }

    // MARK: - Price info

    private var priceInfoSection: some View {
        Section {
            HStack {
                Text("Price a Month")
                Spacer()
                Text(monthlyPrice, format: .currency(code: appSettings.currencyCode))
            }
            HStack {
                Text("Price a Year")
                Spacer()
                Text(yearlyPrice, format: .currency(code: appSettings.currencyCode))
            }
            HStack {
                Text("Since First Payment")
                Spacer()
                Text(subscription.totalAmountTillToday(), format: .currency(code: appSettings.currencyCode))
            }
        } header: {
            Text("Price Details")
        }
    }

    // MARK: - Notification Settings

    private var notificationSettingsSection: some View {
        Section {
            Toggle(isOn: $isEnabledNotification) {
                Text("Reminder Notifications")
            }
            if isEnabledNotification {
                HStack {
                    Text("Next Payment")
                    Spacer()
                    Text("3 days")
                }
                HStack {
                    Picker(selection: $selectedReminder) {
                        ForEach(NotificationDate.allCases) { option in
                            Text(option.description).tag(option)
                        }
                    } label: {
                        Text("Reminds me")
                    } currentValueLabel: {
                        Text("\(selectedReminder.description)")
                    }
                    .onChange(of: selectedReminder) { oldValue, newValue in
                        // TODO: IMPLEMENT NOTIFICATION
                        print(oldValue, newValue)
                    }
                }
                
            }
        } header: {
            Text("Notification Settings")
        }
    }

    // MARK: - calculations
    
    private var monthlyPrice: Decimal {
        switch subscription.billingCycle {
        case .semimonthly:
            return subscription.price * 2
        case .monthly:
            return subscription.price
        case .bimonthly:
            return subscription.price / 2
        case .quarterly:
            return subscription.price / 3
        case .semiannually:
            return subscription.price / 6
        case .annually:
            return subscription.price / 12
        case .biennially:
            return subscription.price / 24
        case .custom:
            // For custom billing cycles, we need a more complex approach
            return subscription.price // Default assumption
        }
    }
    
    private var yearlyPrice: Decimal {
        switch subscription.billingCycle {
        case .semimonthly:
            return subscription.price * 24
        case .monthly:
            return subscription.price * 12
        case .bimonthly:
            return subscription.price * 6
        case .quarterly:
            return subscription.price * 4
        case .semiannually:
            return subscription.price * 2
        case .annually:
            return subscription.price
        case .biennially:
            return subscription.price * 0.5
        case .custom:
            // For custom billing cycles, we need a more complex approach
            return subscription.price // Default assumption
        }
    }
    
    private var totalPaidSinceStart: Decimal {
        // Calculate number of billing cycles since first billing date
        let calendar = Calendar.current
        let today = Date()
        
        // If first billing date is in the future, no payments yet
        if subscription.firstBillingDate > today {
            return 0
        }
        
        // Calculate the number of complete billing cycles
        var cycles = 1
        var currentDate = subscription.firstBillingDate
        
        while currentDate <= today {
            cycles += 1
            
            // Get next billing date
            guard let nextDate = calendar.date(byAdding: billingCycleComponent, value: billingCycleValue, to: currentDate) else {
                break
            }
            
            currentDate = nextDate
        }
        
        // If we're calculating from the start date and it's not
        // exactly aligned with billing cycles, subtract 1
        if cycles > 0 && currentDate > today {
            cycles -= 1
        }
        
        return subscription.price * Decimal(cycles)
    }
    
    // Helper properties for calculating billing cycles
    private var billingCycleComponent: Calendar.Component {
        switch subscription.billingCycle {
        case .semimonthly:
            return .day
        case .monthly, .bimonthly, .quarterly, .semiannually:
            return .month
        case .annually, .biennially:
            return .year
        case .custom:
            return .month // Default
        }
    }

    private var billingCycleValue: Int {
        switch subscription.billingCycle {
        case .semimonthly:
            return 15
        case .monthly:
            return 1
        case .bimonthly:
            return 2
        case .quarterly:
            return 3
        case .semiannually:
            return 6
        case .annually:
            return 1
        case .biennially:
            return 2
        case .custom:
            return 1 // Default
        }
    }
}

enum NotificationDate: Int, CaseIterable, Identifiable {
    case one_day_before = 0
    case three_day_before = 1
    case one_week_before = 2
    
    var id: Int { self.rawValue }
    
    var description: String {
        switch self {
        case .one_day_before:
            return "1 day before"
        case .three_day_before:
            return "3 days before"
        case .one_week_before:
            return "1 week before"
        }
    }
}


#Preview {
    @Previewable @State var subscription = Subscription(
        id: UUID(),
        name: "Test Subscription",
        price: 10.0,
        billingCycle: .monthly,
        firstBillingDate: Date(),
        icon: "",
        colorHex: "#000000"
    )
    SubscriptionDetailView(subscription: subscription)
        .environmentObject(AppSettings())
}
