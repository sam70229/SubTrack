//
//  CurrencyInfo.swift
//  SubTrack
//
//  Created by Sam on 2025/3/27.
//


struct CurrencyInfo: Identifiable, Hashable {
    let id: String // Currency code (e.g., "USD")
    let code: String // Same as id, for clarity
    let symbol: String // Currency symbol (e.g., "$")
    let name: String // Full name (e.g., "US Dollar")
    let exampleFormatted: String // Example of formatted value
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
