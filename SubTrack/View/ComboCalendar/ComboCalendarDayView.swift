//
//  ComboCalendarDayView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/19.
//
import SwiftUI


struct ComboCalendarDayView: View {
    let calendarDate: CalendarDate
    let isSelected: Bool
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            // Date Number
            Text("\(Calendar.current.component(.day, from: calendarDate.date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(calendarDate.isCurrentMonth ? .primary : .secondary.opacity(0.5))

            // Payment Indicators
            if !calendarDate.subscriptions.isEmpty {
                HStack(spacing: 3) {
                    ForEach(Array(calendarDate.subscriptions.prefix(3).enumerated()), id: \.element.id) { _, subscription in
                        Circle()
                            .fill(subscription.color)
                            .frame(width: 6, height: 6)
                    }
                    
                    if calendarDate.subscriptions.count > 3 {
                        Text("+\(calendarDate.subscriptions.count - 3)")
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
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
        )
        .overlay(
            // Today's Date Indicator
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }
}

