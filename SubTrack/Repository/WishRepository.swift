//
//  WishRepository.swift
//  SubTrack
//
//  Created by Sam on 2025/4/9.
//
//
//  Data will be like
//
//      {
//          deviceID: {
//              "createdAt":
//          }
//          wishes:
//              {WishID}
//                  title:
//                  cotent:
//                  createdAt:
//                  voteCount:
//          votes:
//              {WishID}:
//                  voters:
//                      {DeviceID}:
//                          createdAt:
//              {WishID}:
//                  voters:
//                      {DeviceID}:
//                          createdAt
//      }
//
import SwiftUI
import Firebase
import FirebaseFirestore


class WishRepository: ObservableObject {
    @Published var wishes: [Wish] = []
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let wishCollection = "wishes"
    private let voteCollection = "votes"
    
    func fetchWishes(deviceID: String) {
        db.collection(wishCollection)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    return
                }
                
                var newWishes: [Wish] = []
                let group = DispatchGroup()

                for document in documents {
                    group.enter()
                    let data = document.data()
                    let wishId = document.documentID
                    
                    let title = data["title"] as? String ?? "Untitled"
                    let createdAt = data["createdAt"] as? Date ?? Date()
                    let content = data["content"] as? String ?? "no content"
                    let voteCount = data["voteCount"] as? Int ?? 0
                    let createdBy = data["createdBy"] as? String ?? "Anonymous"
                    
                    var wish = Wish(id: wishId, title: title, content: content, createdAt: createdAt, voteCount: voteCount, createdBy: createdBy)
                    
                    // Check if this device has voted for this wish
                    self.checkVoted(for: wish, deviceID: deviceID) { hasVoted in
                        wish.voted = hasVoted
                        newWishes.append(wish)
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    newWishes.sort { $0.createdAt.timeIntervalSince1970 < $1.createdAt.timeIntervalSince1970 }
                    self.wishes = newWishes
                }
            }
    }
    
    func addWish(title: String, content: String?, deviceId: String) {
        let newWish: [String: Any] = [
            "title": title,
            "content": content ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "voteCount": 0,
            "createdBy": deviceId,
        ]
        
        db.collection(wishCollection).addDocument(data: newWish) { error in
            if let error = error {
                self.errorMessage = "Failed to add wish: \(error.localizedDescription)"
            }
        }
    }
    
    func vote(for wish: Wish, deviceID: String) {
        let voteRef = db.collection(voteCollection).document(wish.id).collection("voters").document(deviceID)
        let wishRef = db.collection(wishCollection).document(wish.id)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let voteSnapshot: DocumentSnapshot
            let wishSnapshot: DocumentSnapshot
            do {
                try voteSnapshot = transaction.getDocument(voteRef)
                try wishSnapshot = transaction.getDocument(wishRef)
                
                if voteSnapshot.exists {
                    transaction.deleteDocument(voteRef)
                    
                    let currentCount = wishSnapshot.data()?["voteCount"] as? Int ?? 0
                    transaction.updateData(["voteCount": max(0, currentCount - 1)], forDocument: wishRef)
                    return false
                } else {
                    transaction.setData(["createdAt": FieldValue.serverTimestamp()], forDocument: voteRef)
                    
                    let currentCount = wishSnapshot.data()?["voteCount"] as? Int ?? 0
                    transaction.updateData(["voteCount": currentCount + 1], forDocument: wishRef)
                    
                    return true
                }
            } catch {
                return nil
            }
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let didVote = result as? Bool {
                // Immediately update the local wish array
                DispatchQueue.main.async {
                    if let index = self.wishes.firstIndex(where: { $0.id == wish.id }) {
                        
                        var updatedWish = self.wishes[index]
                        updatedWish.voted = didVote
                        updatedWish.voteCount = didVote ? 
                            updatedWish.voteCount + 1 : 
                            max(0, updatedWish.voteCount - 1)
                        
                        // Replace the old wish with the updated one
                        self.wishes[index] = updatedWish
                    }
                }
            }
        }
    }
    
    func checkVoted(for wish: Wish, deviceID: String, completion: @escaping(Bool) -> Void) {
        let voteRef = db.collection(voteCollection)
            .document(wish.id)
            .collection("voters")
            .document(deviceID)
        
        voteRef.getDocument { (document, error) in
            let hasVoted = document?.exists ?? false
            completion(hasVoted)
        }
    }
    
    func deleteWish(wishId: String, completion: @escaping (Error?) -> Void) {
        // Get references to the wish document and its votes collection
        let wishRef = db.collection(wishCollection).document(wishId)
        let votesRef = db.collection(voteCollection).document(wishId)
        
        // Use a batch to ensure atomicity
        let batch = db.batch()
        
        // Delete the wish document
        batch.deleteDocument(wishRef)
        
        // Delete the votes document (which contains the voters subcollection)
        batch.deleteDocument(votesRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                self.errorMessage = "Failed to delete wish: \(error.localizedDescription)"
            } else {
                // Remove from local array if successful
                DispatchQueue.main.async {
                    self.wishes.removeAll { $0.id == wishId }
                }
            }
            completion(error)
        }
        
        // Note: This doesn't automatically delete subcollections in Firestore
        // For a production app, consider using Cloud Functions to recursively delete
        // subcollections or implement a recursive deletion method
    }

    func updateWish(wishId: String, title: String, content: String, completion: @escaping (Error?) -> Void) {
        let wishRef = db.collection(wishCollection).document(wishId)
        
        let updatedData: [String: Any] = [
            "title": title,
            "content": content,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        wishRef.updateData(updatedData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Failed to update wish: \(error.localizedDescription)"
                completion(error)
            } else {
                // Update local array if successful
                DispatchQueue.main.async {
                    if let index = self.wishes.firstIndex(where: { $0.id == wishId }) {
                        var updatedWish = self.wishes[index]
                        updatedWish.title = title
                        updatedWish.content = content
                        // Replace the old wish with the updated one
                        self.wishes[index] = updatedWish
                    }
                }
                completion(nil)
            }
        }
    }
}
