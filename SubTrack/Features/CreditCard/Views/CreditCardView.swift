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
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.linearGradient(colors: card.colors.map({ color in Color(hex: color.hex)! }), startPoint: .topLeading, endPoint: .bottomTrailing))
            
            VStack {
                HStack {
                    Text(card.name)
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    Text("**** **** **** \(card.last4Digits)")
                    Spacer()
                }
            }
            .padding(20)
        }
        .foregroundStyle(card.colors.first?.name == "White" && card.colors.count == 1 ? .black : .white)
//        .environment(\.colorScheme, card.colors.count == 1 && card.colors[0].name == "White" ? .light : .dark)
    }
    
}

#Preview {
    let creditCard = CreditCard(name: "test Card", last4Digits: "3333")
    CreditCardView(card: creditCard)
}



struct ColorSchemeModifier: ViewModifier {
    let colorScheme: ColorScheme
    
    func body(content: Content) -> some View {
        content.environment(\.colorScheme, colorScheme)
    }
}
