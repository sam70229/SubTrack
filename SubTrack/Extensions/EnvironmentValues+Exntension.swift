//
//  EnvironmentValues+Exntension.swift
//  SubTrack
//
//  Created by Sam on 2025/5/23.
//
import SwiftUI

private struct CurrencyCodeKey: EnvironmentKey {
    static let defaultValue = "USD"
}

extension EnvironmentValues {
    var currencyCode: String {
        get { self[CurrencyCodeKey.self] }
        set { self[CurrencyCodeKey.self] = newValue }
    }
}
