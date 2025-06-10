//
//  CardBackground.swift
//  SubTrack
//
//  Created by Sam on 2025/5/23.
//
import SwiftUI

struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 5) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .shadow(
                        color: colorScheme == .dark ? .white.opacity(0.05) : .black.opacity(0.08),
                        radius: colorScheme == .dark ? shadowRadius * 0.6 : shadowRadius,
                        x: 0,
                        y: colorScheme == .dark ? 1 : 2
                    )
            )
    }
}
