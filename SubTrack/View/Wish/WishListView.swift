//
//  WishListView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/8.
//

import SwiftUI

struct WishListView: View {
    @EnvironmentObject private var appSettings: AppSettings
    private let repo = WishRepository()
    
    @State var wishes: [Wish] = []
    @State private var showAddWishView: Bool = false
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(wishes) { wish in
                    WishView(wish: wish)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(8)
                        .onTapGesture { gesture in
                            repo.vote(for: wish, deviceID: appSettings.deviceID)
                        }
                }
            }
        }
        .navigationTitle("Wishes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddWishView = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            Task {
                repo.fetchWishes { wishes in
                    self.wishes = wishes
                }
            }
        }
        .sheet(isPresented: $showAddWishView) {
            NavigationStack {
                AddWishView()
            }
        }
    }
}

#Preview {
    let wishes = [
        Wish(id: UUID().uuidString, title: "Test Wish", content: "Test Content", createdAt: Date(), voteCount: Int.random(in: 1..<100)),
        Wish(id: UUID().uuidString, title: "Test Wish", content: "Test Content", createdAt: Date(), voteCount: Int.random(in: 1..<100)),
        Wish(id: UUID().uuidString, title: "Test Wish", content: "Test Content", createdAt: Date(), voteCount: Int.random(in: 1..<100)),
        Wish(id: UUID().uuidString, title: "Test Wish", content: "Test Content", createdAt: Date(), voteCount: Int.random(in: 1..<100)),
        Wish(id: UUID().uuidString, title: "Test Wish", content: "Test Content", createdAt: Date(), voteCount: Int.random(in: 1..<100)),
        Wish(id: UUID().uuidString, title: "Test Wish", content: "Test Content", createdAt: Date(), voteCount: Int.random(in: 1..<100)),
    ]
    WishListView(wishes: wishes)
}

