//
//  TotalActivityView.swift
//  monitorExtension
//
//  Created by Sam on 2025/4/7.
//

import SwiftUI
import ManagedSettings
import Charts

struct AppUsage: Identifiable {
    let id: String
    let app: Application
    let duration: TimeInterval
}


struct TotalActivityView: View {
    struct Configuration {
        let totalUsageByApp: [Application:TimeInterval]
    }
    
    let configuration: Configuration
    
    // data should be saved like this, either struct a model to save app name and duration, or just simply use list or smth...
    var body: some View {
        let appUsage = configuration.totalUsageByApp.map { AppUsage(id: $0.key.bundleIdentifier!, app: $0.key, duration: $0.value) }
        VStack {
            Chart {
                ForEach(appUsage) { usage in
                    BarMark(
                        x: .value("App", usage.app.localizedDisplayName!),
                        y: .value("Time", usage.duration / 3600)
                    )
                }
            }
            List {
                ForEach(appUsage.filter { $0.duration / 3600 > 0.5}) { usage in
                    HStack {
                        Text(usage.app.localizedDisplayName!)
                        Spacer()
                        Text(formatTimeInterval(usage.duration))
                    }
                }

                Section {
                    ForEach(appUsage.filter { $0.duration / 3600 < 0.5}) { usage in
                        HStack {
                            Text(usage.app.localizedDisplayName!)
                            Spacer()
                            Text(formatTimeInterval(usage.duration))
                        }
                    }
                } header: {
                    Text("Suggest to unsubscribe")
                }
            }
        }
    }
    
    private func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        var result = ""
        let hour = timeInterval / 3600
        let minute = timeInterval / 60
        
        if hour > 0 {
            result += "\(Int(hour))h "
        }
        
        result += "\(Int(minute))m"
            
        return result
    }
}

// In order to support previews for your extension's custom views, make sure its source files are
// members of your app's Xcode target as well as members of your extension's target. You can use
// Xcode's File Inspector to modify a file's Target Membership.
//#Preview {
//    TotalActivityView(totalActivity: "1h 23m")
//}
