//
//  CompactCalendarGrid.swift
//  SubTrack
//
//  Created by Sam on 2025/4/26.
//
import SwiftUI


struct CompactCalendarGrid: View {
    @Binding var selectedDate: CalendarDate?
    
    let dates: [CalendarDate]
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(dates) { date in
                CalendarDayViewStyle.compact.makeView(
                    calendarDate: date,
                    isSelected: selectedDate?.id == date.id,
                    isToday: Calendar.current.isDateInToday(date.date)
                )
                .onTapGesture {
                    selectedDate = date
                }
            }
        }
    }
}
