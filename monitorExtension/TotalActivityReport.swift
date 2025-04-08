//
//  TotalActivityReport.swift
//  monitorExtension
//
//  Created by Sam on 2025/4/7.
//
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
    static let barGraph = Self("Bar Graph")
}

struct TotalActivityReport: DeviceActivityReportScene {
    // Define which context your scene will represent.
    let context: DeviceActivityReport.Context = .totalActivity
    
    // Define the custom configuration and the resulting view for this report.
    let content: (TotalActivityView.Configuration) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityView.Configuration {
        // Reformat the data into a configuration that can be used to create
        // the report's view.

        var appUsage: [Application:TimeInterval] = [:]
        let selection = FamilyActivitySelection()
        
        for await d in data {
            for await segment in d.activitySegments {
                for await category in segment.categories {
                    for await applications in category.applications {
                        appUsage[applications.application] = applications.totalActivityDuration
                    }
                }
            }
        }
        
        return TotalActivityView.Configuration(totalUsageByApp: appUsage)
        
        
        // Use safe unwrapping and provide default values
//        let formatter = DateComponentsFormatter()
//        formatter.allowedUnits = [.day, .hour, .minute, .second]
//        formatter.unitsStyle = .abbreviated
//        formatter.zeroFormattingBehavior = .dropAll
//        
//        let totalActivityDuration = await data.flatMap { $0.activitySegments }.reduce(0, {
//            $0 + $1.totalActivityDuration
//        })
//        if let userDefaults = UserDefaults(suiteName: "group.com.sam.subtrack.monitor") {
//            userDefaults.set(totalActivityDuration, forKey: "totalActivityDuration")
//        } else {
//            print("Error: Could not access shared UserDefaults")
//        }
//
//        return formatter.string(from: totalActivityDuration) ?? "No activity data"
    }
}
