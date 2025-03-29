//
//  MainView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI


enum CalendarViewType {
    case standard
    case listBullet
}

struct MainView: View {
    @State private var viewType: CalendarViewType = .standard
    @State private var tabSelection = 0
    
    var body: some View {
        Group {
            TabView(selection: $tabSelection) {
                NavigationStack {
                    Group {
                        switch viewType {
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
                                    viewType = viewType == .standard ? .listBullet : .standard
                                }
                            } label: {
                                Image(systemName: viewType == .standard ? "list.bullet.below.rectangle" : "list.dash.header.rectangle")
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
                    Text("Analytics view coming soon")
                        .padding()
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
        }
    }
}

#Preview {
    MainView()
}
