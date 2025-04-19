//
//  CalendarDayView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//
import SwiftUI


struct CalendarDayView: View {
    @EnvironmentObject private var appSettings: AppSettings
    
    let calendarDate: CalendarDate
    let isSelected: Bool
    let isToday: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            // Date Number
            Text("\(Calendar.current.component(.day, from: calendarDate.date))")
                .font(.system(size: 20))
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundColor(isSelected ? .white: calendarDate.isCurrentMonth ? .primary : .secondary.opacity(0.5))
                .frame(width: 36, height: 36)
                .background(
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(isToday ? Color.red : Color(hex:appSettings.accentColorHex) ?? .accentColor)
                        }
                    }
                )
            
            // MARK: - Show list inside calendarDayView
            VStack(spacing: 2) {
                ForEach(calendarDate.subscriptions.prefix(3)) { subscription in
                    Text(subscription.name)
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(subscription.color)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 14)
                        .background {
                            Color(subscription.color).opacity(0.3)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                
                if calendarDate.subscriptions.count > 3 {
                    Text("+\(calendarDate.subscriptions.count - 3)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        
    }
}

#Preview {
    let calendar = Calendar.current
    let currentMonth = calendar.component(.month, from: Date())
    let currentYear = calendar.component(.year, from: Date())
    
    // Get first day of the month
    let firstDayOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))
    let date = calendar.date(byAdding: .day, value: 0, to: firstDayOfMonth!)
    let calendarDate = CalendarDate(date: date!, isCurrentMonth: false)
    CalendarDayView(calendarDate: calendarDate, isSelected: false, isToday: true)
}
