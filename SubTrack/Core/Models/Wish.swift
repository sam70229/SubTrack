//
//  Wish.swift
//  SubTrack
//
//  Created by Sam on 2025/4/8.
//
import Foundation

enum WishStatus: String, Codable {
    case open
    case inDevelopment
    case completed
    case closed
    
    var description: String {
        switch self {
        case .open:
            return "Open"
        case .inDevelopment:
            return "In Development"
        case .completed:
            return "Completed"
        case .closed:
            return "Closed"
        }
    }
}


struct Wish: Identifiable, Codable {
    var id: UUID
    var title: String
    var content: String?
    var createdAt: Date
    var voteCount: Int
    var status: String
    
    var voted: Bool = false
    var createdBy: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case createdAt = "created_at"
        case createdBy = "created_by"
        case voteCount = "vote_count"
        case status
    }
}
