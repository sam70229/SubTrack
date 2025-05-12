//
//  CalendarDayView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/25.
//
import SwiftUI


struct CalendarDayView: View {
    let calendarDate: CalendarDate
    let isSelected: Bool
    let isToday: Bool
    
    @EnvironmentObject private var appSettings: AppSettings
    
    var dateNumberView: some View {
        Text("\(Calendar.current.component(.day, from: calendarDate.date))")
    }
    
    private var dateNumberColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color(hex: appSettings.todayColorHex) ?? .red
        } else {
            return calendarDate.isCurrentMonth ? .primary : .secondary.opacity(0.5)
        }
    }
    
    // Shared logic for rendering event indicators
     func eventIndicators(maxCount: Int = 3) -> some View {
         VStack(spacing: 2) {
             ForEach(calendarDate.subscriptions.prefix(maxCount)) { subscription in
                 eventIndicator(for: subscription)
             }
             
             if calendarDate.subscriptions.count > maxCount {
                 Text("+\(calendarDate.subscriptions.count - maxCount)")
                     .font(.system(size: 9))
                     .foregroundColor(.secondary)
                     .frame(maxWidth: .infinity, alignment: .leading)
             }
             
             Spacer()
         }
     }
     
     // Generic event indicator (can be customized by subclasses)
     func eventIndicator(for subscription: Subscription) -> some View {
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
    
    var body: some View {
        EmptyView()
    }
}
