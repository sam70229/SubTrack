//
//  WishListView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/8.
//

import SwiftUI


enum SortOptions: String, CaseIterable {
    case topVoted
    case mostRecent
    
    var description: String {
        switch self {
        case .topVoted:
            return "Top Voted"
        case .mostRecent:
            return "Most Recent"
        }
    }
}


struct WishListView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @ObservedObject var viewModel: WishViewModel
    
    @State private var showAddWishView: Bool = false
    @State private var showTutorial: Bool = false
    @State private var hoveredWishID: String?
    
    // Sort
    @State private var sortedDict: [String: SortOptions] = [
        "My Wishes": .mostRecent,
        "Community Wishes": .mostRecent
    ]
    @State private var showSortOptionPicker: Bool = false
    @State private var sortSectionTitle: String = ""
    
    
    private var myWishList: [Wish] {
        viewModel.wishes.filter { $0.createdBy == appSettings.deviceID }
    }
    
    private var communityWishList: [Wish] {
        viewModel.wishes.filter { $0.createdBy != appSettings.deviceID && $0.status != WishStatus.inDevelopment.description }
    }
    
    private var onGoingWishList: [Wish] {
        viewModel.wishes.filter { $0.status == WishStatus.inDevelopment.description }
    }
    
    private func sortedWishes(for sectionTitle: String, wishes: [Wish]) -> [Wish] {
        switch sortedDict[sectionTitle]! {
        case .topVoted:
            return wishes.sorted { $0.voteCount > $1.voteCount }
        case .mostRecent:
            return wishes.sorted { $0.createdBy > $1.createdBy }
        }
    }
    
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
                    if onGoingWishList.count > 0 {
                        OnGoingWishListView(ongoingWishes: onGoingWishList)
                    }
                    
                    if myWishList.count > 0 {
                        myWishList(wishList: myWishList)
                    }
                    
                    if communityWishList.count > 0 {
                        othersWishList(wishList: communityWishList)
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
        .sheet(isPresented: $showSortOptionPicker) {
            VStack {
                ForEach(SortOptions.allCases, id: \.self) { option in
                    Text(LocalizedStringKey(option.description))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.secondary)
                        )
                        .padding(.horizontal)
                        .onTapGesture {
                            sortedDict[sortSectionTitle] = option
                            showSortOptionPicker = false
                        }
                }
            }
            .presentationDetents([.height(150)])
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
        VStack {
            let title: String = "My Wishes"
            sectionHeader(title: title, subtitle: "\(wishList.count) wishes", icon: "person")
            
            wishGrid(sortedWishes(for: title, wishes: wishList), isOwner: true)
        }
    }
    
    private func othersWishList(wishList: [Wish]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            let title = "Community Wishes"
            sectionHeader(title: title, subtitle: "\(wishList.count) wishes", icon: "globe")
            
            wishGrid(sortedWishes(for: title, wishes: wishList), isOwner: false)
        }
        .padding(.vertical, 4)
    }
    
    private func wishGrid(_ wishes: [Wish], isOwner: Bool) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(wishes) { wish in
                wishCard(wish: wish, isOwner: isOwner)
            }
        }
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
            
            // filter button
            Button {
                showSortOptionPicker = true
                sortSectionTitle = title
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
            }
            
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
