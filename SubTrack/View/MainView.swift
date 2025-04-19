//
//  MainView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI


enum CalendarViewType: String {
    case standard = "standard"
    case listBullet = "listBullet"
}

struct MainView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @State private var calendarViewType: CalendarViewType = .standard
    @State private var tabSelection = 0
    
    var body: some View {
        Group {
            TabView(selection: $tabSelection) {
                NavigationStack {
                    Group {
                        switch calendarViewType {
                        case .standard:
                            CalendarView()
                        case .listBullet:
                            ComboCalendarView()
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                withAnimation {
                                    calendarViewType = calendarViewType == .standard ? .listBullet : .standard
                                }
                            } label: {
                                Image(systemName: calendarViewType == .standard ? "list.bullet.below.rectangle" : "list.dash.header.rectangle")
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(0)
                
                NavigationStack {
                    SubscriptionListView()
                }
                .tabItem {
                    Label("Subscriptions", systemImage: "list.bullet")
                }
                .tag(1)
                
                NavigationStack {
                    AnalyticsView()
                }
                 .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
                .tag(2)
                
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
            }
            .tint(.blue)
            .onAppear {
                self.calendarViewType = appSettings.defaultCalendarView
                self.tabSelection = appSettings.defaultTab
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppSettings())
}
