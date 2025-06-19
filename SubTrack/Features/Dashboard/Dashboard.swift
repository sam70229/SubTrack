//
//  Dashboard.swift
//  SubTrack
//
//  Created by Sam on 2025/5/12.
//
import SwiftUI
import SwiftData
import Charts

struct DashboardMetrics: Equatable {
    let monthlyTotal: Decimal
    let yearlyProjection: Decimal
    let averageMonthlyCost: Decimal
    let activeSubscriptionCount: Int
    let monthlySubscriptionCount: Int
    let mostExpensiveSubscription: Subscription?
    let mostCommonBillingCycle: Period
}

struct TagBreakdownItem: Identifiable {
    let id = UUID()
    let tag: Tag
    let totalCost: Decimal
    let percentage: Decimal
}


struct Dashboard: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var exchangeRates: ExchangeRateRepository
    @EnvironmentObject private var appSettings: AppSettings
    @Query private var subscriptions: [Subscription]
    
    @State private var showAddSubscription: Bool = false
    
    private var metrics: DashboardMetrics {
        calculateMetrics()
    }
    
    private var upcomingSubscriptions: [Subscription] {
        subscriptions
            .filter { Date.getDaysBetween(startDate: Date(), endDate: $0.nextBillingDate) <= appSettings.daysToShowUpcomingSubscriptions }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }
    
    private var tagBreakdown: [TagBreakdownItem] {
        calculateTagBreakdown()
    }
    
    var body: some View {
        ScrollView {
            
            VStack(spacing: 20) {
                
                summarySection
                
                upcomingSection
                
                metricsSection
                
                categoryBreakdownSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(Date(), format: .dateTime.month(.wide).day())")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSubscription = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSubscription) { NavigationStack {
                AddSubscriptionView()
            }
        }
    }
    
    private var summarySection: some View {
        HStack(spacing: 0) {
            metricView(title: "Due This Month", value: formatCurrency(metrics.monthlyTotal))
            
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 50)
                        
            metricView(title: "Subs this month", value: "\(metrics.monthlySubscriptionCount)")
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundGradient)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
    
    private func metricView(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(LocalizedStringKey(title))
                .font(.caption)
                .opacity(0.9)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var backgroundGradient: LinearGradient {
        let isDarkMode = appSettings.appTheme == .dark ||
        (appSettings.appTheme == .system && colorScheme == .dark)
        
        let colors = isDarkMode
        ? [Color.blue, Color.purple]
        : [Color(red: 0.6, green: 0.85, blue: 1.0),
           Color(red: 0.7, green: 1.0, blue: 0.8)]
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming")
                .bold()
                .font(.title2)
            
            if upcomingSubscriptions.isEmpty {
                EmptyStateCard(
                    message: "No subscriptions upcoming in \(appSettings.daysToShowUpcomingSubscriptions) days.",
                    icon: "calendar.badge.clock"
                )
            } else {
                UpcomingSubscriptionsPager(subscriptions: upcomingSubscriptions)
            }
        }
        .padding(.horizontal)
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Subscription Stats")
                .bold()
                .font(.title2)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Average Monthly Cost
                    MetricCard(
                        title: "Avg Cost",
                        value: formatCurrency(metrics.averageMonthlyCost),
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                    
                    // Most expensive subscription
                    if let mostExpensive = getMostExpensiveSubscription() {
                        MetricCard(
                            title: "Highest",
                            value: mostExpensive.name,
                            details: mostExpensive.formattedPrice(),
                            icon: "arrow.up.circle.fill",
                            color: .red
                        )
                    }
                }
                
                HStack(spacing: 16) {
                    // Most common Period
                    MetricCard(
                        title: "Most Common",
                        value: metrics.mostCommonBillingCycle.description,
                        icon: "calendar.circle.fill",
                        color: .blue
                    )
                    
                    MetricCard(
                        title: "Annual Cost",
                        value: formatCurrency(metrics.yearlyProjection),
                        icon: "chart.line.uptrend.xyaxis.circle.fill",
                        color: .purple
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading) {
            Text("Tags Breakdown")
                .font(.title2)
                .fontWeight(.bold)
            
            if tagBreakdown.isEmpty {
                EmptyStateCard(
                    message: "Add subscriptions with tags to see your tag breakdown",
                    icon: "tag.circle"
                )
            } else {
                CategoryBreakdownChart(tagData: tagBreakdown)
                    .environment(\.currencyCode, appSettings.currencyCode)
            }
        }
        .padding(.horizontal)
    }
}


private extension Dashboard {
    func calculateMetrics() -> DashboardMetrics {
            let activeSubscriptions = subscriptions.filter { $0.isActive }
            let monthlyTotal = calculateMonthlyTotal()
            
            return DashboardMetrics(
                monthlyTotal: monthlyTotal,
                yearlyProjection: monthlyTotal * 12,
                averageMonthlyCost: calculateAverageMonthlyCost(),
                activeSubscriptionCount: activeSubscriptions.count,
                monthlySubscriptionCount: getSubscriptionForMonth(),
                mostExpensiveSubscription: getMostExpensiveSubscription(),
                mostCommonBillingCycle: getMostCommonBillingCycle()
            )
        }
    
    func getSubscriptionForMonth() -> Int {
        var monthlyCount = 0
        
        let calendar = Calendar.current
        let date = Date()
        
        let thisMonth = calendar.dateComponents([.month], from: date)
        // Get monthly first
        for sub in subscriptions {
            switch sub.period {
            case .bimonthly, .quarterly, .semiannually, .annually, .biennially:
                if calendar.dateComponents([.month], from: sub.nextBillingDate) == thisMonth {
                    monthlyCount += 1
                }
            case .monthly:
                monthlyCount += 1
            case .semimonthly:
                monthlyCount += 2
            case .custom:
                monthlyCount += 0
            }
        }
        return monthlyCount
    }
        
        func calculateMonthlyTotal() -> Decimal {
            subscriptions
                .filter { $0.isActive && $0.period == .monthly }
                .reduce(Decimal(0)) { total, subscription in
                    total + convertToUserCurrency(subscription.price, from: subscription.currencyCode)
                }
        }
        
        func calculateAverageMonthlyCost() -> Decimal {
            guard !subscriptions.isEmpty else { return 0 }
            
            let totalMonthly = subscriptions.reduce(Decimal(0)) { result, subscription in
                let convertedPrice = convertToUserCurrency(subscription.price, from: subscription.currencyCode)
                return result + normalizeToMonthlyCost(convertedPrice, period: subscription.period)
            }
            
            return totalMonthly / Decimal(subscriptions.count)
        }
        
        func getMostExpensiveSubscription() -> Subscription? {
            subscriptions.max { a, b in
                convertToUserCurrency(a.price, from: a.currencyCode) <
                convertToUserCurrency(b.price, from: b.currencyCode)
            }
        }
        
        func getMostCommonBillingCycle() -> Period {
            let cycles = subscriptions.map { $0.period }
            let cycleCount = Dictionary(grouping: cycles) { $0 }.mapValues { $0.count }
            return cycleCount.max(by: { $0.value < $1.value })?.key ?? .monthly
        }
        
        func calculateTagBreakdown() -> [TagBreakdownItem] {
            let uncategorizedTag = Tag(name: String(localized: "Uncategorized"))
            var tagTotals: [Tag: Decimal] = [:]
            var totalCost: Decimal = 0
            
            for subscription in subscriptions where subscription.isActive {
                let monthlyCost = normalizeToMonthlyCost(
                    convertToUserCurrency(subscription.price, from: subscription.currencyCode),
                    period: subscription.period
                )
                
                totalCost += monthlyCost
                
                if let tags = subscription.tags {
                    if tags.isEmpty {
                        tagTotals[uncategorizedTag, default: 0] += monthlyCost
                    } else {
                        for tag in tags {
                            tagTotals[tag, default: 0] += monthlyCost
                        }
                    }
                }
            }
            
            return tagTotals.map { tag, cost in
                let percentage = totalCost > 0 ? (cost / totalCost) * 100 : 0
                return TagBreakdownItem(tag: tag, totalCost: cost, percentage: percentage)
            }
            .sorted { $0.totalCost > $1.totalCost }
        }
        
        func convertToUserCurrency(_ amount: Decimal, from: String) -> Decimal {
            exchangeRates.convert(amount, from: from, to: appSettings.currencyCode) ?? amount
        }
        
        func normalizeToMonthlyCost(_ amount: Decimal, period: Period) -> Decimal {
            switch period {
            case .monthly: return amount
            case .quarterly: return amount / 3
            case .semiannually: return amount / 6
            case .annually: return amount / 12
            default: return amount
            }
        }
        
        func formatCurrency(_ amount: Decimal) -> String {
            let formatStyle = CurrencyInfo.hasDecimals(appSettings.currencyCode)
                ? Decimal.FormatStyle.Currency.currency(code: appSettings.currencyCode)
                : Decimal.FormatStyle.Currency.currency(code: appSettings.currencyCode).precision(.fractionLength(0))
            
            return amount.formatted(formatStyle)
        }
}

// MARK: - Supporting Views

struct UpcomingSubscriptionsPager: View {
    let subscriptions: [Subscription]
    
    private let columnsPerPage = 4
    private let rowsPerPage = 2
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    private var pages: [[Subscription]] {
        subscriptions.chunked(into: columnsPerPage)
    }
    
    var body: some View {
        TabView {
            ForEach(Array(pages.enumerated()), id: \.offset) { _, page in
                VStack(spacing: 12) {
                    ForEach(0..<rowsPerPage, id: \.self) { row in
                        HStack(spacing: 12) {
                            ForEach(0..<2, id: \.self) { col in
                                let index = row * 2 + col
                                if index < page.count {
                                    NavigationLink {
                                        SubscriptionDetailView(subscription: page[index])
                                    } label: {
                                        SubscriptionShortItemView(subscription: page[index])
                                            .frame(height: 60)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    // Empty space to maintain alignment
                                    Color.clear
                                        .frame(height: 60)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(height: 140)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//        .cardBackground(cornerRadius: 16, shadowRadius: 3)
    }
}

struct MetricCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    var details: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.body)
                
                Text(LocalizedStringKey(title))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                
                if let details = details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(
                    color: colorScheme == .dark ? .white.opacity(0.05) : .black.opacity(0.08),
                    radius: colorScheme == .dark ? 3 : 5,
                    x: 0,
                    y: colorScheme == .dark ? 1 : 2
                )
        )
    }
}

struct EmptyStateCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(LocalizedStringKey(message))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
        )
    }
}

import Charts

struct CategoryBreakdownChart: View {
    @Environment(\.currencyCode) private var currencyCode
    @Environment(\.colorScheme) private var colorScheme
    let tagData: [TagBreakdownItem]
    
    private let chartColors: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .yellow, .teal]
    
    var body: some View {
        VStack(spacing: 16) {
            Chart {
                ForEach(Array(tagData.enumerated()), id: \.element.id) { index, item in
                    SectorMark(
                        angle: .value("", item.totalCost),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(chartColors[index % chartColors.count])
                    .annotation(position: .overlay) {
                        if item.percentage >= 10 {
                            Text("\(item.percentage.rounding(to: 0, mode: .plain))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .frame(height: 200)
            
            CategoryLegend(tagData: tagData, colors: chartColors)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(
                    color: colorScheme == .dark ? .white.opacity(0.05) : .black.opacity(0.08),
                    radius: colorScheme == .dark ? 3 : 8,
                    x: 0,
                    y: colorScheme == .dark ? 1 : 2
                )
        )
    }
}

struct CategoryLegend: View {
    @Environment(\.currencyCode) private var currencyCode
    let tagData: [TagBreakdownItem]
    let colors: [Color]
    
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(Array(tagData.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(colors[index % colors.count])
                        .frame(width: 12, height: 12)
                    
                    Text(item.tag.name)
                        .font(.caption)
                        .lineLimit(1)
                    
                    Spacer(minLength: 4)
                    
                    Text(formatCurrency(item.totalCost))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatStyle = CurrencyInfo.hasDecimals(currencyCode)
            ? Decimal.FormatStyle.Currency.currency(code: currencyCode)
            : Decimal.FormatStyle.Currency.currency(code: currencyCode).precision(.fractionLength(0))
        
        return amount.formatted(formatStyle)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Subscription.self, configurations: config)
    //    var date = Date()
    //    for i in 1..<10 {
    //        let sub = Subscription(name: "TEst_\(i)", subscriptionDescription: "test description", price: 100, currencyCode: "USD", period: .monthly, firstBillingDate: date, tags: [], creditCard: nil, icon: "cloud", colorHex: Color.blue.toHexString(), isActive: true, createdAt: Date())
    //        container.mainContext.insert(sub)
    //        date = Calendar.current.date(byAdding: .month, value: -1, to: date)!
    //        date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
    //    }
    return Dashboard()
        .modelContainer(container)
        .environmentObject(AppSettings())
        .environmentObject(ExchangeRateRepository())
}
