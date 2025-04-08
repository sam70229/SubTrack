//
//  ColorCircleView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/1.
//
import SwiftUI


struct ColorCircleView: View {
    let color: Color
    let isSelected: Bool
    var isCustom: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 36, height: 36)
                    .shadow(radius: 2)
                
                if isCustom {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color.isDark ? .white : .black)
                }
                
                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color.isDark ? .white : .black)
                }
            }
        }
    }
}
