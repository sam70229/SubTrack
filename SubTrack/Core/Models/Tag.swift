//
//  Tag.swift
//  SubTrack
//
//  Created by Sam on 2025/5/7.
//
import SwiftUI


struct Tag: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
