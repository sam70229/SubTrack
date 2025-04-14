//
//  CreditCardPickerView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/12.
//
import SwiftUI
import SwiftData


struct CreditCardPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let onSelect: (CreditCard) -> Void
    
    @Query private var creditCards: [CreditCard]
    
    @State private var showAddCreditCardView: Bool = false
    
    var body: some View {
        List(creditCards) { creditCard in
            CreditCardView(card: creditCard)
                .onTapGesture {
                    onSelect(creditCard)
                }
        }
        .overlay {
            if creditCards.isEmpty {
                ContentUnavailableView(
                    label: {
                        Label("No Cards", systemImage: "creditcard.trianglebadge.exclamationmark")
                    }, description: {
                        Text("Click add to add a card")
                    }) {
                        Button{
                            showAddCreditCardView = true
                        } label: {
                            Text("Add")
                        }
                        .buttonStyle(.bordered)
                    }
            }
        }
        .sheet(isPresented: $showAddCreditCardView) {
            NavigationStack {
                AddCreditCardView()
            }
        }
    }
}
