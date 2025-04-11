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

enum SubscriptionDisplayStyle: String, CaseIterable {
    case billingCycle
    case nextBillingDate
    
    var description: String {
        switch self {
        case .billingCycle:
            return String(localized: "Billing Cycle")
        case .nextBillingDate:
            return String(localized: "Next Billing Date")
        }
    }
}


class AppSettings: ObservableObject {
    // Device ID
    @AppStorage("device_id") var deviceID: String = UUID().uuidString

    @AppStorage("showDebugInfo") var showDebugInfo: Bool = false
    @AppStorage("subscriptionDisplayStyle") var subscriptionDisplayStyle: SubscriptionDisplayStyle = .billingCycle
    
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
    
    @AppStorage("accentColorHex") var accentColorHex: String = "#007AFF" // Default iOS blue
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
    
    // MARK: - Family Selection for Analytics
    @AppStorage("appSelection") var appSelection: Data = Data()
    
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
