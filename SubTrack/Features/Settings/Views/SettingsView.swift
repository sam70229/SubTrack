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
                
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Label("Notifications", systemImage: "bell.badge")
                }
                
                NavigationLink {
                    TagListView()
                } label: {
                    Label("Tags", systemImage: "number")
                }
            }
            
            hiddenTabsSection

            // Data management section
            dataManageSection
            
            // About section
            aboutSection
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
    
    private var hiddenTabsSection: some View {
        Section {
            ForEach(appSettings.enabledTabs.filter { !$0.isEnabled }) { tab in
                switch tab.title {
                case "Analytics":
                    NavigationLink {
                        AnalyticsView()
                    } label: {
                        Label(LocalizedStringKey(tab.title), systemImage: tab.icon)
                    }
                case "Wish Wall":
                    NavigationLink {
                        WishListView(viewModel: wishListViewModel)
                    } label: {
                        Label(LocalizedStringKey(tab.title), systemImage: tab.icon)
                    }
                default:
                    EmptyView()
                }
            }
        } header: {
            Text("Hidden Tabs")
        }
    }
    
    private var dataManageSection: some View {
        Section(header: Text("Data")) {
            
            NavigationLink {
                iCloudSettingsView()
            } label: {
                HStack {
                    
                    Label("", systemImage: "icloud")
                    
                    VStack(alignment: .leading) {
                        Text("iCloud Sync")
                        
                        if appSettings.iCloudSyncEnabled {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                
                                Text("Syncing with iCloud")
                                
                            }
                            .foregroundStyle(.green)
                            .font(.caption)
                        }
                    }

                    Spacer()

                    if appSettings.iCloudSyncEnabled {
                        Text("On")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Off")
                            .foregroundColor(.secondary)
                    }
                }
                
                
            }
            
            
            Button(role: .destructive) {
                // Show confirmation dialog
                showClearDataAlert = true
            } label: {
                Label("Clear All Local Data", systemImage: "trash")
            }
            
            // TODO: Support import/export, maybe the code is already in the ModelContainerManager.
//            NavigationLink {
//                Text("Import/Export")
//                    .navigationTitle("Import/Export")
//            } label: {
//                Label("Import/Export", systemImage: "square.and.arrow.up.on.square")
//            }
        }
        .alert(isPresented: $showClearDataAlert) {
            Alert(title: Text("Do u really wanna clear all data?"), primaryButton: .destructive(Text("Confirm"), action: {
                do {
                    try modelContext.delete(model: Subscription.self)
                    try modelContext.delete(model: BillingRecord.self)
                    try modelContext.delete(model: CreditCard.self)
                } catch {
                    showSystemAlert = true
                    errorMessage = "Failed to clear data: \(error)"
                }
            }), secondaryButton: .cancel())
        }
    }
    
    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("About SubTrack", systemImage: "info.circle")
            }
            
            // TODO: MAYBE NEEDED, BUT CAN WAIT
//            Link(destination: URL(string: "https://example.com/privacy")!) {
//                Label("Privacy Policy", systemImage: "hand.raised")
//            }
//
//            Link(destination: URL(string: "https://example.com/terms")!) {
//                Label("Terms of Service", systemImage: "doc.text")
//            }
        } header: {
            Text("About")
        } footer: {
            Text("Version \(Bundle.main.versionNumber), Build: \(Bundle.main.buildNumber)")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettings())
    }
}
