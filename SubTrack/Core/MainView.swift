//
//  MainView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI
import SwiftData

enum CalendarViewType: String {
    case standard = "standard"
    case listBullet = "listBullet"
}

struct MainView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @EnvironmentObject private var appSettings: AppSettings
    @StateObject private var identityManager = IdentityManager()

    @State private var calendarViewType: CalendarViewType = .standard
    @State private var tabSelection = 0
    
    private func viewForTab(_ tab: TabItem) -> some View {
         NavigationStack {
             switch tab.title {
             case "Dashboard":
                 Dashboard()
             case "Calendar":
                 NewCalendarView()
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
                if identityManager.modelContext == nil {
                    identityManager.modelContext = modelContext
                    self.identityManager.createDeviceID()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openSubscriptionDetail)) { notification in
                if let subscriptionId = notification.userInfo?["subscriptionId"] as? String,
                   let uuid = UUID(uuidString: subscriptionId) {
                    // Navigate to subscription detail
                    // You'll need to implement navigation logic based on your app structure
                }
            }
        }
        .environmentObject(identityManager)
    }
}

#Preview {
    MainView()
        .environmentObject(AppSettings())
}
