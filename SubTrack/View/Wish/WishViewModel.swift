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
    
    private let repository: WishRepository = WishRepository()
    init() {
        repository.$wishes
            .receive(on: RunLoop.main)
            .assign(to: &$wishes)
    }
    
    func fetchWishes(deviceID: String) {
        repository.fetchWishes(deviceID: deviceID)
    }
    
    func submitWish() {
        repository.addWish(title: newTitle, content: newContent, deviceId: deviceId)
        newTitle = ""
        newContent = ""
    }
    
    func vote(for wish: Wish, deviceID: String) {
        repository.vote(for: wish, deviceID: deviceID)
    }
    
    func setDeviceId(_ deviceId: String) {
        self.deviceId = deviceId
    }
}
