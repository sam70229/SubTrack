//
//  color+extension.swift
//  SubTrack
//
//  Created by Sam on 2025/3/16.
//
import SwiftUI


extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
        
    }
    
    // Check if color is dark
    var isDark: Bool {
        guard let components = UIColor(self).cgColor.components else {
            return false
        }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.5
    }
    
    func toHexString() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let hexString = String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        return hexString
    }
}
