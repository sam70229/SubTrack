//
//  ExchangeRateRepository.swift
//  SubTrack
//
//  Created by Sam on 2025/4/17.
//
import FirebaseFirestore


class ExchangeRateRepository: ObservableObject {
    @Published var rates: [String: Decimal] = [:]
    @Published var lastUpdated: Date?
    private var listener: ListenerRegistration?
    
    init() {
        let db = Firestore.firestore()
        self.listener = db.collection("system").document("exchange_rates").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let ratesDict = data["rates"] as? [String: Double] else {
                return
            }
            
            self.rates = ratesDict.mapValues{ Decimal($0) }
            self.lastUpdated = (data["lastUpdated"] as? Timestamp)?.dateValue()
        }
    }
    
    deinit {
        self.listener?.remove()
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
}
