//
//  View+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/5/23.
//
import SwiftUI

extension View {
    func cardBackground(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 5) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
    
    func toastView(state: Binding<ToastState?>) -> some View {
        modifier(ToastModifier(state: state))
    }
}
