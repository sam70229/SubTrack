//
//  AnalyticsView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/7.
//
import SwiftUI
import FamilyControls
import DeviceActivity


extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
    static let barGraph = Self("Bar Graph")
}


struct AnalyticsView: View {
    @EnvironmentObject var appUsageManager: AppUsageManager
    @EnvironmentObject var appSettings: AppSettings
    
    private let thisWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
    
    @State private var isDiscouragedPresented = false
    @State private var isEncouragedPresented = false
    
    @State private var context: DeviceActivityReport.Context = .totalActivity
    @State private var filter = DeviceActivityFilter(segment: .daily(during: Calendar.current.dateInterval(of: .weekOfYear, for: Date())!), applications: [])
    
    var body: some View {
        VStack {

            DeviceActivityReport(context, filter: filter)
                    .frame(maxHeight: .infinity)

        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .familyActivityPicker(isPresented: $isEncouragedPresented, selection: $appUsageManager.selection).onChange(of: appUsageManager.selection, { oldValue, newValue in
            // Set to filter
            filter.applications = newValue.applicationTokens
            
            // Save to @AppStorage
            if let selection = try? JSONEncoder().encode(newValue) {
                appSettings.appSelection = selection
            }
        })
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isEncouragedPresented = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .padding()
        .onAppear {
            // Load from @AppStorage
            if let loadedSelection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: appSettings.appSelection) {
                appUsageManager.selection = loadedSelection
                
                // Set to filter
                filter.applications = loadedSelection.applicationTokens
            }
        }
    }
}
