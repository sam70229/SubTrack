//
//  WishRepository.swift
//  SubTrack
//
//  Created by Sam on 2025/5/27.
//
import SwiftUI
import Supabase
import Realtime


class WishRepository: ObservableObject {
    static let shared = WishRepository()
    
    @Published var wishes: [Wish] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private let supabase = SupabaseService.shared.client
    private var currentDeviceId: String = ""
    
    // MARK: - Fetch Wishes
    func fetchWishes(deviceID: String) {
        currentDeviceId = deviceID

        Task {
            wishes = await fetchWishes(deviceID: deviceID)
            await subscribeToRealtime(deviceID: deviceID)
        }
    }
    
    @MainActor
    private func fetchWishes(deviceID: String) async -> [Wish] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch wishes with vote status for current device
            let wishes: [Wish] = try await supabase
                .from("wishes")
                .select("*")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            let votes: [Vote] = try await supabase
                .from("votes")
                .select("*")
                .eq("device_id", value: deviceID)
                .execute()
                .value
            
            let votedWishIds = Set(votes.map { $0.wishId })
            
            // Convert to your Wish model
            return wishes.map { wish in
                Wish(
                    id: wish.id,
                    title: wish.title,
                    content: wish.content,
                    createdAt: wish.createdAt,
                    voteCount: wish.voteCount,
                    status: wish.status,
                    voted: votedWishIds.contains(wish.id),
                    createdBy: wish.createdBy
                )
            }
        } catch {
            self.errorMessage = "Failed to fetch wishes: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Add Wish
    func addWish(title: String, content: String?, deviceId: String) {
        Task {
            await addWishAsync(title: title, content: content, deviceId: deviceId)
        }
    }
    
    @MainActor
    private func addWishAsync(title: String, content: String?, deviceId: String) async {
        do {
            let newWish = [
                "title": title,
                "content": content ?? "",
                "created_by": deviceId
            ]
            
            let response: Wish = try await supabase
                .from("wishes")
                .insert(newWish)
                .select()
                .single()
                .execute()
                .value
            
            // Add to local array immediately
            let wish = Wish(
                id: response.id,
                title: response.title,
                content: response.content,
                createdAt: response.createdAt,
                voteCount: response.voteCount,
                status: response.status,
                createdBy: response.createdBy
            )
            
            wishes.insert(wish, at: 0)
        } catch {
            self.errorMessage = "Failed to add wish: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Vote
    func vote(for wish: Wish, deviceID: String) {
        Task {
            await voteAsync(for: wish, deviceID: deviceID)
        }
    }
    
    @MainActor
    private func voteAsync(for wish: Wish, deviceID: String) async {
        do {
            // Call the toggle_vote function
            let _ = try await supabase
                .rpc("toggle_vote", params: [
                    "p_wish_id": wish.id.uuidString,
                    "p_device_id": deviceID
                ])
                .execute()
            
            // Update local state immediately
            if let index = wishes.firstIndex(where: { $0.id == wish.id }) {
                var updatedWish = wishes[index]
                updatedWish.voted.toggle()
                updatedWish.voteCount = updatedWish.voted ?
                updatedWish.voteCount + 1 :
                max(0, updatedWish.voteCount - 1)
                wishes[index] = updatedWish
            }
        } catch {
            self.errorMessage = "Failed to vote: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Delete Wish
    func deleteWish(wishId: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                try await supabase
                    .from("wishes")
                    .delete()
                    .eq("id", value: wishId)
                    .execute()
                
                // Remove from local array
                await MainActor.run {
                    wishes.removeAll { $0.id.uuidString == wishId }
                    completion(nil)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete wish: \(error.localizedDescription)"
                    completion(error)
                }
            }
        }
    }
    
    // MARK: - Update Wish
    func updateWish(wishId: String, title: String, content: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                let updates = [
                    "title": title,
                    "content": content
                ]
                
                try await supabase
                    .from("wishes")
                    .update(updates)
                    .eq("id", value: wishId)
                    .execute()
                
                // Update local array
                await MainActor.run {
                    if let index = self.wishes.firstIndex(where: { $0.id.uuidString == wishId }) {
                        var updatedWish = self.wishes[index]
                        updatedWish.title = title
                        updatedWish.content = content
                        self.wishes[index] = updatedWish
                    }
                    completion(nil)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update wish: \(error.localizedDescription)"
                    completion(error)
                }
            }
        }
    }
    
    // MARK: - Realtime Subscription
    private func subscribeToRealtime(deviceID: String) async {
//        let realtimeChannel = supabase.realtimeV2.channel("supabase_realtime")
//        let wishStream = realtimeChannel.postgresChange(AnyAction.self, schema: "public", table: "wishes")
        
        let channel = supabase.channel("public:wishes")
        let insertions = channel.postgresChange(InsertAction.self, table: "wishes")
        let updates = channel.postgresChange(UpdateAction.self, table: "wishes")
        let deletions = channel.postgresChange(DeleteAction.self, table: "wishes")

        // TODO: - Make sure we need this in future
//        let voteStream = realtimeChannel?.postgresChange(AnyAction.self, schema: "public", table: "votes")
        
        await channel.subscribe()
        
        Task {
            for await insertion in insertions {
                if let wish = decodeWish(from: insertion.record) {
                    await handleInsertNewWish(wish, deviceID: deviceID)
                }
            }
        }
        
        Task {
            for await update in updates {
                if let wish = decodeWish(from: update.record) {
                    await handleUpdatedWish(wish, deviceID: deviceID)
                }
            }
        }
         
        Task {
            for await delete in deletions {
                if let id = delete.oldRecord["id"]?.value as? String {
                    wishes.removeAll(where: { $0.id.uuidString == id.uppercased() })
                }
            }
        }
                
        // TODO: - Make sure we need this in future
        //            for await change in voteStream! {
        //                switch change {
        //                case .delete(let action): print("Deleted vote: \(action.oldRecord)")
        //                case .insert(let action): print("Inserted vote: \(action.record)")
        //                case .update(let action): print("Updated vote: \(action.oldRecord) with \(action.record)")
        //                }
        //            }
    }
    
    private func decodeWish(from record: [String: AnyJSON]) -> Wish? {
        guard let id = record["id"]?.stringValue,
              let title = record["title"]?.stringValue,
              let content = record["content"]?.stringValue,
              let status = record["status"]?.stringValue,
              let vote_count = record["vote_count"]?.intValue,
              let created_by = record["created_by"]?.stringValue,
              let created_at = record["created_at"]?.stringValue else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: created_at) else {
            return nil
        }
        
        return Wish(
            id: UUID(uuidString: id)!,
            title: title,
            content: content,
            createdAt: date,
            voteCount: vote_count,
            status: status,
            createdBy: created_by
        )
    }
    
    @MainActor
    private func handleInsertNewWish(_ wish: Wish, deviceID: String) async {
        // Check if wish already exists locally
        guard !wishes.contains(where: { $0.id == wish.id }) else { return }
        
        // Check if user has voted
        let hasVoted = await checkIfVoted(wishId: wish.id, deviceID: deviceID)
        
        let wish = Wish(
            id: wish.id,
            title: wish.title,
            content: wish.content,
            createdAt: wish.createdAt,
            voteCount: wish.voteCount,
            status: wish.status,
            voted: hasVoted,
            createdBy: wish.createdBy
        )
        
        wishes.insert(wish, at: 0)
    }
    
    @MainActor
    private func handleUpdatedWish(_ wish: Wish, deviceID: String) async {
        guard let index = wishes.firstIndex(where: { $0.id == wish.id }) else { return }
        
        var updatedWish = wishes[index]
        updatedWish.title = wish.title
        updatedWish.content = wish.content
        updatedWish.voteCount = wish.voteCount
        
        wishes[index] = updatedWish
    }
    
    private func checkIfVoted(wishId: UUID, deviceID: String) async -> Bool {
        do {
            let response: [Vote] = try await supabase
                .from("votes")
                .select()
                .eq("wish_id", value: wishId.uuidString)
                .eq("device_id", value: deviceID)
                .execute()
                .value
            
            return !response.isEmpty
        } catch {
            return false
        }
    }
    
//    private func unsubscribeFromRealtime() {        
//        guard realtimeChannel != nil else { return }
//        Task {
//            await realtimeChannel?.unsubscribe()
//            realtimeChannel = nil
//        }
//    }
    
    // Helper methods for vote changes
    @MainActor
    private func handleVoteAdded(_ vote: Vote, deviceID: String) async {
        if let index = wishes.firstIndex(where: { $0.id == vote.wishId }) {
            var updatedWish = wishes[index]
            updatedWish.voteCount += 1
            if vote.deviceId == deviceID {
                updatedWish.voted = true
            }
            wishes[index] = updatedWish
        }
    }
    
    @MainActor
    private func handleVoteRemoved(_ vote: Vote, deviceID: String) async {
        if let index = wishes.firstIndex(where: { $0.id == vote.wishId }) {
            var updatedWish = wishes[index]
            updatedWish.voteCount = max(0, updatedWish.voteCount - 1)
            if vote.deviceId == deviceID {
                updatedWish.voted = false
            }
            wishes[index] = updatedWish
        }
    }
}

