//
//  AddSubscriptionView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI

enum PickerDestination {
    case currencyPicker
    case creditCardPicker
}


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
    @State private var pickerDestination: PickerDestination?

    // Form states
    @State private var name: String = ""
    @State private var priceString = ""
    @State private var price: Decimal = 0
    @State private var billingCycle: BillingCycle = .monthly
    @State private var firstBillingDate: Date = Date()
    @State private var selectedColorOptions: [ColorOption] = []
    @State private var icon: String = "creditcard"
    @State private var selectedCurrency: CurrencyInfo = CurrencyInfo(
        id: Locale.current.currency?.identifier ?? "USD",
        code: Locale.current.currency?.identifier ?? "USD",
        symbol: Locale.current.currencySymbol ?? "$",
        name: Locale.current.localizedString(forCurrencyCode: Locale.current.currency?.identifier ?? "USD") ?? Locale.current.currency?.identifier ?? "USD",
        exampleFormatted: "1234.56"
    )
    @State private var showPicker: Bool = false
    
    // Credit Card Section
    @State private var recordCreditCard: Bool = false
    @State private var creditCard: CreditCard? = nil
    
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
    private let colorOptions: [ColorOption] = ColorOption.generateColors()
    
    var body: some View {
        
        VStack(spacing: 20) {
            Form {
                basicInfoSection
                
                colorSelectionSection
                
                iconSelectionSection
                
                billingInfoSection
                   
                creditCardSection
            }
            .presentationSizing(.fitted)
            
        }
        .navigationTitle("Add Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showPicker) {
            switch pickerDestination {
            case .currencyPicker:
                CurrencyPickerView(currencies: $currencies, onSelect: { currency in
                    selectedCurrency = currency
                })
                
            case .creditCardPicker:
                CreditCardListView { card in
                    print(card)
                    creditCard = card
                }
            case .none:
                EmptyView()
            }
            
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
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        Section {
            VStack {
                TextField("Name", text: $name)
                    .autocorrectionDisabled()

                HStack {
                    let hasDecimal = CurrencyInfo.hasDecimals(selectedCurrency.code)
                    let formatStyle: Decimal.FormatStyle.Currency = hasDecimal ? .currency(code: selectedCurrency.code) : .currency(code: selectedCurrency.code).precision(.fractionLength(0))
                    Text(selectedCurrency.symbol)
                    TextField("Price", text: $priceString)
                        .keyboardType(hasDecimal ? .decimalPad : .numberPad)
                        .onChange(of: priceString) { _, newValue in
                            self.price = (try? Decimal(newValue, format: formatStyle)) ?? 0
                        }
                        

                    Spacer()
                    Button {
                        showPicker = true
                        pickerDestination = .currencyPicker
                    } label: {
                        HStack {
                            Text("\(selectedCurrency.code)")
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
            CustomColorPicker(colorOptions: colorOptions, selectedColorOptions: $selectedColorOptions, limit: 1)
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
    
    private var creditCardSection: some View {
        Section {
            Toggle("Record Credit Card Info", isOn: $recordCreditCard)
            
            if recordCreditCard {
                HStack {
                    if creditCard == nil {
                        Text("Pick a card")
                    } else {
                        CreditCardView(card: creditCard!)
                            .frame(width: 300, height: 200)
                    }
                    Spacer()
                    Button {
                        showPicker = true
                        pickerDestination = .creditCardPicker
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                
                .alignmentGuide(.top) { dimension in
                    dimension[.top] -  (creditCard == nil ? 100 : 0)
                }
            }
        }
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
            currencyCode: selectedCurrency.code,
            billingCycle: billingCycle,
            firstBillingDate: firstBillingDate,
            creditCard: creditCard,
            icon: icon,
            colorHex: selectedColorOptions.first?.hex ?? "#3E80F7",
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
    
    
    //MARK: - Helper function
    private var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency.code
        formatter.maximumFractionDigits = CurrencyInfo.hasDecimals(selectedCurrency.code) ? 2 : 0
        formatter.minimumFractionDigits = CurrencyInfo.hasDecimals(selectedCurrency.code) ? 2 : 0
        return formatter
    }
}

#Preview {
    AddSubscriptionView()
}
