//
//  WishListTutorialView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/23.
//
import SwiftUI


struct WishListTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TabView {
            // First page - Introduction
            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Welcome to Wish Wall")
                    .font(.title.bold())
                
                Text("A place where you can share your feature requests and vote for others' wishes.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Second page - Creating Wishes
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Create Wishes")
                    .font(.title.bold())
                
                Text("Tap the + button to create a new wish.\nAdd a title and description to share your ideas.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Third page - Voting
            VStack(spacing: 20) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Vote for Wishes")
                    .font(.title.bold())
                
                Text("Tap on any wish to vote.\nGreen background indicates you've voted for that wish.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Fourth page - Get Started
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Ready to Start!")
                    .font(.title.bold())
                
                Text("Share your ideas and help shape the future of SubTrack!")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Get Started") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

#Preview {
    WishListTutorialView()
}
