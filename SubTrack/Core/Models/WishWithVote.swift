//
//  WishWithVote.swift
//  SubTrack
//
//  Created by Sam on 2025/5/27.
//
import Foundation


struct WishWithVote: Codable {
    let id: UUID
    let title: String
    let content: String?
    let createdAt: Date
    let createdBy: String
    let voteCount: Int
    let voted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case createdAt = "created_at"
        case createdBy = "created_by"
        case voteCount = "vote_count"
        case voted
    }
}
