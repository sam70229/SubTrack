//
//  CompactCalendarGrid.swift
//  SubTrack
//
//  Created by Sam on 2025/4/26.
//
import SwiftUI


struct CompactCalendarGrid: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedDate: CalendarDate?
    
    let month: Date
    let dates: [CalendarDate]
    let onDateTap: (CalendarDate) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        
        VStack {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(dates) { date in
                    CalendarDayViewStyle.compact.makeView(
                        calendarDate: date,
                        isSelected: selectedDate?.id == date.id,
                        isToday: Calendar.current.isDateInToday(date.date)
                    )
                    .onTapGesture {
                        onDateTap(date)
                    }
                }
            }
            .contentShape(Rectangle())
            .allowsHitTesting(true)
            
            Divider()
            
            if let selectedDate = selectedDate {
                selectedDateView(for: selectedDate)
                    .padding(.top)
            }
        }
    }
    
    private func selectedDateView(for date: CalendarDate) -> some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            Text(dateString(from: date.date))
                .font(.headline)

            if date.subscriptions.isEmpty {
                ScrollView {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.green)
                            
                            Text("No Subscriptions Needs To Be Paid Today")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 30)
                        
                        Spacer()
                    }
                }
                .defaultScrollAnchor(.center)
            } else {
                ScrollView(.vertical) {
                    VStack(spacing: 8) {
                        ForEach(date.subscriptions) { subscription in
                            SubscriptionListItemView(
                                subscription: subscription,
                                onSwipeToDelete: { subscription in
                                    modelContext.delete(subscription)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
