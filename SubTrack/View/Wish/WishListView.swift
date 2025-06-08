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
    @State private var hoveredWishID: String?
    
    var body: some View {
        ZStack {
            // Background gradient for depth
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground).opacity(0.8),
                    Color(.systemBackground).opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 24) {
                    let myWishes = viewModel.wishes.filter { $0.createdBy == appSettings.deviceID}
                    let otherWishes = viewModel.wishes.filter { $0.createdBy != appSettings.deviceID}
                    
                    if myWishes.count > 0 {
                        myWishList(wishList: myWishes)
                    }
                    
                    if otherWishes.count > 0 {
                        othersWishList(wishList: otherWishes)
                    }
                    
                    // Add some bottom padding for better scrolling experience
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 20)
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
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Community Wishes", subtitle: "\(wishList.count) wishes", icon: "globe")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(wishList) { wish in
                    wishCard(wish: wish, isOwner: false)
                }
            }
        }
        .padding(.vertical, 4)
//        Section {
//            ForEach(wishList) { wish in
//                NavigationLink {
//                    WishDetailView(wish: wish, viewModel: viewModel)
//                } label: {
////                    WishView(wish: wish)
////                        .padding(8)
//                    wishCard(wish: wish, isOwner: false)
//                }
//                .buttonStyle(PlainButtonStyle())
//            }
//        } header: {
//            Text("Community Wishes")
//                .font(.subheadline)
//        }
    }
    
    // MARK: - Section Header
        private func sectionHeader(title: String, subtitle: String, icon: String) -> some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    
    private func wishCard(wish: Wish, isOwner: Bool) -> some View {
            NavigationLink {
                WishDetailView(wish: wish, viewModel: viewModel)
            } label: {
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            isOwner ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 0) {
                        WishView(wish: wish)
                    }
                }
                .scaleEffect(hoveredWishID == wish.id.uuidString ? 1.05 : 1.0)
                .shadow(
                    color: Color.black.opacity(hoveredWishID == wish.id.uuidString ? 0.3 : 0.1),
                    radius: hoveredWishID == wish.id.uuidString ? 15 : 8,
                    x: 0,
                    y: hoveredWishID == wish.id.uuidString ? 8 : 4
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hoveredWishID)
                .onHover { isHovering in
                    hoveredWishID = isHovering ? wish.id.uuidString : nil
                }
            }
            .buttonStyle(.plain)
        }
}
