//
//  TagsView.swift
//  SubTrack
//
//  Created by Sam on 2025/5/5.
//
import SwiftUI


struct TagsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    
    @Binding var selectedTags: [Tag]
    @State var allTags: [Tag] = []
    
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
                    print("submit")
                    if !newTag.hasPrefix("#") {
                        newTag = "#\(newTag)"
                    }
                    let tag = Tag(name: "\(newTag)")
                    allTags.append(tag)
                    appSettings.tags.append(tag)
                    selectedTags.append(tag)
                    
                    // Clear input
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
                    // SET tags to subs
                    dismiss()
                } label: {
                    Text("Done")
                }
            }
        }
        .onAppear {
            if allTags.isEmpty {
                allTags = appSettings.tags
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
                            .fill(selectedTags.contains(tag) ? Color.blue : Color(.tertiarySystemFill))
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
    NavigationStack {
        TagsView(selectedTags: $selectedTags)
            .environmentObject(AppSettings())
    }
}
