//
//  Vote.swift
//  SubTrack
//
//  Created by Sam on 2025/5/27.
//
import Foundation

struct Vote: Codable {
    let id: UUID
    let wishId: UUID
    let deviceId: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case wishId = "wish_id"
        case deviceId = "device_id"
        case createdAt = "created_at"
    }
}
