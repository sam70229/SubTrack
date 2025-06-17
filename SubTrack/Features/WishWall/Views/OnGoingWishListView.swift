//
//  OnGoingWishListView.swift
//  SubTrack
//
//  Created by Sam on 2025/6/10.
//
import SwiftUI


struct OnGoingWishListView: View {
    
    var ongoingWishes: [Wish] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("In Development", systemImage: "hammer.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            ForEach(ongoingWishes) { wish in
                HStack {
                    VStack(alignment: .leading) {
                        Text(wish.title)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Coming soon...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    
                    Image(systemName: "gearshape.2.fill")
                        .foregroundStyle(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
            }
        }
    }
}
