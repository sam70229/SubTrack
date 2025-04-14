//
//  CreditCardView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/12.
//
import SwiftUI


struct CreditCardView: View {
    var card: CreditCard

    var body: some View {
        VStack {
            Text(card.name)
            Spacer()
            Text("\(card.maskedLast4Digits)")
        }
        .background(card.color)
    }
}

#Preview {
    let creditCard = CreditCard(name: "test Card", last4Digits: "3333")
    CreditCardView(card: creditCard)
}
