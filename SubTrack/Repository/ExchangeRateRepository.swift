//
//  ExchangeRateRepository.swift
//  SubTrack
//
//  Created by Sam on 2025/4/17.
//
import Foundation
import Supabase


class ExchangeRateRepository: ObservableObject {
    @Published var rates: [String: Decimal] = [:]
    @Published var lastUpdated: Date?
    @Published var baseCurrency: String = "USD"
    
    private let supabase = SupabaseService.shared.client
    private var channel: RealtimeChannelV2?
    
    init() {
        Task {
            await startListening()
        }
    }
    
    deinit {
        unsubscribeFromRealtime()
    }
    
    func startListening() async {
        await fetchRates()
        
        await subscribe()
    }
    
    @MainActor
    private func fetchRates() async {
        do {
            struct ExchangeRateRecord: Codable {
                 let id: String
                 let rates: [String: Double]
                 let lastUpdated: Date
                 let base: String
                 
                 enum CodingKeys: String, CodingKey {
                     case id
                     case rates
                     case lastUpdated = "last_updated"
                     case base
                 }
             }
            
            let response: ExchangeRateRecord = try await supabase
                .from("exchange_rates")
                .select()
                .eq("id", value: "current")
                .single()
                .execute()
                .value
            
            self.rates = response.rates.mapValues { Decimal($0) }
            self.lastUpdated = response.lastUpdated
            self.baseCurrency = response.base
        } catch {
            print("Error fetching exchange rates: \(error)")
        }
    }
    
    private func subscribe() async {
        guard channel == nil else { return }
        
        channel = supabase.realtimeV2.channel("supabase_realtime")
        
        let updateStream = channel?.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "exchange_rates",
        )
        
        await channel?.subscribe()
        Task { @MainActor in
            for await update in updateStream! {
                if let jsonRates = try? JSONSerialization.data(withJSONObject: update.record["rates"]?.value),
                   let decodedRates = try? JSONDecoder().decode([String:Double].self, from: jsonRates),
                   let lastUpdated = update.record["last_updated"]?.value as? String,
                   let base = update.record["base"]?.value as? String {
                    
                    self.rates = decodedRates.mapValues { Decimal($0) }
                    
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    self.lastUpdated = formatter.date(from: lastUpdated)!
                    
                    self.baseCurrency = base
                }
            }
        }
    }
    
    private func unsubscribeFromRealtime() {
        Task {
            if let realtimeChannel = channel {
                await realtimeChannel.unsubscribe()
                channel = nil
            }
        }
    }
    
    func convert(_ amount: Decimal, from sourceCurrency: String, to targetCurrency: String) -> Decimal? {
        guard let sourceRate = rates[sourceCurrency],
              let targetRate = rates[targetCurrency],
              sourceRate > 0 else {
            return nil
        }
        
        // Convert through USD (base currency)
        let amountInUSD = amount / sourceRate
        return amountInUSD * targetRate
    }
    
    // Manual refresh method
    func refreshRates() async {
        await fetchRates()
    }
}
