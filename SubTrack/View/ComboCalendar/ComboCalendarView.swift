//
//  ComboCalendarView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/19.
//
import SwiftUI


struct ComboCalendarView: View {
    @StateObject private var viewModel: CalendarViewModel = CalendarViewModel(dataSource: .shared)
    @State private var showingAddSubscription = false
    
    private let weekdays = ["Sat", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    monthSelectorView
                    
                    weekdayHeaderView
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 300)
                    } else {
                        calendarGridView
                    }
                    
                    if let selectedDate = viewModel.selectedDate {
                        selectedDateView(for: selectedDate)
                            .padding(.top)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSubscription = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionView()
                .presentationDetents([.medium, .large])
        }
        .alert(
            Text("Error"),
            isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel){}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .task {
            viewModel.generateCalendarDates()
        }
    }
    
    private var monthSelectorView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.monthYearString(from: viewModel.selectedMonth))
                    .font(.title2.bold())
            }
            
            Spacer()
            
            HStack {
                Button {
                    viewModel.goToPreviousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                        .frame(width: 30, height: 30)
                }
                
                Button {
                    viewModel.goToNextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                        .frame(width: 30, height: 30)
                }
            }
        }
    }
    
    private var calendarHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.monthYearString(from: viewModel.selectedMonth))
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Subscription Calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.goToPreviousMonth()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    viewModel.goToNextMonth()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var weekdayHeaderView: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day.first!.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var calendarGridView: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(viewModel.calendarDates) { calendarDate in
                ComboCalendarDayView(
                    calendarDate: calendarDate,
                    isSelected: viewModel.selectedDate?.date == calendarDate.date,
                    isToday: viewModel.isToday(date: calendarDate.date)
                )
                .onTapGesture {
                    viewModel.selectDate(calendarDate)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func selectedDateView(for date: CalendarDate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.dateString(from: date.date))
                .font(.headline)
            
            if date.subscriptions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        
                        Text("No payments due")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(date.subscriptions) { subscription in
                        SubscriptionListItemView(subscription: subscription)
                    }
                }
            }
        }
    }
    
    // Format date for header
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    // Format date for selected date
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// Preview Provider
struct ComboCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        ComboCalendarView()
    }
}
