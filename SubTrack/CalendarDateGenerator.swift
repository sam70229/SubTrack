//
//  CalendarGenerator.swift
//  SubTrack
//
//  Created by Sam on 2025/4/26.
//
import Foundation


class CalendarGenerator {
    // Generate calendar dates for a specific month
    static func generateDates(
        for month: Date,
        with subscriptions: [Subscription]
    ) async -> [CalendarDate] {
        let calendar = Calendar.current
        var dates: [CalendarDate] = []
        
        // Get first day of the month
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let firstDayOfMonth = calendar.date(from: components),
              let numberOfDays = calendar.range(of: .day, in: .month, for: month)?.count else {
            return []
        }
        
        // Get the weekday of the first day (0 is Sunday, 1 is Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Add days from the previous month to fill the first week
        let previousMonthDays = firstWeekday - 1
        if previousMonthDays > 0 {
            for dayOffset in (1...previousMonthDays).reversed() {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: firstDayOfMonth) {
                    var calendarDate = CalendarDate(date: date, isCurrentMonth: false)
                    calendarDate.subscriptions = SubscriptionFilter.filterSubscriptions(subscriptions, for: date)
                    dates.append(calendarDate)
                }
            }
        }
        
        // Add days from the current month
        for dayOffset in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) {
                var calendarDate = CalendarDate(date: date)
                calendarDate.subscriptions = SubscriptionFilter.filterSubscriptions(subscriptions, for: date)
                dates.append(calendarDate)
            }
        }
        
        // Fill the remaining days from the next month to complete the last week
        let totalDays = previousMonthDays + numberOfDays
        let remainingDays = 7 - (totalDays % 7)
        if remainingDays < 7 {
            for dayOffset in 1...remainingDays {
                if let date = calendar.date(byAdding: .day, value: numberOfDays + dayOffset - 1, to: firstDayOfMonth) {
                    var calendarDate = CalendarDate(date: date, isCurrentMonth: false)
                    calendarDate.subscriptions = SubscriptionFilter.filterSubscriptions(subscriptions, for: date)
                    dates.append(calendarDate)
                }
            }
        }
        
        return dates
    }
    
    // Find today's date in the date array and return the CalendarDate
    static func findTodayInDates(_ dates: [CalendarDate]) -> CalendarDate? {
        return dates.first(where: { Calendar.current.isDateInToday($0.date) })
    }
}
