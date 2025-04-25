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
    
    private func viewForTab(_ tab: TabItem) -> some View {
         NavigationStack {
             switch tab.title {
             case "Calendar":
                 CalendarView()
             case "Subscriptions":
                 SubscriptionListView()
             case "Analytics":
                 AnalyticsView()
             case "Settings":
                 SettingsView()
             case "Wish Wall":
                 WishListView(viewModel: .init())
             default:
                 EmptyView()
             }
         }
     }
    
    var body: some View {
        Group {
            TabView(selection: $tabSelection) {
                ForEach(appSettings.enabledTabs.filter(\.isEnabled)) { tab in
                    Tab(LocalizedStringKey(tab.title), systemImage: tab.icon, value: tab.id) {
                        viewForTab(tab)
                    }
                }
            }
            .tint(Color(hex: appSettings.accentColorHex) ??  .blue)
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
