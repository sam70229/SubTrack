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
import FirebaseFunctions


struct VoteResult {
    let hasVoted: Bool
    let newVoteCount: Int
}

enum WishError: Error {
    case unauthorized
    case notFound
    case serverError(String)
    
    var localizedDescription: String {
        switch self {
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .notFound:
            return "The requested wish could not be found"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}


class WishRepository: ObservableObject {
    @Published var wishes: [Wish] = []
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
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
    
    func vote(for wish: Wish, deviceID: String, completion: @escaping(Result<VoteResult, WishError>) -> Void = { _ in}) {
        let voteFunction = functions.httpsCallable("voteForWish")
        
        voteFunction.call(["wishId": wish.id, "deviceId": deviceID]) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error as NSError? {
                let message = error.localizedDescription
                self.errorMessage = "Failed to vote: \(message)"
                
                if error.domain == FunctionsErrorDomain {
                    switch error.code {
                    case FunctionsErrorCode.notFound.rawValue:
                        completion(.failure(.notFound))
                    case FunctionsErrorCode.permissionDenied.hashValue:
                        completion(.failure(.unauthorized))
                    default:
                        completion(.failure(.serverError(message)))
                    }
                } else {
                    completion(.failure(.serverError(message)))
                }
                return
            }
            
            guard let data = result?.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let hasVoted = data["hasVoted"] as? Bool,
                  let newVoteCount = data["newVoteCount"] as? Int else {
                self.errorMessage = "Invalid response from server"
                completion(.failure(.serverError("Invalid response from server")))
                return
            }
            
            // Update local wish array immediately for better UX
            DispatchQueue.main.async {
                if let index = self.wishes.firstIndex(where: { $0.id == wish.id }) {
                    var updatedWish = self.wishes[index]
                    updatedWish.voted = hasVoted
                    updatedWish.voteCount = newVoteCount
                    self.wishes[index] = updatedWish
                }
            }
            
            completion(.success(VoteResult(hasVoted: hasVoted, newVoteCount: newVoteCount)))
        }
        
        // OLD ONe
        //        let voteRef = db.collection(voteCollection).document(wish.id).collection("voters").document(deviceID)
        //        let wishRef = db.collection(wishCollection).document(wish.id)
        //
        //        db.runTransaction({ (transaction, errorPointer) -> Any? in
        //            let voteSnapshot: DocumentSnapshot
        //            let wishSnapshot: DocumentSnapshot
        //            do {
        //                try voteSnapshot = transaction.getDocument(voteRef)
        //                try wishSnapshot = transaction.getDocument(wishRef)
        //
        //                if voteSnapshot.exists {
        //                    transaction.deleteDocument(voteRef)
        //
        //                    let currentCount = wishSnapshot.data()?["voteCount"] as? Int ?? 0
        //                    transaction.updateData(["voteCount": max(0, currentCount - 1)], forDocument: wishRef)
        //                    return false
        //                } else {
        //                    transaction.setData(["createdAt": FieldValue.serverTimestamp()], forDocument: voteRef)
        //
        //                    let currentCount = wishSnapshot.data()?["voteCount"] as? Int ?? 0
        //                    transaction.updateData(["voteCount": currentCount + 1], forDocument: wishRef)
        //
        //                    return true
        //                }
        //            } catch {
        //                return nil
        //            }
        //        }) { [weak self] (result, error) in
        //            guard let self = self else { return }
        //
        //            if let error = error {
        //                self.errorMessage = error.localizedDescription
        //            } else if let didVote = result as? Bool {
        //                // Immediately update the local wish array
        //                DispatchQueue.main.async {
        //                    if let index = self.wishes.firstIndex(where: { $0.id == wish.id }) {
        //
        //                        var updatedWish = self.wishes[index]
        //                        updatedWish.voted = didVote
        //                        updatedWish.voteCount = didVote ?
        //                            updatedWish.voteCount + 1 :
        //                            max(0, updatedWish.voteCount - 1)
        //
        //                        // Replace the old wish with the updated one
        //                        self.wishes[index] = updatedWish
        //                    }
        //                }
        //            }
        //        }
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
    
    func deleteWish(wishId: String, requestingDeviceId: String, completion: @escaping (Result<Void, WishError>) -> Void) {
        let deleteFunction = functions.httpsCallable("deleteWish")
        
        deleteFunction.call([
            "wishId": wishId,
            "deviceId": requestingDeviceId
        ]) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error as NSError? {
                let message = error.localizedDescription
                self.errorMessage = "Failed to delete wish: \(message)"
                
                // Handle specific Firebase Function errors
                if error.domain == FunctionsErrorDomain {
                    switch error.code {
                    case FunctionsErrorCode.notFound.rawValue:
                        completion(.failure(.notFound))
                    case FunctionsErrorCode.permissionDenied.rawValue:
                        completion(.failure(.unauthorized))
                    default:
                        completion(.failure(.serverError(message)))
                    }
                } else {
                    completion(.failure(.serverError(message)))
                }
                return
            }
            
            guard let data = result?.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                self.errorMessage = "Invalid response from server"
                completion(.failure(.serverError("Invalid response from server")))
                return
            }
            
            // Remove from local array if successful
            DispatchQueue.main.async {
                self.wishes.removeAll { $0.id == wishId }
            }
            
            completion(.success(()))
        }
    }
    
    func updateWish(wishId: String, title: String, content: String, requestingDeviceId: String, completion: @escaping (Result<Void, WishError>) -> Void) {
        let updateFunction = functions.httpsCallable("updateWish")
        
        updateFunction.call([
            "wishId": wishId,
            "deviceId": requestingDeviceId,
            "title": title,
            "content": content
        ]) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error as NSError? {
                let message = error.localizedDescription
                self.errorMessage = "Failed to update wish: \(message)"
                
                // Handle specific Firebase Function errors
                if error.domain == FunctionsErrorDomain {
                    switch error.code {
                    case FunctionsErrorCode.notFound.rawValue:
                        completion(.failure(.notFound))
                    case FunctionsErrorCode.permissionDenied.rawValue:
                        completion(.failure(.unauthorized))
                    default:
                        completion(.failure(.serverError(message)))
                    }
                } else {
                    completion(.failure(.serverError(message)))
                }
                return
            }
            
            guard let data = result?.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                self.errorMessage = "Invalid response from server"
                completion(.failure(.serverError("Invalid response from server")))
                return
            }
            
            // Update local array if successful
            DispatchQueue.main.async {
                if let index = self.wishes.firstIndex(where: { $0.id == wishId }) {
                    var updatedWish = self.wishes[index]
                    updatedWish.title = title
                    updatedWish.content = content
                    self.wishes[index] = updatedWish
                }
            }
            
            completion(.success(()))
        }
    }
}
