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
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                let myWishes = viewModel.wishes.filter { $0.createdBy == appSettings.deviceID}
                let otherWishes = viewModel.wishes.filter { $0.createdBy != appSettings.deviceID}

                if myWishes.count > 0 {
                    myWishList(wishList: myWishes)
                }

                othersWishList(wishList: otherWishes)

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
        .alert("Error", isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.clearError() }
        )) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        // Add loading overlay
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
            }
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
    
    private func myWishList(wishList: [Wish]) -> some View {
        Section {
            ForEach(wishList) { wish in
                NavigationLink {
                    WishDetailView(wish: wish, viewModel: viewModel)
                } label: {
                    WishView(wish: wish)
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        } header: {
            Text("My Wishes")
                .font(.subheadline)
        }
    }
    
    private func othersWishList(wishList: [Wish]) -> some View {
        Section {
            ForEach(wishList) { wish in
                NavigationLink {
                    WishDetailView(wish: wish, viewModel: viewModel)
                } label: {
                    WishView(wish: wish)
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        } header: {
            Text("Other Wishes")
                .font(.subheadline)
        }
    }
}
