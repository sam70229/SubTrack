//
//  CreditCardRepository.swift
//  SubTrack
//
//  Created by Sam on 2025/4/12.
//
import SwiftUI
import SwiftData


class CreditCardRepository: ObservableObject {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchCreditCards() -> [CreditCard] {
        do {
            let descriptor = FetchDescriptor<CreditCard>()
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    func addCreditCard(_ creditCard: CreditCard) {
        modelContext.insert(creditCard)
    }
    
    func deleteCreditCard(_ creditCard: CreditCard) {
        modelContext.delete(creditCard)
    }
}
