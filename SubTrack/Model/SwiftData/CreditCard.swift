//
//  CreditCard.swift
//  SubTrack
//
//  Created by Sam on 2025/4/12.
//
import SwiftUI
import SwiftData


@Model
class CreditCard {
    var id: UUID
    var name: String
    var last4Digits: String
    var colorHex: String
    
    @Relationship(deleteRule: .nullify, inverse: \Subscription.creditCard)
    var subscriptions: [Subscription]? = []
    
    init(id: UUID = UUID(), name: String, last4Digits: String, colorHex: String = "#ffffff") {
        self.id = id
        self.name = name
        self.last4Digits = last4Digits
        self.colorHex = colorHex
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .black
    }
    
    var maskedLast4Digits: String {
        String("**** **** **** \(last4Digits)")
    }
}
