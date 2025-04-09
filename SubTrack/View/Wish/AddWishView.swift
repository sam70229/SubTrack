import SwiftUI
import Firebase
import FirebaseDatabase


struct AddWishView: View {
    @Environment(\.dismiss) private var dismiss
    private let repository = WishRepository()
    @State private var title: String = ""
    @State private var description: String = ""
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Title")
                TextField("Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            
            VStack(alignment: .leading) {
                Text("Description")
                TextField("Description", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()

            Button("Submit") {
                submitWish()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            Spacer()
        }
        .navigationTitle("Submit a Wish")
    }
    
    private func submitWish() {
        let newWish = Wish(id: UUID().uuidString, title: title, content: description, createdAt: Date(), voteCount: 0)
        
        // Save the wish to your chosen storage
        // For example, append to a list or save to a database
        print("Wish submitted: \(newWish)")
        repository.addWish(title: title, content: description)
        
    }
} 

#Preview {
    AddWishView()
}
