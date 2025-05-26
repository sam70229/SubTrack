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
        isLoading = true
        repository.vote(for: wish, deviceID: deviceID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let voteResult):
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteWish(_ wish: Wish, completion: @escaping (Bool) -> Void) {
        isLoading = true
        repository.deleteWish(wishId: wish.id, requestingDeviceId: deviceId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    func updateWish(_ wish: Wish, title: String, content: String, completion: @escaping (Bool) -> Void) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Title cannot be empty"
            completion(false)
            return
        }
        
        isLoading = true
        repository.updateWish(
            wishId: wish.id,
            title: title,
            content: content,
            requestingDeviceId: deviceId
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
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
