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
    
    @GestureState private var dragTranslation: CGFloat = 0
    @State private var pageOffset: Int = 0
    @State private var isAnimating: Bool = false

    private let swipeThresholdFactor: Double = 0.5
    
    var body: some View {
        GeometryReader { geometry in
            calendarPages(in: geometry)
            .offset(x: calculateOffset(for: geometry) + dragTranslation)
            .gesture(swipeGesture(for: geometry))
        }
    }
    
    private func calendarPages(in geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            ForEach(displayedMonths, id: \.self) { month in
                content(month)
                    .frame(width: geometry.size.width)
                    .transition(.slide)
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
//        let dragOffset = dragState.isDragging ? dragState.translation : 0
        let pageTransition = CGFloat(pageOffset) * geometry.size.width
        
        return baseOffset + pageTransition
    }
    
    // MARK: - Gestures
       
       private func swipeGesture(for geometry: GeometryProxy) -> some Gesture {
           DragGesture()
               .updating($dragTranslation) { value, state, _ in
                   state = value.translation.width
               }
               .onEnded { value in
                   handleSwipeEnd(value: value, geometry: geometry)
               }
       }
       
       private func handleSwipeEnd(value: DragGesture.Value, geometry: GeometryProxy) {
           guard !isAnimating else { return }
           isAnimating = true
           let threshold = geometry.size.width * swipeThresholdFactor
           let shouldChangePage = abs(value.translation.width) > threshold
           
           withAnimation {
               if shouldChangePage {
                   let direction = value.translation.width > 0 ? -1 : 1
                   updateSelectedMonth(direction: direction)
               }
           }

//           dragState = DragState()
           pageOffset = 0

           DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
               isAnimating = false
           }
           
       }
       
       private func updateSelectedMonth(direction: Int) {
           if let newMonth = Calendar.current.date(byAdding: .month, value: direction, to: selectedMonth) {
               selectedMonth = newMonth
           }
       }
}
