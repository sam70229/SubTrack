//
//  WishView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/9.
//
import SwiftUI


struct WishView: View {
    var wish: Wish
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(wish.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
                
                Text(wish.content ?? "No Content")
                    .font(.caption)

                Spacer()

                Text("Created at: \(wish.createdAt, formatter: dateFormatter)")
                    .font(.caption2)
            }
            
            Spacer()

            Text("\(wish.voteCount)")
                .padding(.bottom, 8)
        }
        .padding()
        .frame(height: 100)
        .background(wish.voted ? Color.green : Color.gray)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(.primary)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}


#Preview {
    let uuid = UUID().uuidString
    let wish = Wish(id: uuid, title: "Test Wish", content: "Test Content", createdAt: Date(), voteCount: 0, createdBy: uuid)
    WishView(wish: wish)
}
