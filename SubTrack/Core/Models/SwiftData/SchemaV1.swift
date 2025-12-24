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
        [UserIdentity.self, Subscription.self, BillingRecord.self, CreditCard.self, Tag.self]
    }
}

extension SchemaV1{
    @Model
    final class UserIdentity {
        var deviceId: String = UUID().uuidString
        
        init(deviceId: String) {
            self.deviceId = deviceId
        }
    }
    
    @Model
    final class Subscription {
        var id: UUID = UUID()
        var name: String = ""
        var subscriptionDescription: String?
        var price: Decimal = 0
        var currencyCode: String = "USD" // For supporting diff country

        // Sync to iCloud workaround
        private var rawPeriod: Int = Period.monthly.rawValue  // ✅ Fully qualified default value

        // Computed property to use `Period` enum in app logic
        var period: Period {
            get { Period(rawValue: rawPeriod) ?? .monthly }
            set { rawPeriod = newValue.rawValue }
        }

        var firstBillingDate: Date = Date()

        var tags: [Tag]? = []

        var icon: String = ""
        var colorHex: String = ""
        var isActive: Bool = true
        var createdAt: Date = Date()
        var creditCard: CreditCard?

        // Free Trial Tracking
        var trialEndDate: Date? = nil

        var nextBillingDate: Date {
            calculateNextBillingDate()
        }

        // MARK: - Free Trial Computed Properties

        /// Indicates if this subscription currently has an active free trial
        var isFreeTrial: Bool {
            guard let endDate = trialEndDate else { return false }
            return endDate > Date()
        }

        /// Indicates if the free trial has expired
        var isTrialExpired: Bool {
            guard let endDate = trialEndDate else { return false }
            return endDate <= Date()
        }

        /// Days remaining in free trial (nil if no trial or trial expired)
        var trialDaysRemaining: Int? {
            guard let endDate = trialEndDate, isFreeTrial else { return nil }
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: Date(), to: endDate)
            return components.day
        }
        
        @Relationship(deleteRule: .cascade, inverse: \BillingRecord.subscription)
        var billingRecords: [BillingRecord]?
        
        init(
            id: UUID = UUID(),
            name: String,
            subscriptionDescription: String? = nil,
            price: Decimal,
            currencyCode: String = Locale.current.currency?.identifier ?? "USD",
            period: Period,
            firstBillingDate: Date,
            tags: [Tag]? = nil,
            creditCard: CreditCard? = nil,
            icon: String,
            colorHex: String,
            isActive: Bool = true,
            createdAt: Date = Date(),
            trialEndDate: Date? = nil
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
            self.trialEndDate = trialEndDate
            self.billingRecords = []
        }
        
        var color: Color {
            Color(hex: colorHex) ?? .blue
        }
    }
    
    @Model
    final class CreditCard {
        var id: UUID = UUID()
        var name: String = ""
        var last4Digits: String = ""
        var colors: [ColorOption] = [
            ColorOption(name: "Black", hex: Color.black.toHexString()),
            ColorOption(name: "Gray", hex: Color.gray.toHexString())
        ]
        
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
        var id: UUID = UUID()
        var subscriptionId: UUID = UUID()
        var billingDate: Date = Date()
        var amount: Decimal = 0
        var currencyCode: String = "USD"
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
    final class Tag {
        var id: UUID = UUID()
        var name: String = ""
        
        @Relationship(inverse: \Subscription.tags)
        var subscriptions: [Subscription]? = []
        
        init(id: UUID = UUID(), name: String) {
            self.id = id
            self.name = name
        }
    }
}


// MARK: - Custom Transformers for CloudKit compatibility

@objc(ColorOptionArrayTransformer)
final class ColorOptionArrayTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let colors = value as? [ColorOption] else { return nil }
        return try? JSONEncoder().encode(colors)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode([ColorOption].self, from: data)
    }
}

// Register transformers
extension ColorOptionArrayTransformer {
    static func register() {
        ValueTransformer.setValueTransformer(
            ColorOptionArrayTransformer(),
            forName: NSValueTransformerName("ColorOptionArrayTransformer")
        )
    }
}
