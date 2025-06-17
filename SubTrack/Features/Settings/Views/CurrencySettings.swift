//
//  CurrencySettings.swift
//  SubTrack
//
//  Created by Sam on 2025/3/27.
//
import SwiftUI


struct CurrencySettings: View {
    @EnvironmentObject var appSettings: AppSettings
    
    @Binding var currencies: [CurrencyInfo]
    
    @State private var showPickerView: Bool = false
    
    var body: some View {
        List {
            Toggle("Set Automatically", isOn: $appSettings.autoSetCurrencyCode)
                .onChange(of: appSettings.autoSetCurrencyCode) { _, _ in
                    if appSettings.autoSetCurrencyCode {
                        appSettings.updateSystemCurrencyCode(Locale.current.currency?.identifier ?? "USD")
                    }
                }
            Button {
                if !appSettings.autoSetCurrencyCode {
                    showPickerView.toggle()
                }
            } label: {
                HStack {
                    Text("Currency")
                    
                    Spacer()
                    
                    if let selectedCurrency = currencies.first(where: { $0.code == appSettings.currencyCode }) {
                        HStack(spacing: 4) {
                            Text(selectedCurrency.symbol)
                            Text(selectedCurrency.code)
                                .foregroundColor(appSettings.autoSetCurrencyCode ? .secondary : .primary)
                        }
                    }
                    
                    if !appSettings.autoSetCurrencyCode {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(appSettings.autoSetCurrencyCode)
        }
        .navigationDestination(isPresented: $showPickerView) {
            CurrencyPickerView(currencies: $currencies, onSelect: { currency in
                appSettings.selectCurrency(currency.code)
            })
        }
    }
}
