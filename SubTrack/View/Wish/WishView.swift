//
//  WishView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/9.
//
import SwiftUI


struct WishView: View {
    @EnvironmentObject private var appSettings: AppSettings
    private let repo = WishRepository()
    
    @State var wish: Wish
    
    @State var voted: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(wish.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(wish.content ?? "No Content")
                    .font(.caption)
                Text("Created at: \(wish.createdAt, formatter: dateFormatter)")
                    .font(.subheadline)
            }
            Spacer()
            Text("\(wish.voteCount)")
        }
        .background(voted ? Color.green : Color.gray)
        .padding()
        .onAppear {
            repo.checkVoted(for: wish, deviceID: appSettings.deviceID) { voted in
                self.voted = voted
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}


#Preview {
    let wish = Wish(id: UUID().uuidString, title: "Test Wish", content: "Test Content", createdAt: Date(), voteCount: 0)
    WishView(wish: wish)
}
