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

    @State private var currencies: [CurrencyInfo] = []
    
    // UI States
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Form states
    @State private var name: String = ""
    @State private var price: Decimal = 0
    @State private var billingCycle: BillingCycle = .monthly
    @State private var firstBillingDate: Date = Date()
    @State private var colorHex: String = "#3E80F7"
    @State private var icon: String = "creditcard"
    @State private var selectedCurrency: String = Locale.current.currency!.identifier
    @State private var showCurrencyPicker: Bool = false
    
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
            Form {
                basicInfoSection
                
                colorSelectionSection
                
                iconSelectionSection
                
                billingInfoSection

            }
        }
        .navigationTitle("Add Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showCurrencyPicker) {
            CurrencyPickerView(currencies: $currencies, onSelect: { currency in
                selectedCurrency = currency.code
            })
        }
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
            currencies = CurrencyInfo.loadAvailableCurrencies()
        }
    }
    
    private var basicInfoSection: some View {
        Section {
            VStack {
                TextField("Name", text: $name)
                    .autocorrectionDisabled()

                HStack {
                    let hasDecimal = currencyHasDecimals(code: selectedCurrency)
                    let formatStyle: Decimal.FormatStyle.Currency = hasDecimal ? .currency(code: selectedCurrency) : .currency(code: selectedCurrency).precision(.fractionLength(0))
                    TextField("Price", value: $price, format: formatStyle)
                        .keyboardType(.decimalPad)
                        .onChange(of: price) { oldValue, newValue in
                            if oldValue ==  0 {
                                price = newValue
                            }
                        }
                    Spacer()
                    Button {
                        showCurrencyPicker = true
                    } label: {
                        HStack {
                            Text("\(selectedCurrency)")
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }.foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Subscription Info")
        }
    }
    
    private var colorSelectionSection: some View {
        Section {
            colorSelectionScrollView
        } header: {
            Text("Color")
        }
    }
    
    private var iconSelectionSection: some View {
        Section {
            Picker("icon", selection: $icon) {
                ForEach(iconOptions, id: \.image) { icon in
                    HStack {
                        Text(icon.name)
                        Spacer()
                        Image(systemName: icon.image).tag(icon.name)
                    }
                }
            }
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
    
    // Helper function
    private func currencyHasDecimals(code: String) -> Bool {
        let nonDecimal: Set<String> = ["TWD"]
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return nonDecimal.contains(code) ? false : formatter.minimumFractionDigits > 0
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
