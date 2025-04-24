//
//  CalendarState.swift
//  SubTrack
//
//  Created by Sam on 2025/4/22.
//
import SwiftUI


@Observable
class CalendarState {
    var dates: [CalendarDate] = []
    var selectedDate: CalendarDate?
    var selectedMonth: Date = Date()
    var isLoading: Bool = false
    var viewType: CalendarViewType = .standard
    
    let calendar = Calendar.current
    
    func goToNextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    func goToPreviousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    func toggleViewType() {
        viewType = viewType == .standard ? .listBullet : .standard
    }
}
