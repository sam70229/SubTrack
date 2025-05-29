//
//  NewCalendarView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/26.
//
import SwiftUI
import SwiftData


struct NewCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var exchangeRates: ExchangeRateRepository
    
    @StateObject private var calendarState = CalendarState()
    @Query private var subscriptions: [Subscription]
    @State private var repository: SubscriptionRepository?
    
    @State private var showAddSubscriptionView: Bool = false
    
    // Local view state for gesture handling
    @GestureState private var dragOffset: CGFloat = 0
    @State private var activeOffset: CGFloat = 0
    @State private var previousMonth: Date = Date()
    @State private var nextMonth: Date = Date()
    
    
    // Add state to control animation of header components
    @State private var isTransitioning = false
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    monthSelectorView
                        .transition(.opacity)
                        .padding(.horizontal)
                    //                .padding(.top, 10)
                    
                    weekdayHeaderView
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                }
                .frame(height: 80)
                .zIndex(1)
                
                ZStack {
                    monthGridContainer
//                    if calendarState.isLoading {
//                        ProgressView()
//                    } else {
//                        monthGridContainer
//                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(.top, 0)
        .navigationTitle("Total Costs: \(formattedMonthlyTotal(currency: appSettings.currencyCode))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    calendarState.toggleViewType()
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
            await calendarState.loadCalendarDates(with: subscriptions)
        }
        .onAppear {
            if repository == nil {
                repository = SubscriptionRepository(modelContext: modelContext)
                calendarState.viewType = appSettings.defaultCalendarView
            }
        }
        .onChange(of: subscriptions) { _, _ in
            // Refresh calendar when subscriptions change
            Task {
                await calendarState.loadCalendarDates(with: subscriptions)
            }
        }
        // Synchronize header animations with month changes
        .onChange(of: calendarState.selectedMonth) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isTransitioning = true
            }
            
            // After a short delay, complete the transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTransitioning = false
                }
            }
        }
    }
    
    private var monthSelectorView: some View {
        HStack {
            Button{
                withAnimation(.easeInOut(duration: 0.3)) {
                    calendarState.goToPreviousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            
            Text(calendarState.selectedMonth.formatted(.dateTime.month().year()))
                .font(.title2.bold())
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    calendarState.goToNextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
            }
        }
    }
    
    private var weekdayHeaderView: some View {
        HStack {
            ForEach(Calendar.current.veryShortWeekdaySymbols) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var monthGridContainer: some View {
        GeometryReader { geometry in
            CalendarContainerView(selectedMonth: $calendarState.selectedMonth) { monthDate in
                monthView(for: monthDate, geometry: geometry)
                    .transition(.slide)
            }
            .animation(.easeInOut, value: calendarState.viewType)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func monthView(for monthDate: Date, geometry: GeometryProxy) -> some View {
        let monthDates = calendarState.getDatesForMonth(monthDate)
        
        return Group {
            if calendarState.viewType == .standard {
                StandardCalendarGrid(
                    selectedDate: $calendarState.selectedDate,
                    month: monthDate,
                    dates: monthDates,
                    onDateTap: calendarState.selectDate
                )
                .transition(.opacity) // Add a fade transition
                
            } else {
                CompactCalendarGrid(
                    selectedDate: $calendarState.selectedDate,
                    month: monthDate,
                    dates: monthDates,
                    onDateTap: calendarState.selectDate,
                )
                .transition(.opacity) // Add a fade transition
            }
        }
        .padding(.horizontal)
        .frame(height: geometry.size.height)
    }
    
    
    // MARK: - Calculation Methods
    
    private func formattedMonthlyTotal(currency: String) -> String {
        let total = calculateMonthlyTotal()
        let formatStyle: Decimal.FormatStyle.Currency = CurrencyInfo.hasDecimals(currency) ? .currency(code: currency) : .currency(code: currency).precision(.fractionLength(0))
        return Decimal(total).formatted(formatStyle)
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
}

#Preview {
    NavigationStack {
        NewCalendarView()
            .environmentObject(AppSettings())
            .environmentObject(ExchangeRateRepository())
    }
}
