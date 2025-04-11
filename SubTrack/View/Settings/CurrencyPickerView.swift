//
//  CurrencyPickerView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/11.
//
import SwiftUI


struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var searchText = ""
    @Binding var currencies: [CurrencyInfo]

    let onSelect: (CurrencyInfo) -> Void
    
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
                        onSelect(currency)
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
