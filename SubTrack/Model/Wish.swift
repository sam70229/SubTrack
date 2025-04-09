//
//  Wish.swift
//  SubTrack
//
//  Created by Sam on 2025/4/8.
//
import Foundation

struct Wish: Identifiable {
    var id: String
    var title: String
    var content: String?
    var createdAt: Date
    var voteCount: Int
}
