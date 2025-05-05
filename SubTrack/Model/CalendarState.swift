//
//  CalendarState.swift
//  SubTrack
//
//  Created by Sam on 2025/4/22.
//
import SwiftUI


class CalendarState: ObservableObject {
    enum ViewType: Equatable {
        case standard
        case compact
        
        var iconName: String {
            switch self {
            case .standard:
                return "list.bullet.circle"
            case .compact:
                return "list.bullet.below.rectangle"
            }
        }
    }

    @Published var selectedMonth: Date = Date()
    @Published var previousMonth: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var nextMonth: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    
    
    @Published var dates: [CalendarDate] = []
    @Published var selectedDate: CalendarDate?

    @Published var isLoading: Bool = false
    @Published var viewType: CalendarViewType = .standard
    @Published var errorMessage: String?
    
    private var dateCache: [String: [CalendarDate]] = [:]
    
    var subscriptions: [Subscription] = []
    
    // MARK: - Computed Properties
    
    var totalSubscriptionsThisMonth: Int {
        dates.filter { $0.isCurrentMonth }.flatMap { $0.subscriptions }.count
    }
    
    var uniqueSubscriptionsThisMonth: Int {
        let allSubscriptions = dates.filter { $0.isCurrentMonth }.flatMap { $0.subscriptions }
        let uniqueIds = Set(allSubscriptions.map { $0.id })
        return uniqueIds.count
    }
    
    func toggleViewType() {
        withAnimation(.easeInOut) {
            switch viewType {
            case .standard:
                viewType = .listBullet
            case .listBullet:
                viewType = .standard
            }
        }
    }
    
    func goToNextMonth() {
        let calendar = Calendar.current
        selectedMonth = calendar.startOfMonth(for: Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth)
    }
    
    func goToPreviousMonth() {
        let calendar = Calendar.current
        selectedMonth = calendar.startOfMonth(for: Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth)
    }
    
    func goToToday() {
        selectedMonth = Date()
        // State will be refreshed via task/onChange in the view
    }
    
    func selectDate(_ date: CalendarDate) {
        withAnimation {
            selectedDate = date
        }
    }
    
    // MARK: - Data Loading
    
    @MainActor
    func loadCalendarDates(with subscriptions: [Subscription]) async {
        isLoading = true
        defer { isLoading = false }

        // Generate dates using the separate generator
        let newDates = await CalendarDateGenerator.generateDates(
            for: selectedMonth,
            with: subscriptions
        )
        
        let previousDates = await CalendarDateGenerator.generateDates(
            for: previousMonth,
            with: subscriptions
        )
        
        let nextDates = await CalendarDateGenerator.generateDates(
            for: nextMonth,
            with: subscriptions
        )
        
        cacheMonth(selectedMonth, dates: newDates)
        cacheMonth(nextMonth, dates: nextDates)
        cacheMonth(previousMonth, dates: previousDates)
        
        dates = newDates
        
        // If no date is selected, try to select today or the first date of the month
        if selectedDate == nil {
            if let todayDate = CalendarDateGenerator.findTodayInDates(newDates) {
                selectedDate = todayDate
            } else if let firstDate = newDates.first(where: { $0.isCurrentMonth }) {
                selectedDate = firstDate
            }
        }
    }
    
    // Check if a month is already cached
    private func isCached(month: Date) -> Bool {
        let key = monthCacheKey(for: month)
        return dateCache[key] != nil
    }
    
    // Add a month to the cache
    private func cacheMonth(_ month: Date, dates: [CalendarDate]) {
        let key = monthCacheKey(for: month)
        dateCache[key] = dates
    }
    
    // Create a cache key from a date
    private func monthCacheKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
    
    // Get dates for any month - either from cache or generate new
    func getDatesForMonth(_ month: Date) -> [CalendarDate] {
        let key = monthCacheKey(for: month)
        
        // If we have this month cached, return it
        if let cachedDates = dateCache[key] {
            return cachedDates
        }
        
        // If this is the current month, return the main dates array
        if Calendar.current.isDate(month, equalTo: selectedMonth, toGranularity: .month) {
            return dates
        }
        
        // For months we don't have yet, return an empty array
        // The actual dates will be loaded asynchronously
        Task {
            if !isCached(month: month) {
                let newDates = await CalendarDateGenerator.generateDates(
                    for: month,
                    with: subscriptions
                )
                await MainActor.run {
                    cacheMonth(month, dates: newDates)
                    // Force a UI refresh if this is now the selected month
                    if Calendar.current.isDate(month, equalTo: selectedMonth, toGranularity: .month) {
                        self.dates = newDates
                    }
                }
            }
        }
        
        // Return empty array while loading
        return []
    }
}
