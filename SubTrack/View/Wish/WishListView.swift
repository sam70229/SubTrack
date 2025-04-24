//
//  WishListView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/8.
//

import SwiftUI

struct WishListView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @ObservedObject var viewModel: WishViewModel
    
    @State private var showAddWishView: Bool = false
    @State private var showTutorial: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack {
                let myWishes = viewModel.wishes.filter { $0.createdBy == appSettings.deviceID}
                if myWishes.count > 0 {
                    Section {
                        ForEach(myWishes) { wish in
                            WishView(wish: wish)
                                .background(wish.voted ? Color.green : Color.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(8)
                                .onTapGesture { gesture in
                                    viewModel.vote(for: wish, deviceID: appSettings.deviceID)
                                }
                        }
                    } header: {
                        Text("My Wishes")
                            .font(.subheadline)
                    }
                }
                
                Section {
                    ForEach(viewModel.wishes.filter { $0.createdBy != appSettings.deviceID }) { wish in
                        WishView(wish: wish)
                            .background(wish.voted ? Color.green : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(8)
                            .onTapGesture { gesture in
                                viewModel.vote(for: wish, deviceID: appSettings.deviceID)
                            }
                    }
                } header: {
                    Text("Other Wishes")
                        .font(.subheadline)
                }
                
            }
        }
        .refreshable {
            viewModel.fetchWishes(deviceID: appSettings.deviceID)
        }
        .navigationTitle("Wish Wall")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddWishView = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddWishView) {
            NavigationStack {
                AddWishView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showTutorial) {
            WishListTutorialView()
        }
        .onAppear {
            viewModel.fetchWishes(deviceID: appSettings.deviceID)
            
            // Tutorial
            if !appSettings.hasSeenWishTutorial {
                showTutorial = true
                appSettings.hasSeenWishTutorial = true
            }
        }
    }
}
