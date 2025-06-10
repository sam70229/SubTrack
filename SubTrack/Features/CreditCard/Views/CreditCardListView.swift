//
//  CreditCardListView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/15.
//
import SwiftUI
import SwiftData


struct CreditCardListView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    @Query private var creditCards: [CreditCard]
    
    var onSelect: ((CreditCard) -> Void)?
    
    @State private var showAddCreditCardView: Bool = false
    @State private var repository: CreditCardRepository?
    
    var body: some View {
        GeometryReader { geometry in
            List {
                ForEach(creditCards) { creditCard in
                    CreditCardListItem(
                        card: creditCard) { card in
                            onSelect!(card)
                            presentationMode.wrappedValue.dismiss()
                        } onDelete: { card in
                            // Handle delete
                            repository?.deleteCreditCard(creditCard)
                        }
                        .frame(height: 200)
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
    }
}
