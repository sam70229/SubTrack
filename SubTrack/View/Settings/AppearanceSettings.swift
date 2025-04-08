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
    
    // Predefined accent colors
    private let accentColors: [ColorOption] = [
        ColorOption(name: "Blue", hex: Color.blue.toHexString()),
        ColorOption(name: "Purple", hex: Color.purple.toHexString()),
        ColorOption(name: "Pink", hex: Color.pink.toHexString()),
        ColorOption(name: "Red", hex: Color.red.toHexString()),
        ColorOption(name: "Orange", hex: Color.orange.toHexString()),
        ColorOption(name: "Yellow", hex: Color.yellow.toHexString()),
        ColorOption(name: "Green", hex: Color.green.toHexString()),
        ColorOption(name: "Mint", hex: Color.mint.toHexString()),
        ColorOption(name: "Teal", hex: Color.teal.toHexString()),
        ColorOption(name: "Cyan", hex: Color.cyan.toHexString()),
        ColorOption(name: "Indigo", hex: Color.indigo.toHexString())
    ]
    
    var body: some View {
        List {
            // App Theme Section
            themeSection
            
            // Accent Color Section
            accentColorSection
            
            // UI Options Section
            uiOptionsSection
            
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
            
            Picker("Default Tab", selection: $appSettings.defaultTab) {
                Text("Calendar").tag(0)
                Text("Subscriptions").tag(1)
                Text("Analytics").tag(2)
                Text("Settings").tag(3)
            }
            .pickerStyle(.navigationLink)
            

            Picker(selection: $appSettings.subscriptionDisplayStyle) {
                ForEach(SubscriptionDisplayStyle.allCases, id: \.self) { style in
                    Text(style.description).tag(style)
                }
            } label: {
                Text("Subscription Display Style")
            }
            .pickerStyle(.navigationLink)
        }
    }
    
    
    private var calendarOptionsSection: some View {
        Section(header: Text("Calendar View")) {
            Picker("Default Calendar View", selection: $appSettings.defaultCalendarView) {
                Text("Monthly").tag(CalendarViewType.standard)
                Text("List").tag(CalendarViewType.listBullet)
            }
            .pickerStyle(.navigationLink)
            
//            Toggle("Show Past Payments", isOn: $appSettings.showPastPayments)
            
//            Toggle("Highlight Today", isOn: $appSettings.highlightToday)
        }
    }
}

#Preview {
    AppearanceSettings()
        .environmentObject(AppSettings())
}
