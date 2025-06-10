//
//  CreditCardListItem.swift
//  SubTrack
//
//  Created by Sam on 2025/4/14.
//
import SwiftUI


struct CreditCardListItem: View {
    let card: CreditCard
    var onTap: ((CreditCard) -> Void)? = nil
    let onDelete: (CreditCard) -> Void
    
    var body: some View {
        CreditCardView(card: card)
            .onTapGesture {
                if onTap != nil {
                    onTap!(card)
                }
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    onDelete(card)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
            }
            .listRowBackground(Color.clear)
    }
} 
