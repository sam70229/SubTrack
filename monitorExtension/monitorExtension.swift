//
//  monitorExtension.swift
//  monitorExtension
//
//  Created by Sam on 2025/4/7.
//

import DeviceActivity
import SwiftUI

@main
struct monitorExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { configuration in
            TotalActivityView(configuration: configuration)
        }
        // Add more reports here...
    }
}


class Monitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
    }
}
