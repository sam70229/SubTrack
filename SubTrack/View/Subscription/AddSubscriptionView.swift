//
//  AddSubscriptionView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI


struct AddSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var subscriptionViewModel: SubscriptionViewModel = .init(dataSource: .shared)
    
    
    private let iconOptions = [
        "creditcard", "play.tv", "music.note", "gamecontroller", "book.closed",
        "newspaper", "film", "cloud", "network", "phone", "desktopcomputer",
        "antenna.radiowaves.left.and.right", "car", "fork.knife", "hammer",
        "briefcase", "house", "gift", "person.2", "heart", "bell"
    ]
    
    struct ColorOption: Identifiable {
        let id = UUID()
        let name: String
        let hex: String
        
        // If you need to access the color directly
        var color: Color {
            Color(hex: hex) ?? .blue
        }
    }
    
    // Define the color options as a collection of ColorOption objects
    private let colorOptions: [ColorOption] = [
        ColorOption(name: "Blue", hex: "#3E80F7"),
        ColorOption(name: "Red", hex: "#FF3B30"),
        ColorOption(name: "Green", hex: "#34C759"),
        ColorOption(name: "Purple", hex: "#AF52DE"),
        ColorOption(name: "Orange", hex: "#FF9500"),
        ColorOption(name: "Pink", hex: "#FF2D55"),
        ColorOption(name: "Yellow", hex: "#FFCC00"),
        ColorOption(name: "Teal", hex: "#5AC8FA")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Form {
                    Section {
                        VStack {
                            TextField("Name", text: $subscriptionViewModel.name)
                                .autocorrectionDisabled()
                            
                            HStack {
                                TextField("Price", value: $subscriptionViewModel.price, format: .currency(code: "TWD").precision(.fractionLength(0)))
                                    .keyboardType(.decimalPad)
                            }
                        }
                    } header: {
                        Text("Details")
                    }
                    
                    colorSelectionSection
                    
                    billingInfoSection
                    
                }
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Button("Add") {
                        saveSubscription()
                    }
                    .bold()
                    .disabled(subscriptionViewModel.name.isEmpty || subscriptionViewModel.price == 0 || subscriptionViewModel.isLoading)
                }
                .padding()
            }
        }
        .navigationTitle("Add Subscription")
        .disabled(subscriptionViewModel.isLoading)
        .overlay {
            if subscriptionViewModel.isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
            }
        }
        .alert(
            "Error",
            isPresented: Binding<Bool>(
                get: { subscriptionViewModel.errorMessage != nil },
                set: { if !$0 { subscriptionViewModel.errorMessage = nil } }),
            actions: {
                
            },
            message: {Text("\(subscriptionViewModel.errorMessage ?? "")")}
        )
        
    }
    
    private var colorSelectionSection: some View {
        Section {
            colorSelectionScrollView
        } header: {
            Text("Color")
        }
    }
    
    private var billingInfoSection: some View {
        Section {
            Picker("Billing Cycle", selection: $subscriptionViewModel.billingCycle) {
                ForEach(BillingCycle.allCases) { cycle in
                    Text(cycle.description).tag(cycle)
                }
            }
            .pickerStyle(.navigationLink)
            
            DatePicker("First Billing Date",
                      selection: $subscriptionViewModel.firstBillingDate,
                      displayedComponents: .date)
        } header: {
            Text("Billing Information")
        }
    }
    
    // Break out the ScrollView into its own computed property
    private var colorSelectionScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            colorOptionsRow
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .padding(.horizontal, -20)
    }
    
    // Break out the row of color options
    private var colorOptionsRow: some View {
        HStack(spacing: 12) {
            ForEach(colorOptions, id: \.name) { colorOption in
                colorButton(for: colorOption)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Create a function that returns a view for each color button
    private func colorButton(for colorOption: ColorOption) -> some View {
        Button {
            subscriptionViewModel.colorHex = colorOption.hex
        } label: {
            colorCircle(for: colorOption)
        }
    }
    
    // Create a function that returns the color circle view
    private func colorCircle(for colorOption: ColorOption) -> some View {
        let isSelected = subscriptionViewModel.colorHex == colorOption.hex
        
        return Circle()
            .fill(Color(hex: colorOption.hex) ?? .blue)
            .frame(width: 32, height: 32)
            .overlay(
                Circle()
                    .strokeBorder(isSelected ? .primary : .tertiary, lineWidth: 2)
                    .padding(2)
            )
    }
    
    private func saveSubscription() {
        if subscriptionViewModel.price < 0 {
            subscriptionViewModel.errorMessage = "Please enter a valid price"
            return
        }
        
        subscriptionViewModel.isLoading = true
        let subscription = Subscription(
            name: subscriptionViewModel.name,
            price: subscriptionViewModel.price,
            billingCycle: subscriptionViewModel.billingCycle,
            firstBillingDate: subscriptionViewModel.firstBillingDate,
            icon: subscriptionViewModel.icon,
            colorHex: subscriptionViewModel.colorHex
        )
        
        subscriptionViewModel.addSubscription(subscription)
        subscriptionViewModel.isLoading = false
        dismiss()
    }
}

#Preview {
    AddSubscriptionView()
}
