//
//  AppSettings.swift
//  SubTrack
//
//  Created by Sam on 2025/3/20.
//
import SwiftUI


class AppSettings: ObservableObject {
    @AppStorage("showDebugInfo") var showDebugInfo: Bool = false
    @AppStorage("currencyCode") var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("AutoSetCurrencyCode") var autoCurrencyCode: Bool = true
    
    @AppStorage("SubscriptionInfoType") var subscriptionInfoType: SubscriptionInfoStyle = .billingCycle
}
