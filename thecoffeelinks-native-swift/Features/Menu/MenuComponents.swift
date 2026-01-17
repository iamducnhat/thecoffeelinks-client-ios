//
//  MenuComponents.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

// MARK: - Product Detail Sheet

private struct ProductOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}


struct ProductDetailSheet: View {
    let product: Product
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var menuViewModel: MenuViewModel
    
    @State private var quantity = 1
    @State private var selectedSize: ProductSize = .medium
    @State private var selectedToppings: Set<String> = []
    @State private var notes: String = ""
    @State private var sugarLevel: SugarLevel = .full
    @State private var iceLevel: IceLevel = .normal
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            // Fixed Navigation Header (Overlay)
            HStack(alignment: .center, spacing: AppLayout.spacing) {
                // Hidden title placeholder for alignment
                Text(product.name)
                    .font(AppFont.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(Color.textInk)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(min(1.0, max(scrollOffset - 40, 0.0) / 20.0)) // Fade in title
                    .hidden()
                
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(AppFont.navIcon)
                        .foregroundStyle(Color.textInk)
                        .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                        .background {
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .fill(Color.backgroundPaper)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.textInk, lineWidth: min(66.6, max(scrollOffset, 0.0)) / 66.6)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
            }
            .frame(minHeight: AppLayout.touchTarget)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, AppLayout.spacing)
            .zIndex(1)
            
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppLayout.spacing) {
                        // Navigation Header (Scrollable Title)
                        HStack(alignment: .center, spacing: AppLayout.spacing) {
                            Text(product.name)
                                .font(AppFont.displayTitle)
                                .foregroundStyle(Color.textInk)
                                .lineLimit(1)
                                .padding(.vertical, 24)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Hidden button placeholder for alignment
                            Button { dismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(AppFont.navIcon)
                                    .foregroundStyle(Color.textInk)
                                    .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                            }
                            .hidden()
                        }
                        .frame(minHeight: AppLayout.touchTarget)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, AppLayout.spacing)
                        .overlay(alignment: .bottom) {
                            Color.secondary.frame(height: 1, alignment: .top)
                        }
                        .background(GeometryReader {
                            Color.clear.preference(key: ProductOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ProductOffsetKey.self) {
                            self.scrollOffset = $0
                        }
                        .padding(.bottom, -AppLayout.spacing)
                        
                        // Image Section
                        if let imageUrl = product.displayImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } else {
                                    Color.surfaceCard
                                }
                            }
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                            .background(Color.surfaceCard)
                        }
                        
                        // Metadata Section
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            HStack {
                                Text("Price")
                                    .font(AppFont.uiCaption)
                                    .foregroundStyle(Color.textMuted)
                                Spacer()
                                Text(calculateTotal().formattedCurrency)
                                    .font(AppFont.monoBody.bold())
                                    .foregroundStyle(Color.primaryEspresso)
                            }
                            
                            if let description = product.description {
                                Text(description)
                                    .font(AppFont.body)
                                    .foregroundColor(Color.textInk)
                            }
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        
                        Divider().hidden()
                        
                        // Size Selection
                        if product.sizeOptions.count > 1 {
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("Size")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
                                HStack(spacing: AppLayout.spacingMedium) {
                                    ForEach(product.sizeOptions, id: \.size) { option in
                                        Button {
                                            selectedSize = option.size
                                        } label: {
                                            VStack(spacing: 4) {
                                                Text(option.size.displayName)
                                                    .font(AppFont.monoBody)
                                                Text(option.price.formattedCurrency)
                                                    .font(AppFont.uiMicro)
                                            }
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedSize == option.size ? Color.accentColor : Color.backgroundPaper)
                                            .foregroundColor(selectedSize == option.size ? Color.backgroundPaper : Color.textInk)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                                    .stroke(selectedSize == option.size ? Color.accentColor : Color.border, lineWidth: 1)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppLayout.spacing)
                        }
                        
                        Divider().hidden()
                        
                        // Toppings
                        if !product.availableToppings.isEmpty {
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("Add-ons")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
                                ForEach(product.availableToppings, id: \.self) { toppingId in
                                    if let topping = menuViewModel.toppings.first(where: { $0.id == toppingId }) {
                                        Button {
                                            if selectedToppings.contains(toppingId) {
                                                selectedToppings.remove(toppingId)
                                            } else {
                                                selectedToppings.insert(toppingId)
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: selectedToppings.contains(toppingId) ? "checkmark.square.fill" : "square")
                                                    .foregroundStyle(selectedToppings.contains(toppingId) ? Color.primaryEspresso : Color.textMuted)
                                                
                                                Text(topping.name)
                                                    .font(AppFont.body)
                                                    .foregroundColor(Color.textInk)
                                                
                                                Spacer()
                                                
                                                Text("+\(topping.price.formattedCurrency)")
                                                    .font(AppFont.monoBody)
                                                    .foregroundStyle(Color.primaryEspresso)
                                            }
                                            .padding(AppLayout.spacing)
                                            .background(Color.surfaceCard)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                                    .stroke(Color.border, lineWidth: 1)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppLayout.spacing)
                        }
                        
                        Divider().hidden()
                        
                        // Special Instructions
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Special instructions")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            TextField("Anything else we should know?", text: $notes, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(AppFont.body)
                                .padding(AppLayout.spacing)
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                }
                                .lineLimit(2...4)
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        
                        Divider().hidden()
                        
                        // Quantity
                        HStack {
//                            Text("Quantity")
//                                .font(AppFont.body)
//                                .foregroundStyle(Color.textInk)
//                            
                            Spacer()
//
                            ReceiptQuantityStepper(
                                quantity: quantity,
                                onDecrease: { if quantity > 1 { quantity -= 1 } },
                                onIncrease: { if quantity < 10 { quantity += 1 } }
                            )
                            Spacer()
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        
                        Spacer(minLength: 140)
                    }
                    //.padding(.top, AppLayout.spacing)
                }
                .coordinateSpace(name: "scroll")
                
                // Total Bar
                ReceiptTotalBar(
                    totalLabel: "TOTAL",
                    totalValue: (calculateTotal() * Double(quantity)).formattedCurrency,
                    ctaTitle: "Add to Cart",
                    action: {
                        let allToppings = menuViewModel.toppings
                        let toppingSelections = allToppings.filter { selectedToppings.contains($0.id) }.map {
                            ToppingSelection(id: $0.id, name: $0.name, price: $0.price, quantity: 1)
                        }
                        
                        let customization = OrderCustomization(
                            size: selectedSize,
                            sugar: sugarLevel,
                            ice: iceLevel,
                            toppings: toppingSelections,
                            notes: notes.isEmpty ? nil : notes
                        )
                        cartViewModel.addItem(product: product, quantity: quantity, customization: customization)
                        dismiss()
                    }
                )
            }
        }
    }
    
    private func calculateTotal() -> Double {
        var total = product.price(for: selectedSize)
        let toppings = menuViewModel.toppings
        for toppingId in selectedToppings {
            if let topping = toppings.first(where: { $0.id == toppingId }) {
                total += topping.price
            }
        }
        return total
    }
}
