//
//  SubscriptionDetailView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/31.
//
import SwiftUI


struct SubscriptionDetailView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var exchangeRates: ExchangeRateRepository
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    var subscription: Subscription
    
    // Add these computed properties to SubscriptionDetailView:
    private var daysUntilNextPayment: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextBillingDate).day ?? 0
    }
    
    // Add this @State property at the top of SubscriptionDetailView:
    @State private var scheduledNotificationsCount: Int?
    
    @State private var subscriptionRepository: SubscriptionRepository?
    
    @State private var isNotificationEnabled: Bool = false
    @State private var selectedReminder: NotificationDate = .one_day_before
    @State private var categoryName: String = "None"
    @State private var showDeleteConfirmation: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showTagsSheet: Bool = false
    
    var body: some View {
        List {
            
            subscriptionBasicInfoSection
            
            subscriptionDetailsInfoSection
            
            notificationSettingsSection
            
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
        .sheet(isPresented: $showTagsSheet) {
            NavigationStack {
                TagsView(selectedTags: Binding(
                    get: {subscription.tags},
                    set: {newValue in
                        subscription.tags = newValue
                    }
                ))
            }
        }
        .onAppear {
            subscriptionRepository = SubscriptionRepository(modelContext: modelContext)
            isNotificationEnabled = subscription.isNotificationEnabled
            // Load notification count
            Task {
                let count = await NotificationService.shared.getScheduledNotificationsCount(for: subscription)
                scheduledNotificationsCount = count
            }
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
                Text(subscription.price, format: .currency(code: subscription.currencyCode))
            }
            
            if subscription.currencyCode != appSettings.currencyCode {
                HStack {
                    let convertedPrice = exchangeRates.convert(subscription.price, from: subscription.currencyCode, to: appSettings.currencyCode) ?? subscription.price
                    Text("Actual Price")
                    Spacer()
                    Text(convertedPrice, format: .currency(code: appSettings.currencyCode))
                }
            }
            
        } header: {
            Text("Subscription")
        }
    }
    
    private var subscriptionDetailsInfoSection: some View {
        Section {
            
            HStack {
                
                Text("Tags")
                
                Spacer()
                
                Text(subscription.tags.prefix(2).map { $0.name }.joined(separator: ", ") + (subscription.tags.count > 2 ? ", ..." : ""))
                
                Button {
                    showTagsSheet = true
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            
            
            HStack {
                Text("Period")
                Spacer()
                Text(subscription.period.description)
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
                VStack(alignment: .trailing) {
                    Text(monthlyPrice, format: .currency(code: subscription.currencyCode))
                    Text(convertedMonthlyPrice, format: .currency(code: appSettings.currencyCode))
                }
            }
            
            HStack {
                Text("Price a Year")
                Spacer()
                VStack(alignment: .trailing) {
                    Text(yearlyPrice, format: .currency(code: subscription.currencyCode))
                    Text(convertedYearlyPrice, format: .currency(code: appSettings.currencyCode))
                }
            }
            
            HStack {
                Text("Since First Payment")
                Spacer()
                VStack(alignment: .trailing) {
                    Text(totalPaidSinceStart, format: .currency(code: subscription.currencyCode))
                    Text(exchangeRates.convert(totalPaidSinceStart, from: subscription.currencyCode, to: appSettings.currencyCode) ?? subscription.totalAmountTillToday(), format: .currency(code: appSettings.currencyCode))
                }
            }
            
        } header: {
            Text("Price Details")
        } footer: {
            Text("Exchange Rates updates every day")
        }
    }
    
    // MARK: - Notification Settings
    
    private var notificationSettingsSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { subscription.isNotificationEnabled },
                set: { newValue in
                    withAnimation {
                        isNotificationEnabled = newValue
                        subscription.isNotificationEnabled = newValue
                    }
                }
            )) {
                Text("Reminder Notifications")
            }
            .onChange(of: subscription.isNotificationEnabled) { _, newValue in
                Task {
                    if newValue {
                        await subscription.scheduleNotifications()
                        let count = await NotificationService.shared.getScheduledNotificationsCount(for: subscription)
                        scheduledNotificationsCount = count
                    } else {
                        await NotificationService.shared.cancelNotifications(for: subscription)
                    }
                }
            }
            .onChange(of: subscription.notificationTiming) { _, newValue in
                Task {
                    await NotificationService.shared.cancelNotifications(for: subscription)
                    await subscription.scheduleNotifications()
                    let count = await NotificationService.shared.getScheduledNotificationsCount(for: subscription)
                    scheduledNotificationsCount = count
                }
            }
            
            if isNotificationEnabled {
                Group {
                    HStack {
                        Text("Next Payment")
                        Spacer()
                        Text("\(daysUntilNextPayment) days")
                            .foregroundStyle(.secondary)
                    }
                    
                    Picker(selection: Binding(
                        get: { subscription.notificationTiming },
                        set: { newValue in
                            selectedReminder = newValue
                            subscription.notificationTiming = newValue
                        }
                    )) {
                        ForEach(NotificationDate.allCases) { option in
                            Text(LocalizedStringKey(option.description)).tag(option)
                        }
                    } label: {
                        Text("Reminds me")
                    } currentValueLabel: {
                        Text(LocalizedStringKey(selectedReminder.description))
                    }
                    .pickerStyle(.navigationLink)
                    
                    // Show scheduled notifications count
                    NavigationLink {
                        NotificationListView(subscription: subscription)
                    } label: {
                        HStack {
                            Text("Scheduled Reminders")
                            
                            Spacer()
                            
                            if let count = scheduledNotificationsCount {
                                Text("\(count)")
                                    .foregroundColor(.secondary)
                            } else {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .transition(.slide)
            }
        } header: {
            Text("Notification Settings")
        } footer: {
            if subscription.isNotificationEnabled {
                Text("You will receive a notification \(selectedReminder.description) before the next payment date.")
            }
        }
    }
    
    // MARK: - calculations
    
    private var monthlyPrice: Decimal {
        switch subscription.period {
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
    
    private var convertedMonthlyPrice: Decimal {
        let convertedPrice = exchangeRates.convert(
            subscription.price,
            from: subscription.currencyCode,
            to: appSettings.currencyCode
        ) ?? subscription.price
        
        switch subscription.period {
        case .semimonthly:
            return convertedPrice * 2
        case .monthly:
            return convertedPrice
        case .bimonthly:
            return convertedPrice / 2
        case .quarterly:
            return convertedPrice / 3
        case .semiannually:
            return convertedPrice / 6
        case .annually:
            return convertedPrice / 12
        case .biennially:
            return convertedPrice / 24
        case .custom:
            // For custom billing cycles, we need a more complex approach
            return convertedPrice // Default assumption
        }
    }
    
    private var yearlyPrice: Decimal {
        switch subscription.period {
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
    
    private var convertedYearlyPrice: Decimal {
        let convertedPrice = exchangeRates.convert(
            subscription.price,
            from: subscription.currencyCode,
            to: appSettings.currencyCode
        ) ?? subscription.price
        
        switch subscription.period {
        case .semimonthly:
            return convertedPrice * 24
        case .monthly:
            return convertedPrice * 12
        case .bimonthly:
            return convertedPrice * 6
        case .quarterly:
            return convertedPrice * 4
        case .semiannually:
            return convertedPrice * 2
        case .annually:
            return convertedPrice
        case .biennially:
            return convertedPrice * 0.5
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
        var billingDate = subscription.firstBillingDate
        
        while billingDate <= today {
            cycles += 1
            
            // Get next billing date
            guard let nextDate = calendar.date(byAdding: billingCycleComponent, value: billingCycleValue, to: billingDate) else {
                break
            }
            
            billingDate = nextDate
        }
        
        // If we're calculating from the start date and it's not
        // exactly aligned with billing cycles, subtract 1
        if cycles > 0 && billingDate > today {
            cycles -= 1
        }
        
        return subscription.price * Decimal(cycles)
    }
    
    // Helper properties for calculating billing cycles
    private var billingCycleComponent: Calendar.Component {
        switch subscription.period {
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
        switch subscription.period {
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
            return String(localized: "1 day before")
        case .three_day_before:
            return String(localized: "3 days before")
        case .one_week_before:
            return String(localized: "1 week before")
        }
    }
}


#Preview {
    @Previewable @State var subscription = Subscription(
        id: UUID(),
        name: "Test Subscription",
        price: 10.0,
        period: .monthly,
        firstBillingDate: Date(),
        tags: [],
        icon: "",
        colorHex: "#000000"
    )
    SubscriptionDetailView(subscription: subscription)
        .environmentObject(AppSettings())
        .environmentObject(ExchangeRateRepository())
}
