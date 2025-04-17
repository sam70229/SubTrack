//
//  SubscriptionListItemView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI


struct SubscriptionListItemView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject private var exchangeRates: ExchangeRateRepository

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
                
                if appSettings.billingInfoDisplay == .billingCycle {
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
            let price = switch appSettings.priceDisplayMode {
            case .original:
                subscription.price
            case .converted:
                exchangeRates.convert(subscription.price, from: subscription.currencyCode, to: appSettings.currencyCode) ?? subscription.price
            }
            
            let currencyCode = switch appSettings.priceDisplayMode {
            case .original:
                subscription.currencyCode
            case .converted:
                appSettings.currencyCode
            }

            let formatStyle: Decimal.FormatStyle.Currency = CurrencyInfo.hasDecimals(currencyCode) ? .currency(code: currencyCode) : .currency(code: currencyCode).precision(.fractionLength(0))
            
            appSettings.showCurrencySymbols ? Text(price, format: formatStyle) : Text("\(price)")
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
