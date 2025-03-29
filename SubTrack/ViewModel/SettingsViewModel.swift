//
//  SettingsViewModel.swift
//  SubTrack
//
//  Created by Sam on 2025/3/27.
//
import SwiftUI


class SettingsViewModel: ObservableObject {
    @Published var activeDestination: SettingsDestination?
    @Published var showDestination: Bool = false
    
    // embedded other viewModel
    @Published var currencyViewModel: CurrencyViewModel = .init()
    
    func NavigateToDestination(_ destination: SettingsDestination) {
        self.activeDestination = destination
        self.showDestination.toggle()
        print(self.showDestination)
    }
}
