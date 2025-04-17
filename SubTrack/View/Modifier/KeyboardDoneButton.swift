//
//  KeyboardDoneButton.swift
//  SubTrack
//
//  Created by Sam on 2025/4/17.
//
import SwiftUI


struct KeyboardDoneButton: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

extension View {
    func keyboardDoneButton() -> some View {
        modifier(KeyboardDoneButton())
    }
}
