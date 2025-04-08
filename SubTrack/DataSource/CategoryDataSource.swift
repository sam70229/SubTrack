//
//  CategoryDataSource.swift
//  SubTrack
//
//  Created by Sam on 2025/3/31.
//

import Foundation
import SwiftData


protocol CategoryDataSourceProtocol {
    func fetchCategories() -> [Category]
    func fetchCategory(withId id: UUID) -> Category?
    func addCategory(_ category: Category)
    func updateCategory(_ category: Category)
    func deleteCategory(withId id: UUID)
}


class CategoryDataSource: CategoryDataSourceProtocol {
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    @MainActor
    static let shared = CategoryDataSource()
    
    @MainActor
    private init() {
        self.modelContainer = try! ModelContainer(for: Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false))
        self.modelContext = modelContainer.mainContext
    }
    
    func fetchCategories() -> [Category] {
        return []
    }
    
    func fetchCategory(withId id: UUID) -> Category? {
        do {
            let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == id })
            return try modelContext.fetch(descriptor).first!
        } catch {
            return nil
        }
    }
    
    func addCategory(_ category: Category) {
        modelContext.insert(category)
    }
    
    func updateCategory(_ category: Category) {
        
    }
    
    func deleteCategory(withId id: UUID) {
        let category = self.fetchCategory(withId: id)
        if category != nil {
            modelContext.delete(category!)
        }
    }
}
