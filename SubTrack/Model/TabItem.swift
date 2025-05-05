//
//  TabItem.swift
//  SubTrack
//
//  Created by Sam on 2025/4/21.
//


struct TabItem: Codable, Hashable, Identifiable {
    var id: Int
    var isEnabled: Bool
    var title: String
    var icon: String
    
    static let defaultTabs = [
        TabItem(id: 0, isEnabled: true, title: "Calendar", icon: "calendar"),
        TabItem(id: 1, isEnabled: true, title: "Subscriptions", icon: "list.bullet"),
        TabItem(id: 2, isEnabled: true, title: "Analytics", icon: "chart.bar"),
        TabItem(id: 3, isEnabled: false, title: "Wish Wall", icon: "star.fill"),
        TabItem(id: 4, isEnabled: true, title: "Settings", icon: "gear")
    ]
        
}
