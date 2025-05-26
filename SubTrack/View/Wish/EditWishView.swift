//
//  EditWishView.swift
//  SubTrack
//
//  Created by Sam on 2025/5/26.
//
import SwiftUI


struct EditWishSheet: View {
    let wish: Wish
    @ObservedObject var viewModel: WishViewModel
    @Binding var isPresented: Bool
    
    @State private var editedTitle: String
    @State private var editedContent: String
    
    init(wish: Wish, viewModel: WishViewModel, isPresented: Binding<Bool>) {
        self.wish = wish
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._editedTitle = State(initialValue: wish.title)
        self._editedContent = State(initialValue: wish.content ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Title") {
                    TextField("Wish title", text: $editedTitle)
                }
                
                Section("Description") {
                    TextEditor(text: $editedContent)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Wish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
            }
        }
    }
    
    private func saveChanges() {
        viewModel.updateWish(wish, title: editedTitle, content: editedContent) { success in
            if success {
                isPresented = false
                // You might want to refresh the parent view here
            }
        }
    }
}
