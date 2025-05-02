//
//  CalendarDayViewStyle.swift
//  SubTrack
//
//  Created by Sam on 2025/4/26.
//
import SwiftUI


enum CalendarDayViewStyle {
    case basic
    case compact
    
    func makeView(calendarDate: CalendarDate, isSelected: Bool, isToday: Bool) -> some View {
        switch self {
        case .basic:
            return AnyView(BasicCalendarDayView(calendarDate: calendarDate, isSelected: isSelected, isToday: isToday))
        case .compact:
            return AnyView(ComboCalendarDayView(calendarDate: calendarDate, isSelected: isSelected, isToday: isToday))
        }
    }
}
