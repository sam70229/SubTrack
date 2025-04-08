//
//  CurrencySettings.swift
//  SubTrack
//
//  Created by Sam on 2025/3/27.
//
import SwiftUI


struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var searchText = ""
    @Binding var currencies: [CurrencyInfo]
    
    var filteredCurrencies: [CurrencyInfo] {
        if searchText.isEmpty {
            return currencies
        } else {
            return currencies.filter { currency in
                currency.name.localizedCaseInsensitiveContains(searchText) ||
                currency.code.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCurrencies) { currency in
                    Button(action: {
                        appSettings.selectCurrnecy(currency.code)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(currency.name)
                                    .font(.body)
                                Text(currency.code)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(currency.exampleFormatted)
                                .foregroundColor(.secondary)
                            
                            if currency.code == appSettings.userSelectedCurrencyCode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search currencies")
        }
    }
}


struct CurrencySection: View {
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
            .disabled(appSettings.autoSetCurrencyCode)
        }
        .navigationDestination(isPresented: $showPickerView) {
            CurrencyPickerView(currencies: $currencies)
        }
    }
}
