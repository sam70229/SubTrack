//
//  CompactCalendarDayView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/26.
//
import SwiftUI


struct CompactCalendarDayView: View {
    @EnvironmentObject private var appSettings: AppSettings
    
    private let dayView: CalendarDayView
    
    init(calendarDate: CalendarDate, isSelected: Bool, isToday: Bool) {
        self.dayView = CalendarDayView(calendarDate: calendarDate, isSelected: isSelected, isToday: isToday)
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // Date Number
            dayView.dateNumberView
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(dayView.calendarDate.isCurrentMonth ? .primary : .secondary.opacity(0.5))

            // Payment Indicators
            if !dayView.calendarDate.subscriptions.isEmpty {
                HStack(spacing: 3) {
                    ForEach(Array(dayView.calendarDate.subscriptions.prefix(3).enumerated()), id: \.element.id) { _, subscription in
                        Circle()
                            .fill(subscription.color)
                            .frame(width: 6, height: 6)
                    }
                    
                    if dayView.calendarDate.subscriptions.count > 3 {
                        Text("+\(dayView.calendarDate.subscriptions.count - 3)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(dayView.isSelected ? Color(hex: appSettings.accentColorHex)!.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(dayView.isSelected ? Color(hex: appSettings.accentColorHex)! : Color.clear, lineWidth: 1.5)
                )
        )
        .overlay(
            // Today's Date Indicator
            RoundedRectangle(cornerRadius: 10)
                .stroke(dayView.isToday ? Color(hex: appSettings.todayColorHex) ?? Color.red : Color.clear, lineWidth: 1.5)
        )
    }
}
