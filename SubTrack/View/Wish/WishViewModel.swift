//
//  WishViewModel.swift
//  SubTrack
//
//  Created by Sam on 2025/4/9.
//
import SwiftUI


class WishViewModel: ObservableObject {
    @Published var newTitle: String = ""
    @Published var newContent: String = ""
    @Published var deviceId: String = ""
    @Published var wishes: [Wish] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let repository: WishRepository = WishRepository()
    
    init() {
        // Bind repository wishes to view model
        repository.$wishes
            .receive(on: RunLoop.main)
            .assign(to: &$wishes)
        
        // Bind repository error messages to view model
        repository.$errorMessage
            .receive(on: RunLoop.main)
            .assign(to: &$errorMessage)
        
        // Bind repository loading state
        repository.$isLoading
            .receive(on: RunLoop.main)
            .assign(to: &$isLoading)
    }
    
    func fetchWishes(deviceID: String) {
        repository.fetchWishes(deviceID: deviceID)
    }
    
    func submitWish() {
        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Title cannot be empty"
            return
        }

        repository.addWish(title: newTitle, content: newContent, deviceId: deviceId)
        newTitle = ""
        newContent = ""
    }
    
    func vote(for wish: Wish, deviceID: String) {
        repository.vote(for: wish, deviceID: deviceID)
    }
    
    func deleteWish(_ wish: Wish, completion: @escaping (Bool) -> Void) {
        guard canModify(wish) else {
            errorMessage = "You can only delete your own wishes"
            completion(false)
            return
        }
        
        repository.deleteWish(wishId: wish.id.uuidString, completion: { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        })
    }
    
    func updateWish(_ wish: Wish, title: String, content: String, completion: @escaping (Bool) -> Void) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Title cannot be empty"
            completion(false)
            return
        }
        
        guard canModify(wish) else {
            errorMessage = "You can only update your own wishes"
            completion(false)
            return
        }
        
        repository.updateWish(
            wishId: wish.id.uuidString,
            title: title,
            content: content,
            completion: { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        )
    }
    
    func setDeviceId(_ deviceId: String) {
        self.deviceId = deviceId
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // Helper method to check if current user can modify a wish
    func canModify(_ wish: Wish) -> Bool {
        return wish.createdBy == deviceId
    }
}
