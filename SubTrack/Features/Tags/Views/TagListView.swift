//
//  TagListView.swift
//  SubTrack
//
//  Created by Sam on 2025/6/8.
//
import SwiftUI


struct TagListView: View {
    @EnvironmentObject private var appSettings: AppSettings
    
    @State private var searchString: String = ""
    @State private var newTag: String = ""
    @State private var isAddingTag: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var tags: [Tag] {
        if searchString.isEmpty {
            return appSettings.tags
        } else {
            return appSettings.tags.filter { $0.name.localizedCaseInsensitiveContains(searchString) }
        }
    }
    
    var body: some View {
        List {
            ForEach(tags, id: \.self) { tag in
                HStack {
                    Text("\(tag.name)")
                }
            }
            .onDelete(perform: deleteTag)
            
            if isAddingTag {
                newTagTextField
            }
        }
        .searchable(text: $searchString, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        isAddingTag = true
                        isTextFieldFocused = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private var newTagTextField: some View {
        TextField("Add a tag", text: $newTag)
            .focused($isTextFieldFocused)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.tertiary)
            )
            .padding(.horizontal, 8)
            .submitLabel(.return)
            .onSubmit(of: .text) {
                saveTag()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Cancel") {
                        cancelAddingTag()
                    }
                }
            }
    }
    
    private func saveTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTag.isEmpty else {
            cancelAddingTag()
            return
        }
        
        // Check for duplicates
        let tagName = trimmedTag.hasPrefix("#") ? trimmedTag : "#\(trimmedTag)"
        guard !appSettings.tags.contains(where: { $0.name.lowercased() == tagName.lowercased() }) else {
            // Optionally show an alert for duplicate
            cancelAddingTag()
            return
        }
        
        let tag = Tag(name: tagName)
        appSettings.tags.append(tag)
        
        // Reset state
        cancelAddingTag()
    }
    
    private func cancelAddingTag() {
        withAnimation {
            isAddingTag = false
            newTag = ""
            isTextFieldFocused = false
        }
    }
    
    private func deleteTag(at offsets: IndexSet) {
        let tagsToDelete = offsets.map { tags[$0] }
        appSettings.tags.removeAll { tag in
            tagsToDelete.contains { $0.id == tag.id }
        }
    }
}


#Preview {
    TagListView()
        .environmentObject(AppSettings())
}
