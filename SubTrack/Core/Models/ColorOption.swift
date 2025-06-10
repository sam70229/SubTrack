//
//  ColorOption.swift
//  SubTrack
//
//  Created by Sam on 2025/4/1.
//
import SwiftUI


struct ColorOption: Identifiable {
    var id = UUID()
    let name: String
    let hex: String
    
    // If you need to access the color directly
    var color: Color {
        Color(hex: hex) ?? .blue
    }
    
    static func generateColors() -> [ColorOption] {
        return [
            ColorOption(name: "Red", hex: Color.red.toHexString()),
            ColorOption(name: "Orange", hex: Color.orange.toHexString()),
            ColorOption(name: "Yellow", hex: Color.yellow.toHexString()),
            ColorOption(name: "Green", hex: Color.green.toHexString()),
            ColorOption(name: "Mint", hex: Color.mint.toHexString()),
            ColorOption(name: "Teal", hex: Color.teal.toHexString()),
            ColorOption(name: "Cyan", hex: Color.cyan.toHexString()),
            ColorOption(name: "Blue", hex: Color.blue.toHexString()),
            ColorOption(name: "Indigo", hex: Color.indigo.toHexString()),
            ColorOption(name: "Purple", hex: Color.purple.toHexString()),
            ColorOption(name: "Pink", hex: Color.pink.toHexString()),
            ColorOption(name: "Brown", hex: Color.brown.toHexString()),
            ColorOption(name: "Black", hex: Color.black.toHexString()),
            ColorOption(name: "Gray", hex: Color.gray.toHexString()),
            ColorOption(name: "White", hex: Color.white.toHexString())
        ]
    }
}

extension ColorOption: Hashable {

}

extension ColorOption: Codable {
    
}
