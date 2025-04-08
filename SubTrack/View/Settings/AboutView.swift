//
//  AboutView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/1.
//
import SwiftUI


struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .center, spacing: 12) {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    
                    Text("SubTrack")
                        .font(.title.bold())
                    
                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section(header: Text("Developer")) {
                Link(destination: URL(string: "https://github.com/yourusername")!) {
                    Label("GitHub", systemImage: "link")
                }
                
                Link(destination: URL(string: "mailto:your.email@example.com")!) {
                    Label("Contact", systemImage: "envelope")
                }
            }
            
            Section(header: Text("Acknowledgements")) {
                NavigationLink {
                    List {
                        Text("SwiftUI")
                        Text("SwiftData")
                        // Add more libraries/frameworks
                    }
                    .navigationTitle("Libraries")
                } label: {
                    Text("Third-Party Libraries")
                }
            }
        }
        .navigationTitle("About")
    }
}
