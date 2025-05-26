//
//  IconOption.swift
//  SubTrack
//
//  Created by Sam on 2025/4/2.
//
import SwiftUI


struct IconOption: Identifiable {
    let id = UUID()
    let name: String
    let image: String

    static let defaultIconOptions = [
        // Entertainment & Media
        IconOption(name: "Music", image: "music.note"),
        IconOption(name: "Streaming", image: "tv"),
        IconOption(name: "Movies", image: "film"),
        IconOption(name: "Podcasts", image: "mic.circle"),
        IconOption(name: "Gaming", image: "gamecontroller"),
        IconOption(name: "Books", image: "book.closed"),
        IconOption(name: "News", image: "newspaper"),
        IconOption(name: "Magazines", image: "book.pages"),
        
        // Technology & Software
        IconOption(name: "Cloud Storage", image: "cloud"),
        IconOption(name: "Software", image: "desktopcomputer"),
        IconOption(name: "Mobile Apps", image: "apps.iphone"),
        IconOption(name: "VPN", image: "lock.shield"),
        IconOption(name: "Security", image: "shield.checkered"),
        IconOption(name: "AI Tools", image: "brain"),
        IconOption(name: "Developer Tools", image: "hammer"),
        
        // Food & Beverages
        IconOption(name: "Food Delivery", image: "takeoutbag.and.cup.and.straw"),
        IconOption(name: "Meal Kits", image: "fork.knife"),
        IconOption(name: "Coffee", image: "cup.and.saucer"),
        IconOption(name: "Wine", image: "wineglass"),
        IconOption(name: "Groceries", image: "cart"),
        IconOption(name: "Snacks", image: "birthday.cake"),
        
        // Health & Fitness
        IconOption(name: "Fitness", image: "figure.run"),
        IconOption(name: "Gym", image: "dumbbell"),
        IconOption(name: "Meditation", image: "brain.head.profile"),
        IconOption(name: "Healthcare", image: "heart.text.square"),
        IconOption(name: "Vitamins", image: "pills"),
        IconOption(name: "Mental Health", image: "person.2.wave.2"),
        IconOption(name: "Nutrition", image: "leaf"),
        
        // Lifestyle & Home
        IconOption(name: "Home", image: "house"),
        IconOption(name: "Utilities", image: "bolt.house"),
        IconOption(name: "Internet", image: "wifi"),
        IconOption(name: "Phone", image: "phone"),
        IconOption(name: "Cleaning", image: "sparkles"),
        IconOption(name: "Plants", image: "leaf.arrow.triangle.circlepath"),
        
        // Personal Care & Beauty
        IconOption(name: "Beauty", image: "sparkle"),
        IconOption(name: "Grooming", image: "scissors"),
        IconOption(name: "Skincare", image: "drop.degreesign"),
        IconOption(name: "Haircare", image: "comb"),
        IconOption(name: "Perfume", image: "humidity"),
        
        // Transportation
        IconOption(name: "Car", image: "car"),
        IconOption(name: "Parking", image: "parkingsign.circle"),
        IconOption(name: "Public Transit", image: "bus"),
        IconOption(name: "Rideshare", image: "car.side"),
        IconOption(name: "Bike Share", image: "bicycle"),
        IconOption(name: "Gas", image: "fuelpump"),
        
        // Shopping & Fashion
        IconOption(name: "Fashion", image: "tshirt"),
        IconOption(name: "Shoes", image: "shoe"),
        IconOption(name: "Accessories", image: "handbag"),
        IconOption(name: "Jewelry", image: "sparkles.rectangle.stack"),
        IconOption(name: "Shopping", image: "bag"),
        
        // Education & Learning
        IconOption(name: "Education", image: "graduationcap"),
        IconOption(name: "Language", image: "globe.americas"),
        IconOption(name: "Courses", image: "book.and.wrench"),
        IconOption(name: "Kids Learning", image: "pencil.and.outline"),
        
        // Finance & Business
        IconOption(name: "Banking", image: "banknote"),
        IconOption(name: "Investment", image: "chart.line.uptrend.xyaxis"),
        IconOption(name: "Insurance", image: "shield"),
        IconOption(name: "Accounting", image: "doc.text.magnifyingglass"),
        IconOption(name: "Credit Card", image: "creditcard"),
        
        // Pets
        IconOption(name: "Pet Supplies", image: "pawprint"),
        IconOption(name: "Pet Food", image: "dog"),
        IconOption(name: "Pet Care", image: "cat"),
        
        // Productivity & Work
        IconOption(name: "Productivity", image: "checklist"),
        IconOption(name: "Email", image: "envelope"),
        IconOption(name: "Calendar", image: "calendar"),
        IconOption(name: "Notes", image: "note.text"),
        IconOption(name: "Tasks", image: "list.bullet.rectangle"),
        
        // Photography & Design
        IconOption(name: "Photo Editing", image: "photo"),
        IconOption(name: "Design Tools", image: "paintpalette"),
        IconOption(name: "Photo Storage", image: "photo.stack"),
        IconOption(name: "Video Editing", image: "video.badge.waveform"),
        
        // Social & Dating
        IconOption(name: "Social Network", image: "person.2"),
        IconOption(name: "Dating", image: "heart.circle"),
        IconOption(name: "Professional Network", image: "person.crop.rectangle.stack"),
        
        // Sports & Hobbies
        IconOption(name: "Sports", image: "sportscourt"),
        IconOption(name: "Golf", image: "figure.golf"),
        IconOption(name: "Outdoor", image: "mountain.2"),
        IconOption(name: "Crafts", image: "paintbrush.pointed"),
        
        // Other Services
        IconOption(name: "Donations", image: "gift"),
        IconOption(name: "Membership", image: "person.crop.circle.badge.checkmark"),
        IconOption(name: "Subscription Box", image: "shippingbox"),
        IconOption(name: "Other", image: "ellipsis.circle")
    ]
    
    // Organized by category for easier access
    static let entertainmentIcons = defaultIconOptions.filter {
        ["Music", "Streaming", "Movies", "Podcasts", "Gaming", "Books", "News", "Magazines"].contains($0.name)
    }
    
    static let techIcons = defaultIconOptions.filter {
        ["Cloud Storage", "Software", "Mobile Apps", "VPN", "Security", "AI Tools", "Developer Tools"].contains($0.name)
    }
    
    static let foodIcons = defaultIconOptions.filter {
        ["Food Delivery", "Meal Kits", "Coffee", "Wine", "Groceries", "Snacks"].contains($0.name)
    }
    
    static let healthIcons = defaultIconOptions.filter {
        ["Fitness", "Gym", "Meditation", "Healthcare", "Vitamins", "Mental Health", "Nutrition"].contains($0.name)
    }
    
    static let lifestyleIcons = defaultIconOptions.filter {
        ["Home", "Utilities", "Internet", "Phone", "Cleaning", "Plants"].contains($0.name)
    }
}
