//
//  Category.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//
import SwiftData
import SwiftUI


@Model
class Category {
    var id: UUID
    var name: String
    var colorHex: String
    
    @Relationship(deleteRule: .nullify,  inverse: \Subscription.category)
    var subscriptions: [Subscription]? = []
    
    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}
