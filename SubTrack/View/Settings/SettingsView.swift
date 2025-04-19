//
//  SettingsView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/20.
//
import SwiftUI
import SwiftData
import Foundation


struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @EnvironmentObject private var appSettings: AppSettings
    
    @StateObject private var wishListViewModel = WishViewModel()
    
    // State for currency settings
    @State private var currencies: [CurrencyInfo] = []
    
    @State private var showPicker: Bool = false
    @State private var showClearDataAlert: Bool = false
    
    // SYSTEM ALERT
    @State private var showSystemAlert: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    CurrencySettings(currencies: $currencies)
                } label: {
                    Label("Currency", systemImage: "dollarsign.circle")
                }
                
                // Appearance settings row
                NavigationLink {
                    AppearanceSettings()
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }

                NavigationLink {
                    CreditCardListView()
                } label: {
                    Label("Manage Credit Cards", systemImage: "creditcard")
                }
            }
            
            Section {
                NavigationLink {
                    WishListView(viewModel: wishListViewModel)
                } label: {
                    Label("Wish Wall", systemImage: "star.fill")
                }
            } header: {
                Text("Wish Wall")
            }

            // Data management section
            dataManageSection
            
            // About section
            Section(header: Text("About")) {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About SubTrack", systemImage: "info.circle")
                }
                
                // TODO: MAYBE NEEDED, BUT CAN WAIT
//                Link(destination: URL(string: "https://example.com/privacy")!) {
//                    Label("Privacy Policy", systemImage: "hand.raised")
//                }
//                
//                Link(destination: URL(string: "https://example.com/terms")!) {
//                    Label("Terms of Service", systemImage: "doc.text")
//                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            // Load currencies if not already loaded
            if currencies.isEmpty {
                currencies = CurrencyInfo.loadAvailableCurrencies()
            }
            wishListViewModel.setDeviceId(appSettings.deviceID)
        }
        .alert(isPresented: $showSystemAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage!), dismissButton: .default(Text("OK")))
        }
    }
    
    private var dataManageSection: some View {
        Section(header: Text("Data")) {
            Button(role: .destructive) {
                // Show confirmation dialog
                showClearDataAlert = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
            
            // TODO: Support import/export, but i dunno why we need this
//                NavigationLink {
//                    Text("Import/Export")
//                        .navigationTitle("Import/Export")
//                } label: {
//                    Label("Import/Export", systemImage: "square.and.arrow.up.on.square")
//                }
        }
        .alert(isPresented: $showClearDataAlert) {
            Alert(title: Text("Do u really wanna clear all data?"), primaryButton: .destructive(Text("Confirm"), action: {
                do {
                    try modelContext.delete(model: Subscription.self)
                    try modelContext.delete(model: Category.self)
                } catch {
                    showSystemAlert = true
                    errorMessage = "Failed to clear data: \(error)"
                }
            }), secondaryButton: .cancel())
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}
