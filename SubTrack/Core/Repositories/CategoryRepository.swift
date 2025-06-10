//
//  CategoryRepository.swift
//  SubTrack
//
//  Created by Sam on 2025/3/31.
//
import SwiftUI
import SwiftData


// A repository class that handles category-related business logic
class CategoryRepository: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addCategory(_ category: Category) throws {
        modelContext.insert(category)
    }
    
    func updateCategory(_ category: Category) throws {
        // SwiftData automatically tracks changes to existing objects
        // No need to call save()
    }
    
    func deleteCategory(_ category: Category) throws {
        modelContext.delete(category)
    }
    
    func fetchCategories() -> [Category] {
        do {
            let descriptor = FetchDescriptor<Category>()
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    func fetchCategory(withId id: UUID) -> Category? {
        do {
            let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == id })
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching category: \(error)")
            return nil
        }
    }
} 
