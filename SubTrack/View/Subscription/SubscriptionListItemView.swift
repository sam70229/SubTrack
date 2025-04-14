//
//  SubscriptionListItemView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI


struct SubscriptionListItemView: View {
    @EnvironmentObject var appSettings: AppSettings
    let subscription: Subscription
    
    let onSwipeToDelete: (Subscription) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if appSettings.showSubscriptionIcons {
                Image(systemName: subscription.icon)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(subscription.color)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.headline)
                
                if appSettings.subscriptionDisplayStyle == .billingCycle {
                    Text(subscription.billingCycle.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Price
            let formatStyle: Decimal.FormatStyle.Currency = CurrencyInfo.hasDecimals(appSettings.currencyCode) ? .currency(code: appSettings.currencyCode) : .currency(code: appSettings.currencyCode).precision(.fractionLength(0))
            appSettings.showCurrencySymbols ? Text(subscription.price, format: formatStyle) : Text("\(subscription.price)")
                .font(.subheadline.bold())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .swipeActions {
            Button(role: .destructive) {
                onSwipeToDelete(subscription)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}
