//
//  SettingsView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/20.
//
import SwiftUI
import Foundation


struct SettingsView: View {
    @EnvironmentObject private var appSettings: AppSettings
    
    // State for currency settings
    @State private var currencies: [CurrencyInfo] = []
    
    @State private var showPicker: Bool = false
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    CurrencySection(currencies: $currencies)
                } label: {
                    Label("Currency", systemImage: "dollarsign.circle")
                }
                
                // Appearance settings row
                NavigationLink {
                    AppearanceSettings()
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }
            }
            
            // Data management section
            Section(header: Text("Data")) {
                Button(role: .destructive) {
                    // Show confirmation dialog
                } label: {
                    Label("Clear All Data", systemImage: "trash")
                }
                
                NavigationLink {
                    Text("Import/Export")
                        .navigationTitle("Import/Export")
                } label: {
                    Label("Import/Export", systemImage: "square.and.arrow.up.on.square")
                }
            }
            
            // About section
            Section(header: Text("About")) {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About SubTrack", systemImage: "info.circle")
                }
                
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                Link(destination: URL(string: "https://example.com/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            // Load currencies if not already loaded
            if currencies.isEmpty {
                currencies = CurrencyInfo.loadAvailableCurrencies()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}
