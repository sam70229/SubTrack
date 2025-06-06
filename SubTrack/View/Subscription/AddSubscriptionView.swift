//
//  AddSubscriptionView.swift
//  SubTrack
//
//  Created by Sam on 2025/3/17.
//
import SwiftUI

enum PickerDestination {
    case currencyPicker
    case iconPicker
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
    @State private var period: Period = .monthly
    @State private var firstBillingDate: Date = Date()
    @State private var selectedColorOption: ColorOption = .init(name: "Blue", hex: Color.blue.toHexString())
    @State private var selectedIcon: IconOption = IconOption.defaultIconOptions[0]
    @State private var selectedCurrency: CurrencyInfo = CurrencyInfo(
        id: Locale.current.currency?.identifier ?? "USD",
        code: Locale.current.currency?.identifier ?? "USD",
        symbol: Locale.current.currencySymbol ?? "$",
        name: Locale.current.localizedString(forCurrencyCode: Locale.current.currency?.identifier ?? "USD") ?? Locale.current.currency?.identifier ?? "USD",
        exampleFormatted: "1234.56"
    )
    @State private var hasInitialPrice: Bool = false

    @State private var showPicker: Bool = false
    
    // Credit Card Section
    @State private var recordCreditCard: Bool = false
    @State private var creditCard: CreditCard? = nil
    
    // Tags Section
    @State private var showTagsSheet: Bool = false
    @State private var selectedTags: [Tag] = []

    // Define the color options as a collection of ColorOption objects
    private let colorOptions: [ColorOption] = ColorOption.generateColors()
    
    var body: some View {
        
        VStack(spacing: 20) {
            Form {
                basicInfoSection
                
                colorSelectionSection
                
                iconSelectionSection
                
                tagSelection
                
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
            case .iconPicker:
                IconPickerView(selectedIcon: $selectedIcon)
            case .creditCardPicker:
                CreditCardListView { card in
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
        .sheet(isPresented: $showTagsSheet) {
            NavigationStack {
                TagsView(selectedTags: $selectedTags)
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

            if currencies.isEmpty {
                currencies = CurrencyInfo.loadAvailableCurrencies()
            }

            if !hasInitialPrice {
                if let systemCurrency = CurrencyInfo.loadAvailableCurrencies().filter({ $0.code ==  appSettings.currencyCode }).first {
                    selectedCurrency = systemCurrency
                }
                hasInitialPrice = true
            }
        }
    }
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        Section {

            TextField("Name", text: $name)
                .autocorrectionDisabled()
                .submitLabel(.continue)
            
            HStack {
                let hasDecimal = CurrencyInfo.hasDecimals(selectedCurrency.code)
                let formatStyle: Decimal.FormatStyle.Currency = hasDecimal ? .currency(code: selectedCurrency.code) : .currency(code: selectedCurrency.code).precision(.fractionLength(0))
                Text(selectedCurrency.symbol)
                TextField("Price", text: $priceString)
                    .keyboardType(hasDecimal ? .decimalPad : .numberPad)
                    .onChange(of: priceString) { _, newValue in
                        self.price = (try? Decimal(newValue, format: formatStyle)) ?? 0
                    }
                    .keyboardDoneButton()
                
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
        } header: {
            Text("Subscription Info")
        }
    }
    
    private var colorSelectionSection: some View {
        Section {
            ScrollView(.horizontal,showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colorOptions, id:\.name) { colorOption in
                        colorButton(for: colorOption)
                    }
                }
            }
        } header: {
            Text("Color")
        }
    }
    
    private func colorButton(for colorOption: ColorOption) -> some View {
        return Button {
            selectedColorOption = colorOption
        } label: {
            colorCircle(for: colorOption)
        }
    }

    // Create a function that returns the color circle view
    private func colorCircle(for colorOption: ColorOption) -> some View {
        let isSelected = selectedColorOption == colorOption

        return Circle()
            .fill(Color(hex: colorOption.hex) ?? .blue)
            .frame(width: 32, height: 32)
            .padding(4)
            .overlay(
                Circle()
                    .strokeBorder(isSelected ? .primary : .tertiary, lineWidth: 2)
                    .padding(1)
            )
    }
    
    private var iconSelectionSection: some View {
        Section {
            Button {
                showPicker = true
                pickerDestination = .iconPicker
            } label: {
                HStack {
                    Text("Icon")
                    Spacer()
                    Text("\(selectedIcon.name)")
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }.foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

//            Picker("icon", selection: $icon) {
//                ForEach(IconOption.defaultIconOptions, id: \.image) { icon in
//                    HStack {
//                        Text(LocalizedStringKey(icon.name))
//                        Spacer()
//                        Image(systemName: icon.image).tag(icon.name)
//                    }
//                }
//            }
        }
    }
    
    private var tagSelection: some View {
        Section {
            HStack {
                
                Image(systemName: "number")
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray)
                            .padding(-6)
                    )
                    .foregroundStyle(.white)
                
                Text("Tags")
                    .padding(.horizontal, 8)
                
                Spacer()

                Button{
                    showTagsSheet = true
                } label: {
                    HStack {
                        if !selectedTags.isEmpty {
                            Text(selectedTags.map{ $0.name }.joined(separator: ", "))
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                }.foregroundColor(.secondary)
            }
        }
    }
    
    private var billingInfoSection: some View {
        Section {
            Picker("Period", selection: $period) {
                ForEach(Period.allCases) { cycle in
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
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                
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
            period: period,
            firstBillingDate: firstBillingDate,
            tags: selectedTags,
            creditCard: creditCard,
            icon: selectedIcon.image,
            colorHex: selectedColorOption.hex,
        )
        
        do {
            try repository?.addSubscription(subscription)
            
            // Notification
            if subscription.isNotificationEnabled {
                Task {
                    
                    await subscription.scheduleNotifications()
                }
            }
            
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
    NavigationStack {
        AddSubscriptionView()
            .environmentObject(AppSettings())
    }
}
