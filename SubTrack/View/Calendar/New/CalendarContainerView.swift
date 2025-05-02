//
//  CalendarContainerView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/25.
//
import SwiftUI


struct CalendarContainerView<Content: View>: View {
    @Binding var currentMonth: Date
    @State private var offset: CGFloat = 0
    @State private var initialOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var isDragging = false
    
    let content: (Date) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                
                //Previous month
                content(previousMonth)
                    .frame(width: geometry.size.width)
                
                // Current month
                content(currentMonth)
                    .frame(width: geometry.size.width)
                
                // Next month
                content(nextMonth)
                    .frame(width: geometry.size.width)
            }
            .offset(x: -geometry.size.width + offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            initialOffset = offset
                            isDragging = true
                        }
                        offset = initialOffset + value.translation.width
                    }
                    .onEnded { value in
                        isDragging = false
                        let threshold = geometry.size.width / 3
                        
                        if offset < -threshold {
                            // Next month
                            withAnimation(.easeInOut(duration: 0.3)) {
                                offset = -geometry.size.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                currentMonth = nextMonth
                                offset = 0
                            }
                        } else if offset > threshold {
                            // Previous month
                            withAnimation(.easeInOut(duration: 0.3)) {
                                offset = geometry.size.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                currentMonth = previousMonth
                                offset = 0
                            }
                        } else {
                            // Return to current month
                            withAnimation(.easeInOut(duration: 0.3)) {
                                offset = 0
                            }
                        }
                    }
            )
            .onAppear {
                contentWidth = geometry.size.width
            }
        }
    }
    
    private var previousMonth: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private var nextMonth: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}
