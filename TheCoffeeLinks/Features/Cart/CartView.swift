//
//  CartView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CachedAsyncImage // CHANGED

struct CartView: View {
    @EnvironmentObject private var cartViewModel: CartViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCheckout = false
    @State private var editingItem: CartItem?
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            if cartViewModel.isEmpty {
                EmptyCartView(onBrowse: { dismiss() })
            } else {
                // Fixed Navigation Header
                HStack(alignment: .center, spacing: AppLayout.spacing) {
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
                    
                    Text(LocalizedStringKey("Cart (\(cartViewModel.itemCount))"))
                        .font(AppFont.displayTitle)
                        .lineLimit(1)
                        .foregroundStyle(Color.textInk)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .hidden()
                }
                .frame(minHeight: AppLayout.touchTarget)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, AppLayout.spacing)
                
                VStack(spacing: 0) {
                    ScrollView(.vertical) {
                        // Navigation Header (Scrollable)
                        HStack(alignment: .center, spacing: AppLayout.spacing) {
                            Image(systemName: "xmark")
                                .font(AppFont.navIcon)
                                .foregroundStyle(Color.textInk)
                                .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                                .hidden()
                            
                            Text(LocalizedStringKey("Cart (\(cartViewModel.itemCount))"))
                                .font(AppFont.displayTitle)
                                .lineLimit(1)
                                .foregroundStyle(Color.textInk)
                                .padding(.vertical, 24)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: AppLayout.touchTarget)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, AppLayout.spacing)
                        .overlay(alignment: .bottom) {
                            Color.secondary.frame(height: 1, alignment: .top)
                        }
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) {
                            self.scrollOffset = $0
                        }
                        
                        LazyVStack(spacing: AppLayout.spacing) {
                            // MARK: Cart Items
                            ForEach(cartViewModel.cart.items) { item in
                                CartItemRow(
                                    item: item,
                                    onUpdateQuantity: { qty in
                                        if qty > 0 {
                                            cartViewModel.updateQuantity(for: item.id, delta: qty - item.quantity)
                                        } else {
                                            cartViewModel.removeItem(item.id)
                                        }
                                    },
                                    onRemove: {
                                        cartViewModel.removeItem(item.id)
                                    },
                                    onEdit: {
                                        editingItem = item
                                    }
                                )
                                
                                Divider()
                            }
                            
                            Divider().hidden()
                            
                            // MARK: Voucher Section
                            VoucherSection()
                            
                            Divider().hidden()
                            
                            // MARK: Order Summary
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text(LocalizedStringKey("Summary"))
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(LocalizedStringKey("Subtotal"))
                                            .font(AppFont.body)
                                            .foregroundStyle(Color.textMuted)
                                        Spacer()
                                        Text(cartViewModel.subtotal.formattedVND)
                                            .font(AppFont.monoBody)
                                            .foregroundStyle(Color.textInk)
                                    }
                                    
                                    if cartViewModel.deliveryFee > 0 {
                                        HStack {
                                            Text(LocalizedStringKey("Delivery Fee"))
                                                .font(AppFont.body)
                                                .foregroundStyle(Color.textMuted)
                                            Spacer()
                                            Text(cartViewModel.deliveryFee.formattedVND)
                                                .font(AppFont.monoBody)
                                                .foregroundStyle(Color.textInk)
                                        }
                                    }
                                    
                                    if cartViewModel.summary.discount > 0 {
                                        HStack {
                                            Text(LocalizedStringKey("Discount"))
                                                .font(AppFont.body)
                                                .foregroundStyle(Color.semanticSuccess)
                                            Spacer()
                                            Text("-\(cartViewModel.summary.discount.formattedVND)")
                                                .font(AppFont.monoBody)
                                                .foregroundStyle(Color.semanticSuccess)
                                        }
                                    }
                                }
                                .padding(AppLayout.spacing)
                                .background(Color.surfaceCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.border, lineWidth: 1)
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppLayout.spacing)
                        .padding(.bottom, 72)
                    }
                    .coordinateSpace(name: "scroll")
                    .scrollIndicators(.hidden)
                    
                    // MARK: Total & Checkout
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        HStack(spacing: 0) {
                            Text(LocalizedStringKey("TOTAL"))
                                .font(AppFont.totalLabel)
                                .lineLimit(1)
                                .foregroundStyle(Color.textInk)
                            
                            Spacer(minLength: AppLayout.spacing)
                            
                            Text(cartViewModel.total.formattedVND)
                                .font(AppFont.monoTitle)
                                .foregroundStyle(Color.textInk)
                        }
                        
                        Button {
                            showingCheckout = true
                        } label: {
                            Text(LocalizedStringKey("Checkout"))
                                .font(AppFont.monoCTA)
                                .foregroundStyle(Color.backgroundPaper)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        }
                        .disabled(!cartViewModel.summary.meetsMinimum)
                        .opacity(cartViewModel.summary.meetsMinimum ? 1.0 : 0.666)
                    }
                    .padding(.vertical, 24)
                    .frame(minHeight: AppLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppLayout.spacing)
                    .background(ignoresSafeAreaEdges: .all)
                    .background {
                        WaveRect(stepWidth: AppLayout.waveStepWidth, waveEdge: .top)
                            .fill(Color.backgroundPaper)
                            .offset(x: 0, y: -9)
                    }
                    .overlay(alignment: .top) {
                        WaveSeparator(stepWidth: AppLayout.waveStepWidth)
                            .stroke(Color.secondary, lineWidth: 1)
                            .frame(height: 1)
                            .offset(x: 0, y: -9)
                    }
                }
                .zIndex(-Double.infinity)
            }
        }
        .fullScreenCover(item: $editingItem) { item in
            EditCartItemSheet(item: item, onSave: { updatedItem in
                cartViewModel.removeItem(item.id)
                cartViewModel.addItem(
                    product: updatedItem.product,
                    quantity: updatedItem.quantity,
                    customization: updatedItem.customization
                )
            })
        }
        .fullScreenCover(isPresented: $showingCheckout) {
            CheckoutView()
        }
    }
}

// MARK: - Cart Item Row

struct CartItemRow: View {
    let item: CartItem
    let onUpdateQuantity: (Int) -> Void
    let onRemove: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: AppLayout.spacingMedium) {
            // Image
            // CHANGED: Using CachedAsyncImage
            CachedAsyncImage(url: URL(string: item.product.displayImageUrl ?? "")) { phase in // CHANGED
                switch phase { // CHANGED
                case .empty: // CHANGED
                    Rectangle() // CHANGED
                        .fill(Color.surfaceCard) // CHANGED
                        .overlay { // CHANGED
                            ProgressView() // CHANGED
                                .tint(Color.primaryEspresso) // CHANGED
                        } // CHANGED
                case .success(let image): // CHANGED
                    image // CHANGED
                        .resizable() // CHANGED
                        .aspectRatio(contentMode: .fill) // CHANGED
                case .failure: // CHANGED
                    Rectangle() // CHANGED
                        .fill(Color.textInk.opacity(0.1)) // CHANGED
                        .overlay { // CHANGED
                            Image(systemName: "photo") // CHANGED
                                .font(AppFont.productTitle) // CHANGED
                                .foregroundStyle(Color.textInk) // CHANGED
                        } // CHANGED
                @unknown default: // CHANGED
                    EmptyView() // CHANGED
                } // CHANGED
            } // CHANGED
            .frame(width: AppLayout.productImageSize, height: AppLayout.productImageSize)
            .cornerRadius(AppLayout.cornerRadius)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.product.name)
                    .font(AppFont.headline)
                    .lineLimit(3)
                    .foregroundStyle(Color.textInk)
                
                if !item.displayCustomization.isEmpty {
                    Text(item.displayCustomization)
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(2)
                }
                
                if let notes = item.customization.notes, !notes.isEmpty {
                    Text("Note: \(notes)")
                        .font(AppFont.uiMicro)
                        .italic()
                        .foregroundStyle(Color.textMuted)
                }
                
                Button { onEdit() } label: {
                    Text("Edit")
                        .font(AppFont.uiMicro)
                        .foregroundStyle(Color.primaryEspresso)
                }
                .padding(.top, 4)
                
                Spacer(minLength: AppLayout.spacing)
                
                HStack(spacing: 0) {
                    Text(item.totalPrice.formattedVND)
                        .font(AppFont.monoBody)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(Color.textMuted)
                    
                    Spacer(minLength: 0)
                    
                    // Quantity Controls
                    HStack(spacing: AppLayout.spacingSmall) {
                        Button {
                            if item.quantity > 1 {
                                onUpdateQuantity(item.quantity - 1)
                            } else {
                                onRemove()
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(AppFont.body)
                                .padding(AppLayout.spacingMicro)
                                .foregroundStyle(Color.backgroundPaper)
                                .background(Color.textInk)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        }
                        .disabled(item.quantity <= 1)
                        .opacity(item.quantity <= 1 ? 0.666 : 1.0)
                        
                        Text("\(item.quantity)")
                            .font(AppFont.monoHeadline)
                            .frame(minWidth: AppLayout.quantityMinWidth)
                        
                        Button {
                            onUpdateQuantity(item.quantity + 1)
                        } label: {
                            Image(systemName: "plus")
                                .font(AppFont.body)
                                .padding(AppLayout.spacingMicro)
                                .foregroundStyle(Color.backgroundPaper)
                                .background(Color.textInk)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        }
                    }
                    .fixedSize()
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Empty Cart

struct EmptyCartView: View {
    let onBrowse: () -> Void
    
    var body: some View {
        VStack(spacing: AppLayout.spacingXL) {
            Spacer()
            
            Text("Your Cart is Empty")
                .font(AppFont.displayTitle)
                .foregroundColor(Color.textInk)
            
            Text("Start adding products to see them here.")
                .font(AppFont.body)
                .foregroundColor(Color.textMuted)
            
            Button { onBrowse() } label: {
                Text("Browse Menu")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.backgroundPaper)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
            
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Voucher Section

struct VoucherSection: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var code = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacing) {
            Text("Voucher")
                .textCase(.uppercase)
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
            
            HStack(spacing: AppLayout.spacingMedium) {
                TextField("Promotion Code", text: $code)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AppFont.monoBody)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                    }
                
                Button {
                    Task {
                        await cartViewModel.applyVoucher(code: code)
                        code = ""
                    }
                } label: {
                    Text("Apply")
                        .font(AppFont.monoBody)
                        .foregroundStyle(Color.backgroundPaper)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.textInk)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Edit Cart Item Sheet

struct EditCartItemSheet: View {
    let item: CartItem
    let onSave: (CartItem) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSize: ProductSize
    @State private var notes: String
    
    init(item: CartItem, onSave: @escaping (CartItem) -> Void) {
        self.item = item
        self.onSave = onSave
        _selectedSize = State(initialValue: item.customization.size)
        _notes = State(initialValue: item.customization.notes ?? "")
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                    }
                    
                    Spacer()
                    
                    Text("Update Item")
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Button {
                        var newItem = item
                        newItem.customization.size = selectedSize
                        newItem.customization.notes = notes
                        onSave(newItem)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(AppFont.body)
                            .foregroundStyle(Color.primaryEspresso)
                    }
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        // Product Header
                        HStack(spacing: AppLayout.spacing) {
                        // CHANGED: Using CachedAsyncImage
                        CachedAsyncImage(url: URL(string: item.product.displayImageUrl ?? "")) { phase in // CHANGED
                            switch phase { // CHANGED
                            case .empty: // CHANGED
                                Rectangle() // CHANGED
                                    .fill(Color.surfaceCard) // CHANGED
                                    .overlay { // CHANGED
                                        ProgressView() // CHANGED
                                            .tint(Color.primaryEspresso) // CHANGED
                                    } // CHANGED
                            case .success(let image): // CHANGED
                                image // CHANGED
                                    .resizable() // CHANGED
                                    .aspectRatio(contentMode: .fill) // CHANGED
                            case .failure: // CHANGED
                                Rectangle() // CHANGED
                                    .fill(Color.surfaceCard) // CHANGED
                            @unknown default: // CHANGED
                                EmptyView() // CHANGED
                            } // CHANGED
                        } // CHANGED
                        .frame(width: 60, height: 60)
                        .cornerRadius(AppLayout.cornerRadius)
                            
                            Text(item.product.name)
                                .font(AppFont.sectionHeader)
                                .foregroundColor(Color.textInk)
                            
                            Spacer()
                        }
                        
                        // Size Option
                        VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
                            Text("Size")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            HStack(spacing: 0) {
                                ForEach(item.product.sizeOptions.filter { $0.isEnabled }, id: \.size) { option in
                                    Button {
                                        selectedSize = option.size
                                    } label: {
                                        Text(option.size.rawValue)
                                            .font(AppFont.monoBody)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(selectedSize == option.size ? Color.primaryEspresso.opacity(0.2) : Color.backgroundPaper)
                                            .foregroundColor(Color.textInk)
                                    }
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
                            Text("Notes")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            TextField("Special instructions...", text: $notes)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(AppFont.body)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                }
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}
