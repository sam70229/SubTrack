//
//  Wish.swift
//  SubTrack
//
//  Created by Sam on 2025/4/8.
//
import Foundation

struct Wish: Identifiable, Codable {
    var id: UUID
    var title: String
    var content: String?
    var createdAt: Date
    var voteCount: Int
    
    var voted: Bool = false
    var createdBy: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case createdAt = "created_at"
        case createdBy = "created_by"
        case voteCount = "vote_count"
    }
}
