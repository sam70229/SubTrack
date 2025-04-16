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
    var colors: [ColorOption]
    
    @Relationship(deleteRule: .nullify, inverse: \Subscription.creditCard)
    var subscriptions: [Subscription]? = []
    
    init(
        id: UUID = UUID(),
        name: String,
        last4Digits: String,
        colors: [ColorOption] = [
            ColorOption(name: "Black", hex: Color.black.toHexString()),
            ColorOption(name: "Gray", hex: Color.gray.toHexString())
        ]
    ) {
        self.id = id
        self.name = name
        self.last4Digits = last4Digits
        self.colors = colors
    }
    
    var maskedLast4Digits: String {
        String("**** **** **** \(last4Digits)")
    }
}
