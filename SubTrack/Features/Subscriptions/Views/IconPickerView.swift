//
//  IconPickerView.swift
//  SubTrack
//
//  Created by Sam on 2025/5/23.
//
import SwiftUI


struct IconPickerView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @Binding var selectedIcon: IconOption
    @Environment(\.dismiss) private var dismiss
    
    let categories = ["All", "Entertainment", "Tech", "Food", "Health", "Lifestyle", "Other"]
    
    var filteredIcons: [IconOption] {
        let icons: [IconOption]
        
        switch selectedCategory {
        case "Entertainment":
            icons = IconOption.entertainmentIcons
        case "Tech":
            icons = IconOption.techIcons
        case "Food":
            icons = IconOption.foodIcons
        case "Health":
            icons = IconOption.healthIcons
        case "Lifestyle":
            icons = IconOption.lifestyleIcons
        case "All":
            icons = IconOption.defaultIconOptions
        default:
            icons = IconOption.defaultIconOptions
        }
        
        return icons.search(query: searchText)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search icons", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .font(.caption)
                                    .fontWeight(selectedCategory == category ? .semibold : .regular)
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == category ? Color.accentColor : Color(.systemGray5))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Icon Grid
                iconGrid
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var iconGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80))
            ], spacing: 20) {
                ForEach(filteredIcons) { icon in
                    Button(action: {
                        selectedIcon = icon
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: icon.image)
                                .font(.title)
                                .foregroundColor(selectedIcon.image == icon.image ? .white : .primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIcon.image == icon.image ? Color.accentColor : Color(.systemGray5))
                                )
                            
                            Text(icon.name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}
