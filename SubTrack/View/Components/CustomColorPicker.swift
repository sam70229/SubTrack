//
//  ColorPicker.swift
//  SubTrack
//
//  Created by Sam on 2025/4/14.
//
import SwiftUI


struct CustomColorPicker: View {
    let colorOptions: [ColorOption]
    
    @Binding var selectedColorOptions: [ColorOption]
    
    var limit: Int? = nil
    
    var body: some View {
        colorSelectionScrollView
    }
    
    private var colorSelectionScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            colorOptionsRow
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .padding(.horizontal, 8)
        .disabled(limit != nil && selectedColorOptions.count == limit!)
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
        let newColorOption = ColorOption(name: colorOption.name, hex: colorOption.hex)
        return Button {
            if limit != nil {
                if selectedColorOptions.count < limit! {
                    selectedColorOptions.append(newColorOption)
                }
            } else {
                selectedColorOptions.append(newColorOption)
            }
            
        } label: {
            colorCircle(for: colorOption)
        }
    }
    
    // Create a function that returns the color circle view
    private func colorCircle(for colorOption: ColorOption) -> some View {
        let isSelected = selectedColorOptions.contains { option in
            return colorOption.name == option.name
        }
        
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
    
}

struct ColorButton: View {
    let color: ColorOption
    let onClick: (ColorOption) -> Void
    
    var body: some View {
        Button {
            onClick(color)
        } label: {
            colorCircle(for: color)
        }
    }
    
    private func colorCircle(for colorOption: ColorOption) -> some View {
        return Circle()
            .fill(Color(hex: color.hex) ?? .blue)
            .frame(width: 32, height: 32)
            .padding(4)
            .overlay(
                Circle()
                    .strokeBorder(.primary)
                    .padding(1)
            )
    }
}

#Preview {
    @Previewable @State var selectedColors: [ColorOption] = []
    let colorOptions: [ColorOption] = ColorOption.generateColors()
    CustomColorPicker(colorOptions: colorOptions, selectedColorOptions: $selectedColors)
}
