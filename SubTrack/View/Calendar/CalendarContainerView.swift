//
//  CalendarContainerView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/25.
//
import SwiftUI


private struct DragState: Equatable {
    var isDragging: Bool = false
    var translation: CGFloat = 0
}


struct CalendarContainerView<Content: View>: View {
    @Binding var selectedMonth: Date
    let content: (Date) -> Content
    
    @State private var dragState = DragState()
    @State private var pageOffset: Int = 0
    
    private let animationDuration: Double = 0.3
    private let swipeThresholdFactor: Double = 0.5
    
    var body: some View {
        GeometryReader { geometry in
            calendarPages(in: geometry)
            .offset(x: calculateOffset(for: geometry))
            .gesture(swipeGesture(for: geometry))
            .animation(.interactiveSpring(response: animationDuration), value: dragState.translation)
            .animation(.interactiveSpring(response: animationDuration), value: pageOffset)
//            .simultaneousGesture(
//                DragGesture()
//                    .updating($dragOffset) { value, state, _ in
//                        state = value.translation.width
//                    }
//                    .onEnded { value in
//                        let horizontalDragAmount = value.translation.width
//                        let threshold = geometry.size.width / 2
//    
//                        if abs(horizontalDragAmount) > threshold {
//                            // Determine direction
//                            let movingForward = horizontalDragAmount < 0
//                            
//                            // Prepare the transition
//                            withAnimation(.easeInOut(duration: 0.3)) {
//                                activeOffset = movingForward ? -geometry.size.width : geometry.size.width
//                            }
//                            
//                            // Update the calendar state after animation completes
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                                if movingForward {
//                                    calendarState.goToNextMonth()
//                                } else {
//                                    calendarState.goToPreviousMonth()
//                                }   
//                                // Reset offset without animation
//                                withTransaction(Transaction(animation: nil)) {
//                                    activeOffset = .zero
//                                }
//                            }
//                        } else {
//                            // Spring back to center if threshold not met
//                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                                activeOffset = 0
//                            }
//                        }
//                    }
//            )
//            .animation(.smooth, value: activeOffset)
//            .contentShape(Rectangle())
//            .onChange(of: calendarState.selectedMonth) { _, newMonth in
//                withAnimation(.none) {
//                    calendarState.previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: newMonth) ?? newMonth
//                    calendarState.nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: newMonth) ?? newMonth
//                }
//            }
        }
    }
    
    private func calendarPages(in geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            ForEach(displayedMonths, id: \.self) { month in
                content(month)
                    .frame(width: geometry.size.width)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var displayedMonths: [Date] {
        [previousMonth, selectedMonth, nextMonth]
    }
    
    private var previousMonth: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }
    
    private var nextMonth: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }
    
    // MARK: - Calculations
    
    private func calculateOffset(for geometry: GeometryProxy) -> CGFloat {
        let baseOffset = -geometry.size.width // Center on middle page
        let dragOffset = dragState.isDragging ? dragState.translation : 0
        let pageTransition = CGFloat(pageOffset) * geometry.size.width
        
        return baseOffset + dragOffset + pageTransition
    }
    
    // MARK: - Gestures
       
       private func swipeGesture(for geometry: GeometryProxy) -> some Gesture {
           DragGesture()
               .onChanged { value in
                   dragState = DragState(
                       isDragging: true,
                       translation: value.translation.width
                   )
               }
               .onEnded { value in
                   handleSwipeEnd(value: value, geometry: geometry)
               }
       }
       
       private func handleSwipeEnd(value: DragGesture.Value, geometry: GeometryProxy) {
           let threshold = geometry.size.width * swipeThresholdFactor
           let shouldChangePage = abs(value.translation.width) > threshold
           
           withAnimation(.interactiveSpring(response: animationDuration)) {
               if shouldChangePage {
                   let direction = value.translation.width > 0 ? -1 : 1
                   pageOffset = direction
                   
                   // Update the selected month after a slight delay
                   // This is cleaner than DispatchQueue
                   Task { @MainActor in
                       try? await Task.sleep(nanoseconds: UInt64(animationDuration * 1_000_000_000))
                       updateSelectedMonth(direction: direction)
                       pageOffset = 0
                   }
               }
               
               dragState = DragState()
           }
       }
       
       private func updateSelectedMonth(direction: Int) {
           if let newMonth = Calendar.current.date(byAdding: .month, value: direction, to: selectedMonth) {
               selectedMonth = newMonth
           }
       }
}
