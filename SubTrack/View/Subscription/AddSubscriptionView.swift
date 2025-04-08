//
//  AddSubscriptionView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI


struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    // Create the repository with the injected model context
    @State private var repository: SubscriptionRepository?
    
    // UI States
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Form states
    @State private var name: String = ""
    @State private var price: Decimal = 0
    @State private var billingCycle: BillingCycle = .monthly
    @State private var firstBillingDate: Date = Date()
    @State private var colorHex: String = "#3E80F7"
    @State private var icon: String = ""
    
    private let iconOptions: [IconOption] = [
        IconOption(name: "Credit Card", image: "creditcard"),
        IconOption(name: "Music", image: "music.note"),
        IconOption(name: "Gaming", image: "gamecontroller"),
        IconOption(name: "Cloud", image: "cloud"),
        IconOption(name: "Car", image: "car"),
        IconOption(name: "Streaming", image: "film"),
        IconOption(name: "Book", image: "book.closed"),
        IconOption(name: "House", image: "house"),
        IconOption(name: "News", image: "newspaper"),
    ]

//    private let iconOptions = [
//        "creditcard", "play.tv", "music.note", "gamecontroller", "book.closed",
//        "newspaper", "film", "cloud", "network", "phone", "desktopcomputer",
//        "antenna.radiowaves.left.and.right", "car", "fork.knife", "hammer",
//        "briefcase", "house", "gift", "person.2", "heart", "bell"
//    ]
    
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
        
        VStack(spacing: 20) {
//                headerSection
            Form {
                Section {
                    VStack {
                        TextField("Name", text: $name)
                            .autocorrectionDisabled()
                        
                        HStack {
                            TextField("Price", value: $price, format: .currency(code: appSettings.currencyCode).precision(.fractionLength(0)))
                                .keyboardType(.decimalPad)
                        }
                    }
                } header: {
                    Text("Subscription Info")
                }
                
                colorSelectionSection
                
                Picker("icon", selection: $icon) {
                    ForEach(iconOptions, id: \.image) { icon in
                        HStack {
                            Text(icon.name)
                            Spacer()
                            Image(systemName: icon.image).tag(icon.name)
                        }
                    }
                }
                
                billingInfoSection

            }
        }
        .navigationTitle("Add Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    saveSubscription()
                }
                .bold()
                .disabled(name.isEmpty || price == 0 || isLoading)
            }

            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
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
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }),
            actions: {
                
            },
            message: {Text("\(errorMessage ?? "")")}
        )
        .onAppear {
            // Initialize the repository with the model context
            repository = SubscriptionRepository(modelContext: modelContext)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            Spacer()
            Text("Add Subscription")
                .bold()
            Spacer()
            Button("Add") {
                saveSubscription()
            }
            .bold()
            .disabled(name.isEmpty || price == 0 || isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
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
            Picker("Billing Cycle", selection: $billingCycle) {
                ForEach(BillingCycle.allCases) { cycle in
                    Text(cycle.description).tag(cycle)
                }
            }
            .pickerStyle(.navigationLink)
            
            DatePicker("First Billing Date",
                      selection: $firstBillingDate,
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
        .padding(.horizontal, 8)
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
            colorHex = colorOption.hex
        } label: {
            colorCircle(for: colorOption)
        }
    }
    
    // Create a function that returns the color circle view
    private func colorCircle(for colorOption: ColorOption) -> some View {
        let isSelected = colorHex == colorOption.hex
        
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
        if price < 0 {
            errorMessage = "Please enter a valid price"
            return
        }
        
        isLoading = true
        let subscription = Subscription(
            name: name,
            price: price,
            billingCycle: billingCycle,
            firstBillingDate: firstBillingDate,
            icon: icon,
            colorHex: colorHex
        )
        
        do {
            try repository?.addSubscription(subscription)
            isLoading = false
            dismiss()
        } catch {
            errorMessage = "Failed to save subscription"
            isLoading = false
        }
    }
}

#Preview {
    AddSubscriptionView()
}


extension AddSubscriptionView {
    @Observable
    class ViewModel {
        
    }
}
