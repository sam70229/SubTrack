//
//  SubscriptionShortItemView.swift
//  SubTrack
//
//  Created by Sam on 2025/5/13.
//
import SwiftUI
import SwiftData


struct SubscriptionShortItemView: View {
    @EnvironmentObject private var appSettings: AppSettings
    
    var subscription: Subscription
    
    var body: some View {
        HStack {
            if appSettings.showSubscriptionIcons {
                Image(systemName: subscription.icon)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(4)
            }
            
            VStack(alignment: .leading) {
                Text(subscription.name)
                Text(subscription.period.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack {
//                Spacer()
                Text("\(getDaysBetween(startDate: Date(),endDate: subscription.nextBillingDate))")
                    
                Text("Days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(subscription.color)
        )
    }
    
    
    private func getDaysBetween(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        return abs(calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0)
    }
    
    
}

#Preview {
    let date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    let sub = Subscription(name: "TEst", subscriptionDescription: "test description", price: 100, currencyCode: "USD", period: .monthly, firstBillingDate: date, tags: [], creditCard: nil, icon: "cloud", colorHex: Color.blue.toHexString(), isActive: true, createdAt: Date())
    
    SubscriptionShortItemView(subscription: sub)
        .environmentObject(AppSettings())
}
