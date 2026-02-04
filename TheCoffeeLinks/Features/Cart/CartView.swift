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
            Color.bgPrimary.ignoresSafeArea()
            
            if cartViewModel.isEmpty {
                EmptyCartView(onBrowse: { dismiss() })
            } else {
                // Fixed Navigation Header
                HStack(alignment: .center, spacing: AppLayout.spacing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .padding(12)
                            .background {
                                Circle()
                                    .fill(Color.bgPrimary)
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.textPrimary, lineWidth: min(66.6, max(scrollOffset, 0.0)) / 66.6)
                                    .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                            }
                    }
                    
                    Text("cart_header_count \(cartViewModel.itemCount)")
                        .font(AppTypography.displayMedium)
                        .lineLimit(1)
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .hidden()
                }
                .frame(minHeight: AppLayout.touchTarget)
                .padding(.horizontal, AppLayout.spacing)
                .padding(.top, 8)
                .zIndex(1)
                .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: 0) {
                    ScrollView(.vertical) {
                        // Navigation Header (Scrollable)
                        VStack(spacing: AppLayout.marginCompact) {
                            HStack(alignment: .center, spacing: AppLayout.spacing) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(Color.textPrimary)
                                    .padding(12)
                                    .hidden()
                                
                                Text("cart_header_count \(cartViewModel.itemCount)")
                                    .font(AppTypography.displayMedium)
                                    .lineLimit(1)
                                    .foregroundColor(Color.textPrimary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                            
                            Divider()
                                .background(Color.borderSecondary)
                                .padding(.horizontal, -AppLayout.spacing)
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        .padding(.top, AppLayout.spacingCompact)
                        .background(Color.bgPrimary)
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
                                    },
                                    storeId: cartViewModel.cart.storeId
                                )
                                
                                Divider()
                            }
                            
                            Divider().hidden()
                            
                            // MARK: Voucher Section
                            VoucherSection()
                            
                            Divider().hidden()
                            
                            // MARK: Order Summary
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("summary_section_title")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textPrimary)
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("subtotal_label")
                                            .font(AppFont.body)
                                            .foregroundStyle(Color.textSecondary)
                                        Spacer()
                                        Text(cartViewModel.subtotal.formattedVND)
                                            .font(AppFont.monoBody)
                                            .foregroundStyle(Color.textPrimary)
                                    }
                                    
                                    if cartViewModel.deliveryFee > 0 {
                                        HStack {
                                            Text("delivery_fee_label")
                                                .font(AppFont.body)
                                                .foregroundStyle(Color.textSecondary)
                                            Spacer()
                                            Text(cartViewModel.deliveryFee.formattedVND)
                                                .font(AppFont.monoBody)
                                                .foregroundStyle(Color.textPrimary)
                                        }
                                    }
                                    
                                    if cartViewModel.summary.discount > 0 {
                                        HStack {
                                            Text("discount_label")
                                                .font(AppFont.body)
                                                .foregroundStyle(Color.stateSuccess)
                                            Spacer()
                                            Text("-\(cartViewModel.summary.discount.formattedVND)")
                                                .font(AppFont.monoBody)
                                                .foregroundStyle(Color.stateSuccess)
                                        }
                                    }
                                }
                                .padding(AppLayout.spacing)
                                .background(Color.surfacePrimary)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.border, lineWidth: 1)
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
                            Text("total_label")
                                .font(AppFont.totalLabel)
                                .lineLimit(1)
                                .foregroundStyle(Color.textPrimary)
                            
                            Spacer(minLength: AppLayout.spacing)
                            
                            Text(cartViewModel.total.formattedVND)
                                .font(AppFont.monoTitle)
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        Button {
                            showingCheckout = true
                        } label: {
                            Text("checkout_button")
                                .font(AppFont.monoCTA)
                                .foregroundStyle(Color.bgPrimary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.accentPrimary)
                                .clipShape(Capsule())
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
                            .fill(Color.bgPrimary)
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
    let storeId: String? // Store ID to check product availability
    
    private var isAvailable: Bool {
        item.product.isAvailableAt(storeId: storeId)
    }
    
    var body: some View {
        HStack(spacing: AppLayout.spacingMedium) {
            // Image
            // CHANGED: Using CachedAsyncImage
            CachedAsyncImage(url: URL(string: item.product.displayImageUrl ?? "")) { phase in // CHANGED
                switch phase { // CHANGED
                case .empty: // CHANGED
                    Rectangle() // CHANGED
                        .fill(Color.surfacePrimary) // CHANGED
                        .overlay { // CHANGED
                            ProgressView() // CHANGED
                                .tint(Color.accentPrimary) // CHANGED
                        } // CHANGED
                case .success(let image): // CHANGED
                    image // CHANGED
                        .resizable() // CHANGED
                        .aspectRatio(contentMode: .fill) // CHANGED
                case .failure: // CHANGED
                    Rectangle() // CHANGED
                        .fill(Color.textPrimary.opacity(0.1)) // CHANGED
                        .overlay { // CHANGED
                            Image("photo") // CHANGED
                                .font(AppFont.productTitle) // CHANGED
                                .foregroundStyle(Color.textPrimary) // CHANGED
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
                    .foregroundStyle(isAvailable ? Color.textPrimary : Color.textSecondary)
                
                // Unavailable badge
                if !isAvailable {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("Not available at this store")
                            .font(AppFont.uiMicro)
                    }
                    .foregroundStyle(Color.orange)
                    .padding(.top, 2)
                }
                
                if !item.displayCustomization.isEmpty {
                    Text(item.displayCustomization)
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }
                
                if let notes = item.customization.notes, !notes.isEmpty {
                    Text("note_prefix \(notes)")
                        .font(AppFont.uiMicro)
                        .italic()
                        .foregroundStyle(Color.textSecondary)
                }
                
                Button { onEdit() } label: {
                    Text("edit_button")
                        .font(AppFont.uiMicro)
                        .foregroundStyle(Color.accentPrimary)
                }
                .padding(.top, 4)
                
                Spacer(minLength: AppLayout.spacing)
                
                HStack(spacing: 0) {
                    Text(item.totalPrice.formattedVND)
                        .font(AppFont.monoBody)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(Color.textSecondary)
                    
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
                            Image("minus")
                                .font(AppFont.body)
                                .padding(AppLayout.spacingMicro)
                                .foregroundStyle(Color.bgPrimary)
                                .background(Color.textPrimary)
                                .clipShape(Capsule())
                        }
                        .disabled(item.quantity <= 1)
                        .opacity(item.quantity <= 1 ? 0.666 : 1.0)
                        
                        Text("\(item.quantity)")
                            .font(AppFont.monoHeadline)
                            .frame(minWidth: AppLayout.quantityMinWidth)
                        
                        Button {
                            onUpdateQuantity(item.quantity + 1)
                        } label: {
                            Image("plus")
                                .font(AppFont.body)
                                .padding(AppLayout.spacingMicro)
                                .foregroundStyle(Color.bgPrimary)
                                .background(Color.textPrimary)
                                .clipShape(Capsule())
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
            
            Text("cart_empty_title")
                .font(AppFont.displayTitle)
                .foregroundColor(Color.textPrimary)
            
            Text("cart_empty_message")
                .font(AppFont.body)
                .foregroundColor(Color.textSecondary)
            
            Button { onBrowse() } label: {
                Text("browse_menu_button")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.bgPrimary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accentPrimary)
                    .clipShape(Capsule())
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
            Text("voucher_section_title")
                .textCase(.uppercase)
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textPrimary)
            
            HStack(spacing: AppLayout.spacingMedium) {
                TextField("promotion_code_placeholder", text: $code)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AppFont.monoBody)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                    }
                
                Button {
                    Task {
                        await cartViewModel.applyVoucher(code: code)
                        code = ""
                    }
                } label: {
                    Text("apply_button")
                        .font(AppFont.monoBody)
                        .foregroundStyle(Color.bgPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.textPrimary)
                        .clipShape(Capsule())
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
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text("cancel_button")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("item_update_title")
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        var newItem = item
                        newItem.customization.size = selectedSize
                        newItem.customization.notes = notes
                        onSave(newItem)
                        dismiss()
                    } label: {
                        Text("save_button")
                            .font(AppFont.body)
                            .foregroundStyle(Color.accentPrimary)
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
                                    .fill(Color.surfacePrimary) // CHANGED
                                    .overlay { // CHANGED
                                        ProgressView() // CHANGED
                                            .tint(Color.accentPrimary) // CHANGED
                                    } // CHANGED
                            case .success(let image): // CHANGED
                                image // CHANGED
                                    .resizable() // CHANGED
                                    .aspectRatio(contentMode: .fill) // CHANGED
                            case .failure: // CHANGED
                                Rectangle() // CHANGED
                                    .fill(Color.surfacePrimary) // CHANGED
                            @unknown default: // CHANGED
                                EmptyView() // CHANGED
                            } // CHANGED
                        } // CHANGED
                        .frame(width: 60, height: 60)
                        .cornerRadius(AppLayout.cornerRadius)
                            
                            Text(item.product.name)
                                .font(AppFont.sectionHeader)
                                .foregroundColor(Color.textPrimary)
                            
                            Spacer()
                        }
                        
                        // Size Option
                        VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
                            Text("size_section_title")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            HStack(spacing: 0) {
                                ForEach(item.product.sizeOptions.filter { $0.isEnabled }, id: \.size) { option in
                                    Button {
                                        selectedSize = option.size
                                    } label: {
                                        Text(option.size.rawValue)
                                            .font(AppFont.monoBody)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(selectedSize == option.size ? Color.accentPrimary : Color.bgPrimary)
                                            .foregroundColor(selectedSize == option.size ? .white : Color.textPrimary)
                                    }
                                }
                            }
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.borderPrimary, lineWidth: 1)
                            )
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
                            Text("notes_section_title")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            TextField("notes_placeholder", text: $notes)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(AppFont.body)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .overlay {
                                    Capsule()
                                        .strokeBorder(Color.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                }
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}
