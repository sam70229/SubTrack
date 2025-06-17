//
//  TagsView.swift
//  SubTrack
//
//  Created by Sam on 2025/5/5.
//
import SwiftUI
import SwiftData

struct TagsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedTags: [Tag]
    @Query var allTags: [Tag]
    
    @State private var newTag: String = ""
    
    var body: some View {

        VStack {
            if !allTags.isEmpty {
                tagsList
            }
            
            TextField("Add a tag", text: $newTag)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.tertiary)
                )
                .padding(.horizontal, 8)
                .submitLabel(.return)
                .onSubmit(of: .text) {
                    var tagName = newTag
                    if !tagName.hasPrefix("#") {
                        tagName = "#\(tagName)"
                    }
                    if !allTags.contains(where: { $0.name == tagName }) {
                        let tag = Tag(name: tagName)
                        modelContext.insert(tag)
                        selectedTags.append(tag)
                    } else if let existingTag = allTags.first(where: { $0.name == tagName }) {
                        if !selectedTags.contains(existingTag) {
                            selectedTags.append(existingTag)
                        }
                    }
                    newTag = ""
                }
            
            Spacer()
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Tags are already persisted; just dismiss
                    dismiss()
                } label: {
                    Text("Done")
                }
            }
        }
    }
    
    private var tagsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(allTags) { tag in
                    Button {
                        if !selectedTags.contains(tag) {
                            selectedTags.append(tag)
                        } else {
                            selectedTags.removeAll { $0.id == tag.id }
                        }
                    } label: {
                        Text(tag.name)
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTags.contains(tag) ? Color.blue : Color.gray)
                    )
                }
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.tertiary)
        )
        .padding(.horizontal, 8)
    }
}

#Preview {
    @Previewable @State var selectedTags: [Tag] = [Tag(name: "#Test1")]
    let container = try? ModelContainer(for: Tag.self)
    
    NavigationStack {
        TagsView(selectedTags: $selectedTags)
            .modelContainer(container!)
    }
}
