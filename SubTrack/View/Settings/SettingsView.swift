//
//  SettingsView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/20.
//
import SwiftUI
import Foundation


enum SettingsDestination: Identifiable {
    case currencyPicker
    
    var id: String {
        switch self {
        case .currencyPicker: return "currencyPicker"
        }
    }
}

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel = .init()
    @State private var showPicker: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                CurrencySection(
                    currencyViewModel: viewModel.currencyViewModel,
                    onSelect: {
                        viewModel.NavigateToDestination(.currencyPicker)
                    }
                )
            }
        }
        .navigationTitle("Settings")
        .navigationDestination(isPresented: $viewModel.showDestination) {
            destinationView(for: viewModel.activeDestination)
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: SettingsDestination?) -> some View {
        switch destination {
        case .currencyPicker:
            CurrencyPickerView(
                currencies: $viewModel.currencyViewModel.currencies,
                selectedCurrencyCode: $viewModel.currencyViewModel.selectedCurrencyCode
            )
        case nil:
            EmptyView()
        }
    }
}


#Preview {
    SettingsView()
}
