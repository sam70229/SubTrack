//
//  CalendarViewModel.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//
import SwiftUI


class CalendarViewModel: ObservableObject {
    @EnvironmentObject var appSettings: AppSettings
    @Published var calendarDates: [CalendarDate] = []
    @Published var selectedDate: CalendarDate?
    @Published var selectedMonth: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let dataSource: SubscriptionDataSource
    
    init(dataSource: SubscriptionDataSource) {
        self.dataSource = dataSource
    }
    
    @MainActor
    func generateCalendarDates() {
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
                        do {
                            calendarDate.subscriptions = try dataSource.fetchSubscriptionsForDate(date)
                        } catch {
                            errorMessage = "Failed to load subscriptions: \(error.localizedDescription)"
                        }
                        newCalendarDates.append(calendarDate)
                    }
                }
            }
            
            // Add days from the current month
            for dayOffset in 0..<numberOfDays {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
                    var calendarDate = CalendarDate(date: date)
                    do {
                        calendarDate.subscriptions = try dataSource.fetchSubscriptionsForDate(date)
                    } catch {
                        errorMessage = "Failed to load subscriptions: \(error.localizedDescription)"
                    }
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
                        do {
                            calendarDate.subscriptions = try dataSource.fetchSubscriptionsForDate(date)
                        } catch {
                            errorMessage = "Failed to load subscriptions: \(error.localizedDescription)"
                        }
                        newCalendarDates.append(calendarDate)
                    }
                }
            }
            
            isLoading = false
            self.calendarDates = newCalendarDates
        }
    }
    
    enum CalculationMethod {
        case actualBilling   // Count subscriptions only when billed
        case amortized       // Distribute annual costs across months
    }

    func calculateMonthlyTotal(calculationMethod: CalculationMethod = .actualBilling) -> Double {
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
    
    func formattedMonthlyTotal(currency: String) -> String {
        let total = calculateMonthlyTotal()
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        
        // If you've implemented CurrencyManager from the previous conversation:
        // return CurrencyManager.shared.format(value: total)
        
//        return formatter.string(from: NSNumber(value: total)) ?? "$\(total)"
        return Decimal(total).formatted(.currency(code: currency))
    }
    
    /// Calculates the total cost for a specific month and year
    /// - Parameters:
    ///   - month: The month (1-12)
    ///   - year: The year
    /// - Returns: The total cost as a Double
    func calculateTotalForMonth(_ month: Int, year: Int) -> Double {
        // Save current state
        let previousSelectedMonth = selectedMonth
        
        // Set selected month to the requested month
        if let newDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) {
            selectedMonth = newDate
            // Generate calendar dates for the requested month
            Task {
                generateCalendarDates()
                // Once generated, calculate the total
                return calculateMonthlyTotal()
            }
        }
        
        // Restore previous state
        selectedMonth = previousSelectedMonth
        Task {
            generateCalendarDates()
        }
        
        return 0.0
    }
    
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
    
    // Helper functions
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    func isToday(date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
