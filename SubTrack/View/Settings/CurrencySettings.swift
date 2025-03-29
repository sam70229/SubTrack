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
    @Binding var selectedCurrencyCode: String
    
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
                        self.selectedCurrencyCode = currency.code
                        appSettings.currencyCode = currency.code
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
                            
                            if currency.code == self.selectedCurrencyCode {
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
    @ObservedObject var currencyViewModel: CurrencyViewModel
    @State private var showingPicker = false
    var onSelect: () -> Void
    
    var body: some View {
        Section(header: Text("Currency")) {
            Toggle("Set Automatically", isOn: $appSettings.autoCurrencyCode)
                .onChange(of: appSettings.autoCurrencyCode) { oldValue, newValue in
                    if newValue {
                        let selectedCurrencyCode = Locale.current.currency!.identifier
                        currencyViewModel.selectedCurrencyCode = selectedCurrencyCode
                        appSettings.currencyCode = selectedCurrencyCode
                    }
                    appSettings.autoCurrencyCode = newValue
                }

            HStack {
                Text("Currency")
                
                Spacer()
                
                if let selectedCurrency = currencyViewModel.currencies.first(where: { $0.code == appSettings.currencyCode }) {
                    HStack(spacing: 4) {
                        Text(selectedCurrency.symbol)
                        Text(selectedCurrency.code)
                            .foregroundColor(appSettings.autoCurrencyCode ? .secondary : .primary)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !appSettings.autoCurrencyCode {
                    showingPicker = true
                    onSelect()
                }
            }
            .disabled(appSettings.autoCurrencyCode)
        }
        .onAppear {
            self.currencyViewModel.loadSelectedCurrencyCode(appSettings.currencyCode)
        }
    }
}
