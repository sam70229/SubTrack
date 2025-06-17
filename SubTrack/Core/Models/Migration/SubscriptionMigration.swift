//
//  SubscriptionMigration.swift
//  SubTrack
//
//  Created by Sam on 2025/5/6.
//
import Foundation
import SwiftUI
import SwiftData

typealias Subscription = SchemaV1.Subscription
typealias BillingRecord = SchemaV1.BillingRecord
typealias CreditCard = SchemaV1.CreditCard
typealias Tag = SchemaV1.Tag


struct MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
    
    //    static let migrateV1ToV2 = MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
}
