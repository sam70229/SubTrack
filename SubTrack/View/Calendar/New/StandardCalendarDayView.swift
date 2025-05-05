//
//  StandardCalendarDayView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/25.
//
import SwiftUI


struct StandardCalendarDayView: View {
    @EnvironmentObject private var appSettings: AppSettings
    
    private let dayView: CalendarDayView
    
    init(calendarDate: CalendarDate, isSelected: Bool, isToday: Bool) {
        self.dayView = CalendarDayView(calendarDate: calendarDate, isSelected: isSelected, isToday: isToday)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            dayView.dateNumberView
                .font(.system(size: 20))
                .foregroundColor(dayView.calendarDate.isCurrentMonth ? .primary : .secondary.opacity(0.5))
                .frame(width: 36, height: 36)
                .background {
                    ZStack {
                        if dayView.isSelected {
                            Circle()
                                .fill(dayView.isToday ?
                                      Color(hex: appSettings.todayColorHex) ?? Color.red :
                                        Color(hex:appSettings.accentColorHex) ?? .accentColor)
                        } else {
                            if dayView.isToday {
                                Circle()
                                    .fill(Color(hex: appSettings.todayColorHex) ?? Color.red)
                            }
                        }
                    }
                }
            
            dayView.eventIndicators(maxCount: 3)
                .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
}
