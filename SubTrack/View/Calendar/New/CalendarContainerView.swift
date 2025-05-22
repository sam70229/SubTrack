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
    
    private let dragThreshold: CGFloat = 1000
    
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
                        let threshold = geometry.size.width / 2
    
                        if abs(horizontalDragAmount) > threshold {
                            // Determine direction
                            let movingForward = horizontalDragAmount < 0
                            
                            // Prepare the transition
                            withAnimation(.easeInOut(duration: 0.3)) {
                                activeOffset = movingForward ? -geometry.size.width : geometry.size.width
                            }
                            
                            // Update the calendar state after animation completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if movingForward {
                                    calendarState.goToNextMonth()
                                } else {
                                    calendarState.goToPreviousMonth()
                                }   
                                // Reset offset without animation
                                withTransaction(Transaction(animation: nil)) {
                                    activeOffset = .zero
                                }
                            }
                        } else {
                            // Spring back to center if threshold not met
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                activeOffset = 0
                            }
                        }
                    }
            )
            .animation(.smooth, value: activeOffset)
            .contentShape(Rectangle())
            .onChange(of: calendarState.selectedMonth) { _, newMonth in
                withAnimation(.none) {
                    calendarState.previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: newMonth) ?? newMonth
                    calendarState.nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: newMonth) ?? newMonth
                }
            }
        }
    }
}
