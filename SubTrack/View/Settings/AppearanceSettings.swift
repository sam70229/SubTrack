//
//  AppearanceSettings.swift
//  SubTrack
//
//  Created by Sam on 2025/4/1.
//
import SwiftUI


struct AppearanceSettings: View {
    @EnvironmentObject private var appSettings: AppSettings
    
    // Local state for UI
    @State private var showColorPicker = false
    @State private var selectedAccentColor: Color = .blue
    
    // Tabs
    @State private var tabs: [TabItem]
    
    // Predefined accent colors
    private let accentColors: [ColorOption] = ColorOption.generateColors()
    
    init() {
        _tabs = State(initialValue: TabItem.defaultTabs)
    }
    
    var body: some View {
        List {
            // App Theme Section
            themeSection
            
            // TODO: Add this if it needed
            // Accent Color Section
            accentColorSection
            
            // UI Options Section
            uiOptionsSection
            
            tabOptionsSection
            
            subscriptionDisplayOptionsSection
            
            // Calendar View Options
            calendarOptionsSection
        }
        .navigationTitle("Appearance")
        .onAppear {
            selectedAccentColor = Color(hex: appSettings.accentColorHex) ?? .blue
        }
    }
    
    private var themeSection: some View {
        Section(header: Text("Theme")) {
            Picker("App Theme", selection: $appSettings.appTheme) {
                Text("System").tag(AppTheme.system)
                Text("Light").tag(AppTheme.light)
                Text("Dark").tag(AppTheme.dark)
            }
            .pickerStyle(.navigationLink)
        }
    }
    
    private var accentColorSection: some View {
        Section(header: Text("Accent Color")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(accentColors) { colorOption in
                        ColorCircleView(
                            color: colorOption.color,
                            isSelected: appSettings.accentColorHex == colorOption.color.toHexString(),
                            action: {
                                appSettings.accentColorHex = colorOption.color.toHexString()
                                selectedAccentColor = colorOption.color
                            }
                        )
                    }
                    
                    // Custom color option
                    ColorCircleView(
                        color: Color(hex: appSettings.accentColorHex) ?? .blue,
                        isSelected: !accentColors.contains(where: { $0.color.toHexString() == appSettings.accentColorHex }),
                        isCustom: true,
                        action: {
                            showColorPicker = true
                        }
                    )
                }
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            if showColorPicker {
                ColorPicker("Custom Color", selection: $selectedAccentColor)
                    .onChange(of: selectedAccentColor) { _, newValue in
                        appSettings.accentColorHex = newValue.toHexString()
                    }
            }
        }
    }
    
    private var uiOptionsSection: some View {
        Section(header: Text("UI Options")) {
            Toggle("Show Currency Symbols", isOn: $appSettings.showCurrencySymbols)
            
            Toggle("Show Subscription Icons", isOn: $appSettings.showSubscriptionIcons)
        }
    }
    
    private var tabOptionsSection: some View {
        Section {
            Picker("Default Tab", selection: $appSettings.defaultTab) {
                Text("Calendar").tag(0)
                Text("Subscriptions").tag(1)
                Text("Analytics").tag(2)
                Text("Settings").tag(3)
            }
            .pickerStyle(.navigationLink)
            
            Picker("Max Tabs", selection: Binding(
                get: { appSettings.maxTabCount },
                set: { newValue in
                    let oldValue = appSettings.maxTabCount
                    appSettings.maxTabCount = newValue
                    if newValue < oldValue {
                        var enabledTabs = tabs.filter(\.isEnabled)
                        while enabledTabs.count > newValue - 1 {
                            if let lastTab = enabledTabs.last {
                                if lastTab.title != "Settings" {
                                    if let tabIndex = tabs.firstIndex(where: { $0.id == lastTab.id }) {
                                        tabs[tabIndex].isEnabled = false
                                        enabledTabs.removeLast()
                                    }
                                } else {
                                    enabledTabs.removeLast()
                                }
                            }
                        }
                        appSettings.enabledTabs = tabs
                    }
                })
            ) {
                Text("3 Tabs").tag(3)
                Text("4 Tabs").tag(4)
                Text("5 Tabs").tag(5)
            }

            .tint(.secondary)
            
            NavigationLink {
                List {
                    ForEach($tabs) { $tab in
                        HStack {
                            Image(systemName: tab.icon)
                            Text(tab.title)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { tab.isEnabled },
                                set: { newValue in
                                    let enabledCount = tabs.filter(\.isEnabled).count
                                    if newValue && enabledCount >= appSettings.maxTabCount {
                                        return
                                    }
                                    if !newValue && enabledCount <= 1 {
                                        return
                                    }
                                    tab.isEnabled = newValue
                                    appSettings.enabledTabs = tabs
                                }
                            ))
                        }
                        .disabled(tab.title == "Settings")
                    }
                }
                .navigationTitle("Manage Tabs")
            } label: {
                HStack {
                    Text("Manage Tabs")
                    Spacer()
                    Text("\(tabs.filter(\.isEnabled).count) enabled")
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("You can access disabled tabs from settings menu")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Tabs")
        }
    }
    
    private var subscriptionDisplayOptionsSection: some View {
        Section {
            Group {
                Text("Subscription Display Style")
                    .listRowSeparator(.hidden)

                Picker(selection: $appSettings.billingInfoDisplay) {
                    ForEach(BillingInfoDisplay.allCases, id: \.self) { style in
                        Text(style.description).tag(style)
                    }
                } label: {
                    Text("Subscription Display Style")
                }
                .pickerStyle(SegmentedPickerStyle())
                
            }
            
            Group {
                Text("Price Display")
                    
                Picker(selection: $appSettings.priceDisplayMode) {
                    ForEach(PriceDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.description).tag(mode)
                    }
                } label: {
                    Text("Price Display")
                }
                .pickerStyle(SegmentedPickerStyle())
                .listRowSeparator(.hidden)
            }
        } header: {
            Text("Subscription Display")
        }
    }
    
    
    private var calendarOptionsSection: some View {
        Section {
            Picker("Default Calendar View", selection: $appSettings.defaultCalendarView) {
                Text("Monthly").tag(CalendarViewType.standard)
                Text("List").tag(CalendarViewType.listBullet)
            }
            .pickerStyle(.navigationLink)
            
//            Toggle("Highlight Today", isOn: $appSettings.highlightToday)

        } header: {
            Text("Calendar")
        } footer: {
            Text("This will only affect on app launch.")
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettings()
            .environmentObject(AppSettings())
    }
}
