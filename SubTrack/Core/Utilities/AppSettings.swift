//
//  AppSettings.swift
//  SubTrack
//
//  Created by Sam on 2025/3/20.
//
import SwiftUI
import ManagedSettings


enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
}

enum BillingInfoDisplay: String, CaseIterable {
    case period
    case nextBillingDate
    
    var description: String {
        switch self {
        case .period:
            return String(localized: "Period")
        case .nextBillingDate:
            return String(localized: "Next Billing Date")
        }
    }
}

enum PriceDisplayMode: String, CaseIterable {
    case original
    case converted
    
    var description: String {
        switch self {
        case .original:
            return String(localized: "Original Price")
        case .converted:
            return String(localized: "Converted Price")
        }
    }
}


class AppSettings: ObservableObject {
    // Device ID
    @AppStorage("device_id") var deviceID: String = UUID().uuidString

    @AppStorage("showDebugInfo") var showDebugInfo: Bool = false
    @AppStorage("billingInfoDisplay") var billingInfoDisplay: BillingInfoDisplay = .period
    
    @AppStorage("priceDisplayMode") var priceDisplayMode: PriceDisplayMode = .original
    
    // MARK: - Currency Settings
    @AppStorage("systemCurrencyCode") var systemCurrencyCode: String = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("userSelectedCurrencyCode") var userSelectedCurrencyCode: String = "USD"
    @AppStorage("autoSetCurrencyCode") var autoSetCurrencyCode: Bool = true
    
    var currencyCode: String {
        return autoSetCurrencyCode ? systemCurrencyCode : userSelectedCurrencyCode
    }
    
    func updateSystemCurrencyCode(_ code: String) {
        systemCurrencyCode = Locale.current.currency?.identifier ?? "USD"
    }
    
    func selectCurrency(_ code: String) {
        userSelectedCurrencyCode = code
    }
    
    func setAutoSetCurrencyCode(_ enabled: Bool) {
        autoSetCurrencyCode = enabled
    }
    
    // MARK: - Appearance Settings
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue {
        didSet {
            applyTheme()
        }
    }
    
    var appTheme: AppTheme {
        get {
            AppTheme(rawValue: appThemeRaw) ?? .system
        }
        set {
            appThemeRaw = newValue.rawValue
        }
    }
    
    var colorScheme: ColorScheme? {
        switch appTheme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil  // Let system decide
        }
    }
    
    @AppStorage("accentColorHex") var accentColorHex: String = Color.blue.toHexString() // Default iOS blue
    @AppStorage("todayColorHex") var todayColorHex: String = Color.red.toHexString()
    
    // MARK: - UIOptions
    @AppStorage("showCurrencySymbols") var showCurrencySymbols: Bool = true
    @AppStorage("showSubscriptionIcons") var showSubscriptionIcons: Bool = true
    @AppStorage("defaultTab") var defaultTab: Int = 0
    
    @AppStorage("defaultCalendarView") private var defaultCalendarViewRaw: String = CalendarViewType.standard.rawValue
    
    var defaultCalendarView: CalendarViewType {
        get {
            CalendarViewType(rawValue: defaultCalendarViewRaw) ?? .standard
        }
        set {
            defaultCalendarViewRaw = newValue.rawValue
        }
    }
    
//    @AppStorage("daysToShowUpcomingSubscriptions") var daysToShowUpcomingSubscriptions: Int = 7
    @AppStorage("daysToShowUpcomingSubscriptions") var daysToShowUpcomingSubscriptions: Int = 7
    
    // MARK: - Family Selection for Analytics
    @AppStorage("appSelection") var appSelection: Data = Data()
    
    
    // MARK: - TabItems
    @AppStorage("maxTabCount") var maxTabCount: Int = 4

    @AppStorage("enabledTabs") private var enabledTabsData: Data = try! JSONEncoder().encode(TabItem.defaultTabs)
    
    var enabledTabs: [TabItem] {
        get {
            (try? JSONDecoder().decode([TabItem].self, from: enabledTabsData)) ?? TabItem.defaultTabs
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                enabledTabsData = encoded
            }
        }
    }
    
    // MARK: - Tags
    @AppStorage("tagsData") private var tagsData: Data = Data()
    
    var tags: [Tag] {
        get {
            guard !tagsData.isEmpty else { return [] }
            return (try? JSONDecoder().decode([Tag].self, from: tagsData)) ?? []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                tagsData = encoded
            }
        }
    }
    
    // MARK: - iCloud Sync
    @AppStorage("iCloudSyncEnabled") var iCloudSyncEnabled: Bool = true {
        didSet {
            // Post notification when sync preference changes
            NotificationCenter.default.post(
                name: .iCloudSyncPreferenceChanged,
                object: nil
            )
        }
    }
    
    // MARK: - Tutorial Page
    @AppStorage("hasSeenWishTutorial") var hasSeenWishTutorial: Bool = false
    
    // MARK: - Initialization
    init() {
        // Apply theme on initialization
        applyTheme()
    }
    
    // Apply the selected theme
    private func applyTheme() {
        let theme = AppTheme(rawValue: appThemeRaw) ?? .system
        
        DispatchQueue.main.async {
            // Get the current UI style based on theme
            // let style = self.userInterfaceStyle(for: theme)
            
            if #available(iOS 15.0, *) {
                let scenes = UIApplication.shared.connectedScenes
                let windowScene = scenes.first as? UIWindowScene
                let window = windowScene?.windows.first
                
                window?.overrideUserInterfaceStyle = self.userInterfaceStyle(for: theme)
            } else {
                let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
                keyWindow?.overrideUserInterfaceStyle = self.userInterfaceStyle(for: theme)
            }
        }
    }

    // Helper method to convert AppTheme to UIUserInterfaceStyle
    private func userInterfaceStyle(for theme: AppTheme) -> UIUserInterfaceStyle {
        switch theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return .unspecified
        }
    }
}
