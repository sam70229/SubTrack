//
//  IconOption.swift
//  SubTrack
//
//  Created by Sam on 2025/4/2.
//
import SwiftUI


struct IconOption: Identifiable {
    let id = UUID()
    let name: String
    let image: String

    static let defaultIconOptions = [
        IconOption(name: "Music", image: "music.note"),
        IconOption(name: "Gaming", image: "gamecontroller"),
        IconOption(name: "Cloud", image: "cloud"),
        IconOption(name: "Car", image: "car"),
        IconOption(name: "Streaming", image: "film"),
        IconOption(name: "Book", image: "book.closed"),
        IconOption(name: "House", image: "house"),
        IconOption(name: "News", image: "newspaper"),
    ]
}
