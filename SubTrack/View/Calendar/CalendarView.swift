//
//  CalendarView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/21.
//
import SwiftUI
import SwiftData


struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var exchangeRates: ExchangeRateRepository
    
    @Query private var subscriptions: [Subscription]
    
    @State private var calendarState = CalendarState()
    @State private var repository: SubscriptionRepository?
    @State private var showAddSubscriptionView: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            monthSelectorView
                .padding(.horizontal)
            
            weekdayHeaderView
            
            if calendarState.isLoading {
                ProgressView()
                    .frame(height: 300)
            } else {
                GeometryReader { proxy in
                    Group {
                        if calendarState.viewType == .standard {
                            BasicCalendarGrid(state: calendarState)
                                .frame(width: proxy.size.width)
                        } else {
                            ListCalendarGrid(state: calendarState)
                        }
                    }
                }
            }
            
            if calendarState.viewType == .listBullet {
                if let selectedDate = calendarState.selectedDate {
                    Divider()
                        .padding(.top, 8)
                    
                    selectedDateView(date: selectedDate)
                }
            } else {
                Spacer()
            }
        }
        .padding(.top, 0)
        .navigationTitle("Total Costs: \(formattedMonthlyTotal(currency: appSettings.currencyCode))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        calendarState.toggleViewType()
                    }
                } label: {
                    Image(systemName: calendarState.viewType == .standard ? "list.bullet.below.rectangle" : "list.dash.header.rectangle")
                }

                Button {
                    showAddSubscriptionView = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSubscriptionView) {
            NavigationStack {
                AddSubscriptionView()
            }
        }
        .task(id: calendarState.selectedMonth) {
            await generateCalendarDates()
        }
        .onAppear {
            repository = SubscriptionRepository(modelContext: modelContext)
        }
        .onChange(of: subscriptions) { _, _ in
            // Refresh calendar when subscriptions change
            Task {
                await generateCalendarDates()
            }
        }
    }
    
    private var monthSelectorView: some View {
        HStack {
            Button{
                calendarState.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            
            Text(calendarState.selectedMonth.formatted(.dateTime.month().year()))
                .font(.title2.bold())
            
            Spacer()
            
            Button {
                calendarState.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
            }
        }
    }
    
    private var weekdayHeaderView: some View {
        HStack {
            ForEach(Calendar.current.veryShortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
    
    @MainActor
    private func generateCalendarDates() async {
        calendarState.isLoading = true
        defer { calendarState.isLoading = false }
        
        let calendar = Calendar.current
        var newDates: [CalendarDate] = []
        
        // Get first day of the month
        let components = calendar.dateComponents([.year, .month], from: calendarState.selectedMonth)
        guard let firstDayOfMonth = calendar.date(from: components),
              let numberOfDays = calendar.range(of: .day, in: .month, for: calendarState.selectedMonth)?.count else {
            return
        }
        
        
        // Get the weekday of the first day (0 is Sunday, 1 is Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Add days from the previous month to fill the first week
        let previousMonthDays = firstWeekday - 1
        if previousMonthDays > 0 {
            for dayOffset in (1...previousMonthDays).reversed() {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: firstDayOfMonth) {
                    var calendarDate = CalendarDate(date: date, isCurrentMonth: false)
                    calendarDate.subscriptions = repository?.fetchSubscriptionsForDate(date) ?? []
                    newDates.append(calendarDate)
                }
            }
        }
        
        // Add days from the current month
        for dayOffset in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
                var calendarDate = CalendarDate(date: date)
                calendarDate.subscriptions = repository?.fetchSubscriptionsForDate(date) ?? []
                newDates.append(calendarDate)
                
                // Select today's date by default if it's in the current month
                if calendar.isDateInToday(date) {
                    calendarState.selectedDate = calendarDate
                }
            }
        }
        
        // Fill the remaining days from the next month to complete the last week
        let totalDays = previousMonthDays + numberOfDays
        let remainingDays = 7 - (totalDays % 7)
        if remainingDays < 7 {
            for dayOffset in 1...remainingDays {
                if let date = calendar.date(byAdding: .day, value: numberOfDays + dayOffset - 1, to: firstDayOfMonth) {
                    var calendarDate = CalendarDate(date: date, isCurrentMonth: false)
                    calendarDate.subscriptions = repository?.fetchSubscriptionsForDate(date) ?? []
                    newDates.append(calendarDate)
                }
            }
        }
        
        calendarState.dates = newDates
    }
    
    private func calculateMonthlyTotal() -> Double {
        let currentMonthDates = calendarState.dates.filter { $0.isCurrentMonth }
        
        var processedSubscriptionIds = Set<String>()
        var totalCost: Decimal = 0
        
        for calendarDate in currentMonthDates {
            for subscription in calendarDate.subscriptions {
                if processedSubscriptionIds.contains(subscription.id.uuidString) {
                    continue
                }
                
                processedSubscriptionIds.insert(subscription.id.uuidString)
                
                let convertedPrice = exchangeRates.convert(
                    subscription.price,
                    from: subscription.currencyCode,
                    to: appSettings.currencyCode
                ) ?? subscription.price
                
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
        }
        
        return NSDecimalNumber(decimal: totalCost).doubleValue
    }
    
    private func formattedMonthlyTotal(currency: String) -> String {
        let total = calculateMonthlyTotal()
        let formatStyle: Decimal.FormatStyle.Currency = CurrencyInfo.hasDecimals(currency) ? .currency(code: currency) : .currency(code: currency).precision(.fractionLength(0))
        return Decimal(total).formatted(formatStyle)
    }
    
    private func selectedDateView(date: CalendarDate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateString(from: date.date))
                .font(.headline)
            
            ScrollView {
                if date.subscriptions.isEmpty {
                    ContentUnavailableView {
                        Label("No Subscriptions", systemImage: "text.page.slash")
                    } description: {
                        Text("Subscriptions will appear here if the payment due date is reached.")
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(date.subscriptions) { subscription in
                            SubscriptionListItemView(subscription: subscription) { subscription in
                                modelContext.delete(subscription)
                            }
                        }
                    }
                }
            }
            .defaultScrollAnchor(.center, for: .alignment)
        }
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct BasicCalendarGrid: View {
    let state: CalendarState
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(state.dates) { date in
                BasicCalendarDayView(
                    calendarDate: date,
                    isSelected: state.selectedDate?.id == date.id,
                    isToday: Calendar.current.isDateInToday(date.date)
                )
                .onTapGesture {
                    state.selectedDate = date
                }
            }
        }
    }
}

struct ListCalendarGrid: View {
    let state: CalendarState
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(state.dates) { date in
                ComboCalendarDayView(
                    calendarDate: date,
                    isSelected: state.selectedDate?.id == date.id,
                    isToday: Calendar.current.isDateInToday(date.date)
                )
                .onTapGesture {
                    state.selectedDate = date
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CalendarView()
            .environmentObject(AppSettings())
            .environmentObject(ExchangeRateRepository())
    }
}
