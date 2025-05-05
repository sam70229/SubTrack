//
//  StandardCalendarGrid.swift
//  SubTrack
//
//  Created by Sam on 2025/4/26.
//
import SwiftUI


struct StandardCalendarGrid: View {
    @Binding var selectedDate: CalendarDate?
    
    let month: Date
    let dates: [CalendarDate]
    let onDateTap: (CalendarDate) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    private var weeks: [[CalendarDate]] {
        dates.chunked(into: 7)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(weeks, id: \.self) { week in
                WeekRow(week: week, selectedDate: $selectedDate, onDateTap: onDateTap)
                Divider() // Divider after each week
            }
        }
        
        .contentShape(Rectangle())
        .allowsHitTesting(true)
    }
}

struct WeekRow: View {
    let week: [CalendarDate]
    @Binding var selectedDate: CalendarDate?
    let onDateTap: (CalendarDate) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(week) { date in
                    CalendarDayViewStyle.basic.makeView(
                        calendarDate: date,
                        isSelected: selectedDate?.id == date.id,
                        isToday: Calendar.current.isDateInToday(date.date)
                    )
                    .aspectRatio(1, contentMode: .fit) // Keep cells square
                    .onTapGesture { onDateTap(date) }
                    .frame(width: geometry.size.width / 7) // Equal width distribution
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
