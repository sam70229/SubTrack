//
//  WishDetailView.swift
//  SubTrack
//
//  Created by Sam on 2025/5/22.
//
import SwiftUI


struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let tintColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(tintColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.callout)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}


struct WishDetailView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WishViewModel
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var animateVote = false
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedContent = ""
    @State private var showDeleteConfirmation = false
    @State private var localVoteCount: Int
    @State private var localHasVoted: Bool
    @State private var isVoting = false
    
    let wish: Wish
    
    init(wish: Wish, viewModel: WishViewModel) {
        self.wish = wish
        self.viewModel = viewModel
        self._localVoteCount = State(initialValue: wish.voteCount)
        self._localHasVoted = State(initialValue: wish.voted)
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            headerCard
            
            contentCard
            
            informationCard
            
            if (wish.createdBy == appSettings.deviceID) {
                actionSection
            }
            
            Spacer()
            
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if wish.createdBy != appSettings.deviceID {
                    voteButton
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditWishSheet(
                wish: wish,
                viewModel: viewModel,
                isPresented: $showingEditSheet
            )
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Delete Wish", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteWish()
            }
        } message: {
            Text("Are you sure you want to delete this wish? This action cannot be undone.")
        }
        .onAppear {
            // Ensure viewModel has the correct device ID
            viewModel.setDeviceId(appSettings.deviceID)
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            // Vote count with animated background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .scaleEffect(animateVote ? 1.2 : 1.0)
                
                if isVoting {
                    // Show loading indicator over vote count
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 80, height: 80)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    VStack(spacing: 4) {
                        Text("\(wish.voteCount)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Votes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isVoting)
            .padding(.top, 8)
            
            // Creator badge
            if wish.createdBy == appSettings.deviceID {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.caption)
                    Text("Created by You")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.blue.opacity(0.15))
                        .overlay(
                            Capsule()
                                .strokeBorder(.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 5)
        )
    }
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title Section
            VStack(alignment: .leading, spacing: 8) {
                Label("Title", systemImage: "text.quote")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(wish.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
                .background(Color(.separator).opacity(0.5))
            
            // Description Section
            VStack(alignment: .leading, spacing: 8) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(wish.content ?? "No description provided")
                    .font(.body)
                    .foregroundColor(wish.content == nil ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                
                if wish.content != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption2)
                        Text("Wishes requiring Internet connections will be considered based on budget constraints")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.orange.opacity(0.1))
                    )
                    .padding(.top, 8)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private var informationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Information", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "calendar",
                    title: "Created",
                    value: wish.createdAt.formatted(date: .abbreviated, time: .shortened),
                    tintColor: .blue
                )
                
                InfoRow(
                    icon: "person.fill",
                    title: "Creator",
                    value: wish.createdBy == appSettings.deviceID ? "You" : "Anonymous User",
                    tintColor: wish.createdBy == appSettings.deviceID ? .purple : .gray
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingEditSheet = true
            }) {
                Label("Edit Wish", systemImage: "square.and.pencil")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.blue)
                    )
                    .foregroundColor(.white)
            }
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                Label("Delete Wish", systemImage: "trash")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.red.opacity(0.5), lineWidth: 1.5)
                            )
                    )
                    .foregroundColor(.red)
            }
        }
        .padding(.top, 8)
    }
    
    private var voteButton: some View {
        Button(action: {
            performVote()
        }) {
            HStack(spacing: 6) {
                Image(systemName: wish.voted ? "heart.fill" : "heart")
                    .font(.body)
                    .foregroundColor(wish.voted ? .white : .blue)
                    .scaleEffect(animateVote ? 1.2 : 1.0)
                
                Text(wish.voted ? "Voted" : "Vote")
                    .font(.callout.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(wish.voted ? Color.red : Color.blue.opacity(0.15))
            )
            .foregroundColor(wish.voted ? .white : .blue)
            .overlay(
                Capsule()
                    .strokeBorder(wish.voted ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isVoting || viewModel.isLoading)  // Fixed: Now properly disabled only during voting
        .opacity(isVoting ? 0.6 : 1.0)
    }
    
    private func performVote() {
        // Prevent voting on own wishes
        guard wish.createdBy != appSettings.deviceID else { return }
        
        // Prevent multiple votes while processing
        guard !isVoting else { return }
        
        isVoting = true
        
        // Animate the vote button
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            animateVote = true
        }
        
        // Update local state optimistically for immediate feedback
        withAnimation {
            localHasVoted.toggle()
            localVoteCount += localHasVoted ? 1 : -1
        }
        
        // Call the API
        viewModel.vote(for: wish, deviceID: appSettings.deviceID)
        
        // Reset animation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateVote = false
        }
        
        // Since the viewModel.vote doesn't have a completion handler in the current implementation,
        // we'll wait a reasonable amount of time for the response
        // In production, you should modify the vote method to include a completion handler
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isVoting = false
            }
            
            // If there was an error, revert the optimistic update
            if viewModel.errorMessage != nil {
                withAnimation {
                    localHasVoted.toggle()
                    localVoteCount += localHasVoted ? 1 : -1
                }
            }
        }
    }
    
    private func deleteWish() {
        viewModel.deleteWish(wish) { success in
            if success {
                dismiss()
            }
        }
    }
}


#Preview {
    NavigationStack {
        WishDetailView(wish: Wish(id: UUID().uuidString, title: "TEst", createdAt: Date(), voteCount: 0, createdBy: UUID().uuidString),
                       viewModel: WishViewModel())
        .environmentObject(AppSettings())
    }
}
