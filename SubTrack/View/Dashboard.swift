//
//  Dashboard.swift
//  SubTrack
//
//  Created by Sam on 2025/5/12.
//
import SwiftUI
import SwiftData
import Charts


struct Dashboard: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var exchangeRates: ExchangeRateRepository
    @EnvironmentObject private var appSettings: AppSettings
    @Query private var subscriptions: [Subscription]
    
    var body: some View {
        ScrollView {
            
            VStack(spacing: 8) {
                
                HStack {
                    Text(Date(), format: .dateTime.month(.wide).day())
                        .font(.title)
                        .bold()
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                monthlyTotalCard
                
                upcomingSection
                
                metricsSection
                
                categoryBreakdownSection
            }
        }
    }
    
    private var monthlyTotalCard: some View {
        HStack {
            
            Spacer()
            
            VStack {
                Text("Due This Month")
                
                Text("\(formattedMonthlyTotal(currency: appSettings.currencyCode))")
                    .bold()
            }
            .padding()
            
            Spacer()
            
            VStack {
                Text("Total Subs")
                
                Text("\(subscriptions.count)")
                    .bold()
            }
            .foregroundStyle(.primary)
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: appSettings.appTheme != .system ? (appSettings.appTheme == .dark ? [
                    .blue,
                    .purple
                ] : [
                    Color(red: 0.6, green: 0.85, blue: 1.0), // Sky blue
                    Color(red: 0.7, green: 1.0, blue: 0.8)
                ]) : colorScheme == .dark ? [.blue, .purple] : [Color(red: 0.6, green: 0.85, blue: 1.0), // Sky blue
                                                                Color(red: 0.7, green: 1.0, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .padding(.horizontal)
    }
    
    private var upcomingSection: some View {
        let sortedSubscriptions = subscriptions.sorted { $0.nextBillingDate < $1.nextBillingDate }
        // Then take the first 7
        let limitedSubscriptions = sortedSubscriptions.filter { Date.getDaysBetween(startDate: Date(), endDate: $0.nextBillingDate) <= appSettings.daysToShowUpcomingSubscriptions }
        // Then chunk them into groups of 4
        let chunkedSubscriptions = Array(limitedSubscriptions).chunked(into: 4)
        
        return VStack(alignment: .leading, spacing: 0) {
            Text("Upcoming")
                .bold()
                .font(.title2)
            
            TabView {
                if chunkedSubscriptions.isEmpty {
                    Text("No Subscriptions upcoming in \(appSettings.daysToShowUpcomingSubscriptions) days.")
                } else {
                    ForEach(Array(chunkedSubscriptions.enumerated()), id: \.offset) { _, chunk in
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ]) {
                            ForEach(chunk, id: \.self) { subscription in
                                SubscriptionShortItemView(subscription: subscription)
                                    .frame(height: 60)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: calculateTabViewHeight())
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .padding(.horizontal)
    }
    
    private func calculateTabViewHeight() -> CGFloat {
        // Calculate height based on row count (2 rows in your case)
        let rowCount = 2
        let itemHeight: CGFloat = 60
        let rowSpacing: CGFloat = 10
        let verticalPadding: CGFloat = 10
        
        // Total height = (item height × row count) + spacing between rows + top and bottom padding
        return (itemHeight * CGFloat(rowCount)) + (rowSpacing * CGFloat(rowCount - 1)) + verticalPadding
    }
    
    private func formattedMonthlyTotal(currency: String) -> String {
        let total = calculateMonthlyTotal()
        let formatStyle: Decimal.FormatStyle.Currency = CurrencyInfo.hasDecimals(currency) ? .currency(code: currency) : .currency(code: currency).precision(.fractionLength(0))
        return Decimal(total).formatted(formatStyle)
    }
    
    private func calculateMonthlyTotal() -> Double {
        let monthlySubs = subscriptions.filter({ $0.period == .monthly })
        var processedSubscriptionIds = Set<String>()
        var totalCost: Decimal = 0
        
        for sub in monthlySubs {
            
            if processedSubscriptionIds.contains(sub.id.uuidString) {
                continue
            }
            
            processedSubscriptionIds.insert(sub.id.uuidString)
            
            let convertedPrice = exchangeRates.convert(
                sub.price,
                from: sub.currencyCode,
                to: appSettings.currencyCode
            ) ?? sub.price
            
            totalCost += convertedPrice
            //                switch calculationMethod {
            //                case .actualBilling:
            //                    totalCost += convertedPrice
            //                case .amortized:
            //                    if subscription.period == .annually {
            //                        totalCost += convertedPrice / 12
            //                    } else {
            //                        totalCost += convertedPrice
            //                    }
            //                }
        }

        return NSDecimalNumber(decimal: totalCost).doubleValue
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


extension Dashboard {
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Subscription Stats")
                .bold()
                .font(.title2)
            
            HStack(spacing: 16) {
                // Average Monthly Cost
                metricCard(
                    title: "Avg Cost",
                    value: formattedAverageCost(),
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                // Most expensive subscription
                if let mostExpensive = getMostExpensiveSubscription() {
                    metricCard(
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
                metricCard(
                    title: "Most Common",
                    value: getMostCommonBillingCycle(),
                    icon: "calendar.circle.fill",
                    color: .blue
                )
                
                metricCard(
                    title: "Annual Cost",
                    value: formattedYearlyTotal(),
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    color: .purple
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func metricCard(title: String, value: String, details: String? = nil, icon: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(LocalizedStringKey(title))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if details == nil {
                Spacer()
            }
            
            Text(value)
                .font(.headline)
                .lineLimit(1)
            
            if let details = details {
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 60)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    // Helper methods for metrics
    private func formattedAverageCost() -> String {
        guard !subscriptions.isEmpty else { return "N/A" }
        
        let totalMonthly = subscriptions.reduce(Decimal(0), { result, subscription in
            let convertedPrice = exchangeRates.convert(
                subscription.price,
                from: subscription.currencyCode,
                to: appSettings.currencyCode
            ) ?? subscription.price
            
            // Convert to monthly equivalent
            switch subscription.period {
            case .monthly:
                return result + convertedPrice
            case .quarterly:
                return result + (convertedPrice / 3)
            case .semiannually:
                return result + (convertedPrice / 6)
            case .annually:
                return result + (convertedPrice / 12)
            default:
                return result + convertedPrice
            }
        })
        
        let average = totalMonthly / Decimal(subscriptions.count)
        let formatStyle = CurrencyInfo.hasDecimals(appSettings.currencyCode) ?
        Decimal.FormatStyle.Currency.currency(code: appSettings.currencyCode) :
        Decimal.FormatStyle.Currency.currency(code: appSettings.currencyCode).precision(.fractionLength(0))
        
        return average.formatted(formatStyle)
    }
    
    private func getMostExpensiveSubscription() -> Subscription? {
        return subscriptions.max { a, b in
            let aPrice = exchangeRates.convert(a.price, from: a.currencyCode, to: appSettings.currencyCode) ?? a.price
            let bPrice = exchangeRates.convert(b.price, from: b.currencyCode, to: appSettings.currencyCode) ?? b.price
            
            return aPrice < bPrice
        }
    }
    
    private func getMostCommonBillingCycle() -> String {
        let cycles = subscriptions.map { $0.period }
        let cycleCount = Dictionary(grouping: cycles) { $0 }.mapValues { $0.count }
        
        if let mostCommon = cycleCount.max(by: { $0.value < $1.value })?.key {
            return mostCommon.description
        }
        
        return "Monthly"
    }
    
    private func formattedYearlyTotal() -> String {
        // Get current monthly total and multiply by 12 for yearly projection
        let monthlyTotal = Decimal(calculateMonthlyTotal())
        let yearlyProjection = monthlyTotal * 12
        
        let formatStyle = CurrencyInfo.hasDecimals(appSettings.currencyCode) ?
        Decimal.FormatStyle.Currency.currency(code: appSettings.currencyCode) :
        Decimal.FormatStyle.Currency.currency(code: appSettings.currencyCode).precision(.fractionLength(0))
        
        return yearlyProjection.formatted(formatStyle)
    }
}

extension Dashboard {
    
    struct TagBreakdownItem {
        let tag: Tag
        let totalCost: Decimal
        let percentage: Decimal
    }

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading) {
            Text("Tags Breakdown")
                .bold()
                .font(.title2)
            
            if subscriptions.isEmpty {
                Text("Add subscriptions with tags to see your tag breakdown")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                categoryBreakdownChart
            }
        }
        .padding(.horizontal)
    }
    
    private var categoryBreakdownChart: some View {
        let tagData = calculateTagBreakdown()
        
        return VStack {
            Chart {
                ForEach(tagData, id: \.tag) { item in
                    sectorMarkForItem(item)
                }
            }
            .frame(height: 200)
            
            // Legend below the chart
            categoryLegend(tagData: tagData)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private func sectorMarkForItem(_ item: TagBreakdownItem) -> some ChartContent {
        SectorMark(
            angle: .value("Cost", item.totalCost),
            innerRadius: .ratio(0.5),
            angularInset: 1.5
        )
        .foregroundStyle(by: .value("Category", item.tag.name))
        .annotation(position: .overlay) {
            sectorAnnotation(for: item)
        }
    }
    
    @ViewBuilder
    private func sectorAnnotation(for item: TagBreakdownItem) -> some View {
        if item.percentage >= 10 {
            let percentageInt = NSDecimalNumber(decimal: item.percentage).intValue
            Text("\(percentageInt)%")
                .font(.caption)
                .bold()
                .foregroundStyle(.white)
        }
    }
    
    @ViewBuilder
    private func categoryLegend(tagData: [TagBreakdownItem]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
            ForEach(Array(tagData.enumerated()), id: \.element.tag) { index, item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(colorForTag(item.tag, index: index))
                        .frame(width: 10, height: 10)
                    
                    Text(item.tag.name)
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(formatCurrency(item.totalCost))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // Helper function to get color for a tag (you can customize this)
    private func colorForTag(_ tag: Tag, index: Int) -> Color {
        // You could use a deterministic color based on the tag name, or add a color property to your Tag model
        // For now, using a simple hash-based approach
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .yellow, .teal]
//        let index = abs(tag.name.hashValue) % colors.count
        return colors[index]
    }
    
    // Calculate data for the chart
    private func calculateTagBreakdown() -> [TagBreakdownItem] {
        // Handle subscriptions with no tags by creating a "Uncategorized" tag
        let uncategorizedTag = Tag(name: "Uncategorized")
        
        // Group subscriptions by tag
        var tagTotals: [Tag: Decimal] = [:]
        var totalCost: Decimal = 0
        
        for subscription in subscriptions where subscription.isActive {
            let convertedPrice = exchangeRates.convert(
                subscription.price,
                from: subscription.currencyCode,
                to: appSettings.currencyCode
            ) ?? subscription.price
            
            // Normalize to monthly cost
            let monthlyCost: Decimal
            switch subscription.period {
            case .monthly: monthlyCost = convertedPrice
            case .quarterly: monthlyCost = convertedPrice / 3
            case .semiannually: monthlyCost = convertedPrice / 6
            case .annually: monthlyCost = convertedPrice / 12
            default: monthlyCost = convertedPrice
            }
            
            totalCost += monthlyCost
            
            if subscription.tags.isEmpty {
                tagTotals[uncategorizedTag, default: 0] += monthlyCost
            } else {
                for tag in subscription.tags {
                    tagTotals[tag, default: 0] += monthlyCost
                }
            }
        }
        
        // Convert to array and calculate percentages
        var result = tagTotals.map { tag, cost in
            let percentage = totalCost > 0 ? (cost / totalCost) * 100 : 0
            return TagBreakdownItem(tag: tag, totalCost: cost, percentage: percentage)
        }
        
        // Sort by cost (highest first)
        result.sort { $0.totalCost > $1.totalCost }
        
        return result
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatStyle = CurrencyInfo.hasDecimals(appSettings.currencyCode) ?
            Decimal.FormatStyle.Currency.currency(code: appSettings.currencyCode) :
            Decimal.FormatStyle.Currency.currency(code: appSettings.currencyCode).precision(.fractionLength(0))
            
        return amount.formatted(formatStyle)
    }
}
