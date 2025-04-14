//
//  AddCreditCardView.swift
//  SubTrack
//
//  Created by Sam on 2025/4/14.
//
import SwiftUI
import SwiftData


struct AddCreditCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    @State private var repository: CreditCardRepository?
    
    @State private var cardName: String = ""
    @State private var cardLast4Digits: String = ""
    @State private var selectedColors: [ColorOption] = [
        ColorOption(name: "Black", hex: "#000000"),
        ColorOption(name: "Gray", hex: Color.gray.toHexString())
    ]
    
    private let colorOptions: [ColorOption] = [
        ColorOption(name: "Blue", hex: "#3E80F7"),
        ColorOption(name: "Red", hex: "#FF3B30"),
        ColorOption(name: "Green", hex: "#34C759"),
        ColorOption(name: "Purple", hex: "#AF52DE"),
        ColorOption(name: "Orange", hex: "#FF9500"),
        ColorOption(name: "Pink", hex: "#FF2D55"),
        ColorOption(name: "Yellow", hex: "#FFCC00"),
        ColorOption(name: "Teal", hex: "#5AC8FA"),
        ColorOption(name: "Black", hex: Color.black.toHexString()),
        ColorOption(name: "Gray", hex: Color.gray.toHexString()),
        ColorOption(name: "White", hex: Color.white.toHexString())
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.linearGradient(colors:
                                                selectedColors.map({ color in
                            Color(hex: color.hex)!
                        })
                                              , startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    VStack {
                        HStack {
                            Text(cardName.isEmpty ? "Card Name" : cardName)
                            Spacer()
                        }
                        
                        Spacer()
                        
                        HStack {
                            Text("**** **** **** \(cardLast4Digits.isEmpty ? "xxxx": cardLast4Digits)")
                            Spacer()
                        }
                    }
                    .padding(20)
                }
                .environment(\.colorScheme, .dark)
                .frame(height: geometry.size.height / 3)
                
                Form {
                    TextField("Card Name", text: $cardName)
                    TextField("last 4 digits", text: $cardLast4Digits)
                        .keyboardType(.numberPad)
                        .onChange(of: cardLast4Digits) { oldValue, newValue in
                            if newValue.count > 4 {
                                cardLast4Digits = oldValue
                            }
                        }

                    colorPickerSection
                    
                    selectedCardColorsSection
                }
            }
            .padding()
            .navigationTitle("Add Card")
            navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        
                    } label: {
                        Text("Add")
                    }
                }
            }
            .onAppear {
                repository = CreditCardRepository(modelContext: modelContext)
            }
        }
    }
    
    private var colorPickerSection: some View {
        Section {
            CustomColorPicker(colorOptions: colorOptions, selectedColorOptions: $selectedColors)
        } header: {
            Text("Card Color")
        }
    }
    
    private var selectedCardColorsSection: some View {
        Section {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(Array(selectedColors.enumerated()), id: \.element) { index, selectedColor in
                        ColorButton(color: selectedColor) { colorOption in
                            selectedColors.remove(at: index)
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .padding(.horizontal, 8)

            Button {
                selectedColors = [
                    ColorOption(name: "Black", hex: Color.black.toHexString()),
                    ColorOption(name: "Gray", hex: Color.gray.toHexString())
                ]
            } label: {
                Text("Reset to default")
            }
        } header: {
            Text("Selected Card Color")
        }
    }
}

#Preview {
    AddCreditCardView()
}
