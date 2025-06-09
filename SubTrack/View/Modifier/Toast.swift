//
//  Toast.swift
//  SubTrack
//
//  Created by Sam on 2025/6/8.
//
import SwiftUI

struct ToastState: Identifiable {
  let id = UUID()

  enum Status {
    case error
    case success
  }

  var status: Status
  var title: String
  var description: String?
}


struct ToastModifier: ViewModifier {
    let state: Binding<ToastState?>
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    if let state = state.wrappedValue {
                        ToastView(state: state)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state.wrappedValue?.id)
            )
            .onChange(of: state.wrappedValue?.id) { oldValue, newValue in
                if oldValue == newValue, newValue != nil {
                    scheduleAutoDismiss()
                }
            }
    }
    
    private func scheduleAutoDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            dismissToast()
        }
    }
    
    private func dismissToast() {
        withAnimation {
            state.wrappedValue = nil
        }
    }
}

private struct ToastView: View {
    let state: ToastState
    
    var body: some View {
        HStack(spacing: 12) {
            statusIcon
                .imageScale(.large)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                if let description = state.description {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .frame(maxWidth: 430)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch state.status {
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.red)
        }
    }
}
