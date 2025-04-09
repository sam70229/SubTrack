//
//  WishRepository.swift
//  SubTrack
//
//  Created by Sam on 2025/4/9.
//
import SwiftUI
import FirebaseDatabase


class WishRepository: ObservableObject {
    private let dbRef = Database.database().reference()
    private let wishNode = "wishes"
    private let voteNode = "votes"
    
    
    func fetchWishes(completion: @escaping([Wish]) -> Void) {
        dbRef.child(wishNode).observe(.value) { snapshot in
            var wishes: [Wish] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let title = dict["title"] as? String,
                   let createdAt = dict["createdAt"] as? TimeInterval,
                   let content = dict["content"] as? String {
                    let votes = dict["voteCount"] as? Int ?? 0
                    wishes.append(Wish(id: snapshot.key, title: title, content: content, createdAt: Date(timeIntervalSince1970: createdAt), voteCount: votes))
                }
            }
            completion(wishes)
        }
    }
    
    func addWish(title: String, content: String?) {
        let newRef = dbRef.child(wishNode).childByAutoId()
        newRef.setValue(["title": title, "content": content ?? "", "createdAt": Date().timeIntervalSince1970, "voteCount": 0])
    }
    
    func vote(for wish: Wish, deviceID: String) {
        let votePath = dbRef.child(voteNode).child(wish.id).child(deviceID)
        print(votePath)
        let voteCountRef = self.dbRef.child(self.wishNode).child(wish.id).child("voteCount")
        votePath.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                votePath.removeValue()
                voteCountRef.runTransactionBlock { currentData in
                    if var count = currentData.value as? Int {
                        if count >= 0 {
                            count -= 1
                        }
                        currentData.value = count
                        return TransactionResult.success(withValue: currentData)
                    }
                    return TransactionResult.success(withValue: currentData)
                }
                return
            }
            
            votePath.setValue(true)
            
            voteCountRef.runTransactionBlock { currentData in
                var count = currentData.value as? Int ?? 0
                count += 1
                currentData.value = count
                return TransactionResult.success(withValue: currentData)
            }
        }
    }
    
    func checkVoted(for wish: Wish, deviceID: String, completion: @escaping (Bool) -> Void) {
        let votePath = dbRef.child(voteNode).child(wish.id).child(deviceID)
        votePath.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
