//
//  SubscriptionItemCard.swift
//  SubTrack
//
//  Created by Sam on 2025/3/27.
//
import SwiftUI

enum SubscriptionInfoStyle: String, CaseIterable {
    case nextBillingDate = "Next Billing Date"
    case billingCycle = "Billing Cycle"
}


struct SubscriptionItemCard: View {
    @EnvironmentObject var appSettings: AppSettings
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: subscription.icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(subscription.color)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.headline)
                
                switch appSettings.subscriptionInfoType {
                case .nextBillingDate:
                    Text(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .billingCycle:
                    Text(subscription.billingCycle.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
            }
            
            Spacer()
            
            // Price
            Text(subscription.price.formatted(.currency(code: appSettings.currencyCode)))
                .font(.subheadline.bold())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
