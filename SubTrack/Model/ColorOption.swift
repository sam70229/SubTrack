//
//  ColorOption.swift
//  SubTrack
//
//  Created by Sam on 2025/4/1.
//
import SwiftUI


struct ColorOption: Identifiable {
    let id = UUID()
    let name: String
    let hex: String
    
    // If you need to access the color directly
    var color: Color {
        Color(hex: hex) ?? .blue
    }
}
