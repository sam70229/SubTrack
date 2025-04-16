//
//  CreditCardPickerView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/12.
//
import SwiftUI
import SwiftData


struct CreditCardPickerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    let onSelect: (CreditCard) -> Void
    
    @Query private var creditCards: [CreditCard]
    
    @State private var showAddCreditCardView: Bool = false
    @State private var repository: CreditCardRepository?
    
    var body: some View {
        GeometryReader { geometry in
            List {
                ForEach(creditCards) { creditCard in
                    CreditCardListItem(
                        card: creditCard,
                        onTap: { card in
                            onSelect(card)
                            presentationMode.wrappedValue.dismiss()
                        },
                        onDelete: { card in
                            repository?.deleteCreditCard(card)
                        }
                    )
                }
            }
        }
        .toolbar {
            if !creditCards.isEmpty {
                ToolbarItem {
                    Button {
                        showAddCreditCardView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .overlay {
            if creditCards.isEmpty {
                ContentUnavailableView(
                    label: {
                        Label("No Cards", systemImage: "creditcard.trianglebadge.exclamationmark")
                    }, description: {
                        Text("Click button below to add a card")
                    }) {
                        Button{
                            showAddCreditCardView = true
                        } label: {
                            Label("Add Card", systemImage: "plus")
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
        .onAppear {
            repository = CreditCardRepository(modelContext: modelContext)
        }
    }
}
