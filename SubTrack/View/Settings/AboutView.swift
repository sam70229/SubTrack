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
                    Bundle.main.appIcon.flatMap { UIImage(named: $0) }.map { Image(uiImage: $0) }?
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                    
                    
                    Text("SubTrack")
                        .font(.title.bold())
                    
                    Text("Version \(Bundle.main.versionNumber)")
                        .foregroundColor(.secondary)
                    
                    Text("Build \(Bundle.main.buildNumber)")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section(header: Text("Developer")) {
                Link(destination: URL(string: "https://github.com/sam70229")!) {
                    Label("GitHub", systemImage: "link")
                }
                
                Link(destination: URL(string: "mailto:sam70229@gmail.com")!) {
                    Label("Contact Me", systemImage: "envelope")
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
