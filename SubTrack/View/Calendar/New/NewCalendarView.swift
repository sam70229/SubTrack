//
//  NewCalendarView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/26.
//
import SwiftUI
import SwiftData


struct NewCalendarView: View {
    @StateObject private var calendarState = CalendarState()
    @Query private var subscriptions: [Subscription]
    
    // Local view state for gesture handling
    @GestureState private var dragOffset: CGFloat = 0
    @State private var activeOffset: CGFloat = 0
    @State private var previousMonth: Date = Date()
    @State private var nextMonth: Date = Date()
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                MonthGridView(
                    selectedDate: $calendarState.selectedDate,
                    month: previousMonth,
                    dates: [],
                    onDateTap: calendarState.selectDate
                )
                    .frame(width: geometry.size.width)
                
                MonthGridView(
                    selectedDate: $calendarState.selectedDate,
                    month: calendarState.selectedMonth,
                    dates: calendarState.dates,
                    onDateTap: calendarState.selectDate
                )
                    .frame(width: geometry.size.width)
                
                MonthGridView(
                    selectedDate: $calendarState.selectedDate,
                    month: nextMonth,
                    dates: [],
                    onDateTap: calendarState.selectDate
                )
                    .frame(width: geometry.size.width)
            }
            .offset(x: -geometry.size.width + activeOffset + dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = geometry.size.width / 3
                        
                        if value.translation.width > threshold {
                            // Swiped right - go to previous month
                            activeOffset = geometry.size.width
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                calendarState.selectedMonth = previousMonth
                                activeOffset = 0
                                
                                updateAdjacentMonths()
                            }
                        } else if value.translation.width < -threshold {
                               // Swiped left - go to next month
                               activeOffset = -geometry.size.width
                               
                               // After animation completes, update state
                               DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                   calendarState.selectedMonth = nextMonth
                                   activeOffset = 0
                                   // Update adjacent months
                                   updateAdjacentMonths()
                               }
                           } else {
                               // Not enough to change month, snap back
                               activeOffset = 0
                           }
                    }
            )
            .animation(.easeInOut(duration: 0.3), value: activeOffset)
            .onChange(of: calendarState.selectedMonth) { _, _ in
                updateAdjacentMonths()
            }
            .onAppear {
                updateAdjacentMonths()
                
                Task {
                    await calendarState.loadCalendarDates(with: subscriptions)
                }
            }
        }
    }

    private func updateAdjacentMonths() {
         let calendar = Calendar.current
         previousMonth = calendar.date(byAdding: .month, value: -1, to: calendarState.selectedMonth) ?? calendarState.selectedMonth
         nextMonth = calendar.date(byAdding: .month, value: 1, to: calendarState.selectedMonth) ?? calendarState.selectedMonth
     }
}

#Preview {
    NavigationStack {
        NewCalendarView()
    }
}
