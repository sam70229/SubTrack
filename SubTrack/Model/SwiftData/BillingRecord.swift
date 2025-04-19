//
//  BillingRecord.swift
//  SubTrack
//
//  Created by Sam on 2025/4/11.
//
import Foundation
import SwiftData


@Model
class BillingRecord {
    var id: UUID
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
