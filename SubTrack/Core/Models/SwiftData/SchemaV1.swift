//
//  SchemaV3.swift
//  SubTrack
//
//  Created by Sam on 2025/5/8.
//
import Foundation
import SwiftUI
import SwiftData


enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Subscription.self, BillingRecord.self, CreditCard.self]
    }
}

extension SchemaV1{
    @Model
    final class Subscription {
        @Attribute(.unique) var id: UUID
        var name: String
        var subscriptionDescription: String?
        var price: Decimal
        var currencyCode: String // For supporting diff country
        var period: Period
        var firstBillingDate: Date
        var tags: [Tag]
        var icon: String
        var colorHex: String
        var isActive: Bool
        var createdAt: Date
        var creditCard: CreditCard?
        
        var nextBillingDate: Date {
            calculateNextBillingDate()
        }
        
        @Relationship(deleteRule: .cascade, inverse: \BillingRecord.subscription)
        var billingRecords: [BillingRecord] = []
        
        init(
            id: UUID = UUID(),
            name: String,
            subscriptionDescription: String? = nil,
            price: Decimal,
            currencyCode: String = Locale.current.currency?.identifier ?? "USD",
            period: Period,
            firstBillingDate: Date,
            tags: [Tag] = [],
            creditCard: CreditCard? = nil,
            icon: String,
            colorHex: String,
            isActive: Bool = true,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.subscriptionDescription = subscriptionDescription
            self.price = price
            self.currencyCode = currencyCode
            self.period = period
            self.firstBillingDate = firstBillingDate
            self.tags = tags
            self.creditCard = creditCard
            self.icon = icon
            self.colorHex = colorHex
            self.isActive = isActive
            self.createdAt = createdAt
        }
        
        var color: Color {
            Color(hex: colorHex) ?? .blue
        }
    }
    
    @Model
    final class CreditCard {
        @Attribute(.unique) var id: UUID
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
    
    @Model
    final class BillingRecord {
        @Attribute(.unique) var id: UUID
        var subscriptionId: UUID
        var billingDate: Date
        var amount: Decimal
        var currencyCode: String
        var isPaid: Bool = true
        
        @Relationship(deleteRule: .cascade, inverse: \Subscription.id)
        var subscription: Subscription?
        
        init(id: UUID = UUID(), subscriptionId: UUID, billingDate: Date, amount: Decimal, currencyCode: String, isPaid: Bool = true) {
            self.id = id
            self.subscriptionId = subscriptionId
            self.billingDate = billingDate
            self.amount = amount
            self.currencyCode = currencyCode
            self.isPaid = isPaid
        }
    }
    
    @Model
    class Category {
        @Attribute(.unique) var id: UUID
        var name: String
        var colorHex: String
        
        init(id: UUID = UUID(), name: String, colorHex: String) {
            self.id = id
            self.name = name
            self.colorHex = colorHex
        }
        
        var color: Color {
            Color(hex: colorHex) ?? .gray
        }
    }
}
