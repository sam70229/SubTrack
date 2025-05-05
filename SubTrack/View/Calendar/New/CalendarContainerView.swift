//
//  CalendarContainerView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/25.
//
import SwiftUI


struct CalendarContainerView<Content: View>: View {
    @StateObject var calendarState: CalendarState
    
    @GestureState private var dragOffset: CGFloat = 0
    @State private var activeOffset: CGFloat = 0
    
    @State private var displayMonths: [Date] = []
    
    private let dragThreshold: CGFloat = 50
    
    let content: (Date) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                content(calendarState.previousMonth)
                    .frame(width: geometry.size.width)
                
                content(calendarState.selectedMonth)
                    .frame(width: geometry.size.width)
                
                content(calendarState.nextMonth)
                    .frame(width: geometry.size.width)
            }
            .offset(x: -geometry.size.width + dragOffset + activeOffset)
            .simultaneousGesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width    
                    }
                    .onEnded { value in
                        let horizontalDragAmount = value.translation.width
                        
                        if horizontalDragAmount > dragThreshold {
                            calendarState.goToPreviousMonth()
                        } else if horizontalDragAmount < -dragThreshold {
                            calendarState.goToNextMonth()
                        } else {
                            withAnimation {
                                activeOffset = 0
                            }
                        }
                    }
            )
            .animation(.easeInOut, value: activeOffset)
            .contentShape(Rectangle())
            .onChange(of: calendarState.selectedMonth) { _, newMonth in
                calendarState.previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: newMonth) ?? newMonth
                calendarState.nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: newMonth) ?? newMonth
            }
        }
    }
}
