//
//  CalendarView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//
import SwiftUI
import SwiftData


struct CalendarView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.modelContext) private var modelContext
    
    @State private var showAddSubscription = false
    
    // Use SwiftData's query capabilities
    @Query private var subscriptions: [Subscription]
    
    @State private var calendarDates: [CalendarDate] = []
    @State private var selectedDate: CalendarDate?
    @State private var selectedMonth: Date = Date()
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    // Repository
    @State private var repository: SubscriptionRepository?
    
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing:  0), count: 7)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                monthSelectorView
                    .padding(.horizontal)
                
                weekdayHeaderView
                
                if isLoading {
                    ProgressView()
                        .frame(height: 300)
                } else {
                    ScrollView {
                        calendarGridView
                    }
                }
            }
            .padding(.top, 10)
        }
        .navigationTitle("Total Costs: \(formattedMonthlyTotal(currency: appSettings.currencyCode))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSubscription = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSubscription) {
            NavigationStack {
                AddSubscriptionView()
            }
        }
        .alert(
            Text("Error"),
            isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel){}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .onAppear {
            repository = SubscriptionRepository(modelContext: modelContext)
            generateCalendarDates()
        }
        .onChange(of: subscriptions) { _, _ in
            // Refresh calendar when subscriptions change
            generateCalendarDates()
        }
    }
    
    private var monthSelectorView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(monthYearString(from: selectedMonth))
                    .font(.title2.bold())
            }
            
            Spacer()
            
            HStack {
                Button {
                    goToPreviousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                        .frame(width: 30, height: 30)
                }
                
                Button {
                    goToNextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                        .frame(width: 30, height: 30)
                }
            }
        }
    }
    
    private var calendarHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(monthYearString(from: selectedMonth))
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Subscription Calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 20) {
                Button(action: {
                    goToPreviousMonth()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    goToNextMonth()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var weekdayHeaderView: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day.first!.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var calendarGridView: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(calendarDates) { calendarDate in
                CalendarDayView(
                    calendarDate: calendarDate,
                    isSelected: selectedDate?.date == calendarDate.date,
                    isToday: isToday(date: calendarDate.date)
                )
                .onTapGesture {
                    selectDate(calendarDate)
                }
            }
        }
    }
    
    private func selectedDateView(for date: CalendarDate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateString(from: date.date))
                .font(.headline)
            
            if date.subscriptions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        
                        Text("No Subscriptions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(date.subscriptions) { subscription in
                        SubscriptionListItemView(subscription: subscription)
                    }
                }
            }
        }
    }
    
    // MARK: - Calender Generation
    
    private func generateCalendarDates() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            var newCalendarDates: [CalendarDate] = []
            
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: selectedMonth)
            let currentYear = calendar.component(.year, from: selectedMonth)
            
            // Get first day of the month
            guard let firstDayOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1)) else {
                errorMessage = "Could not determine the first day of the month"
                return
            }
            
            // Get the number of days in the month
            let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) ?? 1..<31
            let numberOfDays = range.count
            
            // Get the weekday of the first day (0 is Sunday, 1 is Monday, etc.)
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
            
            // Add days from the previous month to fill the first week
            let previousMonthDays = firstWeekday - 1
            if previousMonthDays > 0 {
                for dayOffset in (1...previousMonthDays).reversed() {
                    if let date = calendar.date(byAdding: .day, value: -dayOffset, to: firstDayOfMonth) {
                        var calendarDate = CalendarDate(date: date, isCurrentMonth: false)
                        calendarDate.subscriptions = repository?.fetchSubscriptionsForDate(date) ?? []
                        newCalendarDates.append(calendarDate)
                    }
                }
            }
            
            // Add days from the current month
            for dayOffset in 0..<numberOfDays {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
                    var calendarDate = CalendarDate(date: date)
                    calendarDate.subscriptions = repository?.fetchSubscriptionsForDate(date) ?? []
                    newCalendarDates.append(calendarDate)
                    
                    // Select today's date by default if it's in the current month
                    if calendar.isDateInToday(date) {
                        selectedDate = calendarDate
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
                        newCalendarDates.append(calendarDate)
                    }
                }
            }
            
            isLoading = false
            self.calendarDates = newCalendarDates
        }
    }
    
    // MARK: - Navigation Methods
    func selectDate(_ date: CalendarDate) {
        selectedDate = date
    }
    
    func goToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
            Task {
                generateCalendarDates()
            }
        }
    }
    
    func goToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
            Task {
                generateCalendarDates()
            }
        }
    }
    
    // MARK: - Calculation Methods
    
    enum CalculationMethod {
        case actualBilling   // Count subscriptions only when billed
        case amortized       // Distribute annual costs across months
    }
    
    private func calculateMonthlyTotal(calculationMethod: CalculationMethod = .actualBilling) -> Double {
        let currentMonthDates = calendarDates.filter { $0.isCurrentMonth }
        
        var processedSubscriptionIds = Set<String>()
        var totalCost: Double = 0.0
        
        for calendarDate in currentMonthDates {
            for subscription in calendarDate.subscriptions {
                if processedSubscriptionIds.contains(subscription.id.uuidString) {
                    continue
                }
                
                processedSubscriptionIds.insert(subscription.id.uuidString)
                switch calculationMethod {
                case .actualBilling:
                    totalCost += NSDecimalNumber(decimal: subscription.price).doubleValue
                case .amortized:
                    if subscription.billingCycle == .annually {
                        totalCost += NSDecimalNumber(decimal: subscription.price / 12).doubleValue
                    } else {
                        totalCost += NSDecimalNumber(decimal: subscription.price).doubleValue
                    }
                }
            }
        }
        
        return totalCost
    }
    
    private func formattedMonthlyTotal(currency: String) -> String {
        let total = calculateMonthlyTotal()
        return Decimal(total).formatted(.currency(code: currency))
    }
    
    // MARK: - Helper functions
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func isToday(date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

// Preview Provider
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(AppSettings())
    }
}
