//
//  CartView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
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
            BaseViewColor.background.ignoresSafeArea()
            
            if cartViewModel.isEmpty {
                EmptyCartView(onBrowse: { dismiss() })
            } else {
                // Fixed Navigation Header
                HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .padding(12)
                            .background {
                                Circle()
                                    .fill(BaseViewColor.background)
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(BaseViewColor.textPrimary, lineWidth: 1)
                                    .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                            }
                    }

                    Text("cart_header_count \(cartViewModel.itemCount)")
                        .font(BaseViewFont.displayMedium)
                        .lineLimit(1)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .fixedSize()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .hidden()
                }
                .frame(minHeight: BaseViewLayout.touchTarget)
                .padding(.horizontal, BaseViewLayout.spacing)
                .padding(.top, 8)
                .zIndex(1)
                .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: 0) {
                    ScrollView(.vertical) {
                        // Navigation Header (Scrollable)
                        VStack(spacing: BaseViewLayout.marginCompact) {
                            HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                    .padding(12)
                                    .hidden()
                                
                                Text("cart_header_count \(cartViewModel.itemCount)")
                                    .font(BaseViewFont.displayMedium)
                                    .lineLimit(1)
                                    .foregroundColor(BaseViewColor.textPrimary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                            
                            Divider()
                                .background(BaseViewColor.borderSecondary)
                                .padding(.horizontal, -BaseViewLayout.spacing)
                        }
                        .padding(.horizontal, BaseViewLayout.spacing)
                        .padding(.top, BaseViewLayout.spacingCompact)
                        .background(BaseViewColor.background)
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) {
                            self.scrollOffset = $0
                        }
                        
                        LazyVStack(spacing: BaseViewLayout.spacing) {
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
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                Text("summary_section_title")
                                    .textCase(.uppercase)
                                    .font(BaseViewFont.sectionHeader)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("subtotal_label")
                                            .font(BaseViewFont.body)
                                            .foregroundStyle(BaseViewColor.textSecondary)
                                        Spacer()
                                        Text(cartViewModel.subtotal.formattedVND)
                                            .font(BaseViewFont.monoBody)
                                            .foregroundStyle(BaseViewColor.textPrimary)
                                    }
                                    
                                    if cartViewModel.deliveryFee > 0 {
                                        HStack {
                                            Text("delivery_fee_label")
                                                .font(BaseViewFont.body)
                                                .foregroundStyle(BaseViewColor.textSecondary)
                                            Spacer()
                                            Text(cartViewModel.deliveryFee.formattedVND)
                                                .font(BaseViewFont.monoBody)
                                                .foregroundStyle(BaseViewColor.textPrimary)
                                        }
                                    }
                                    
                                    if cartViewModel.summary.discount > 0 {
                                        HStack {
                                            Text("discount_label")
                                                .font(BaseViewFont.body)
                                                .foregroundStyle(BaseViewColor.semanticSuccess)
                                            Spacer()
                                            Text("-\(cartViewModel.summary.discount.formattedVND)")
                                                .font(BaseViewFont.monoBody)
                                                .foregroundStyle(BaseViewColor.semanticSuccess)
                                        }
                                    }
                                }
                                .padding(BaseViewLayout.spacing)
                                .background(BaseViewColor.surface)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(BaseViewColor.border, lineWidth: 1)
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(BaseViewLayout.spacing)
                        .padding(.bottom, 72)
                    }
                    .coordinateSpace(name: "scroll")
                    .scrollIndicators(.hidden)
                    
                    // MARK: Total & Checkout
                    VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                        HStack(spacing: 0) {
                            Text("total_label")
                                .font(BaseViewFont.totalLabel)
                                .lineLimit(1)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            Spacer(minLength: BaseViewLayout.spacing)
                            
                            Text(cartViewModel.total.formattedVND)
                                .font(BaseViewFont.monoTitle)
                                .foregroundStyle(BaseViewColor.textPrimary)
                        }
                        
                        Button {
                            showingCheckout = true
                        } label: {
                            Text("checkout_button")
                                .font(BaseViewFont.monoCTA)
                                .foregroundStyle(BaseViewColor.background)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(BaseViewColor.accent)
                                .clipShape(Capsule())
                        }
                        .disabled(!cartViewModel.summary.meetsMinimum)
                        .opacity(cartViewModel.summary.meetsMinimum ? 1.0 : 0.666)
                    }
                    .padding(.vertical, 24)
                    .frame(minHeight: BaseViewLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BaseViewLayout.spacing)
                    .background(ignoresSafeAreaEdges: .all)
                    .background {
                        WaveRect(stepWidth: BaseViewLayout.waveStepWidth, waveEdge: .top)
                            .fill(BaseViewColor.background)
                            .offset(x: 0, y: -9)
                    }
                    .overlay(alignment: .top) {
                        WaveSeparator(stepWidth: BaseViewLayout.waveStepWidth)
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
        HStack(spacing: BaseViewLayout.spacingMedium) {
            AppRemoteImage(
                url: URL(string: item.product.displayImageUrl ?? ""),
                width: BaseViewLayout.productImageSize,
                height: BaseViewLayout.productImageSize,
                backgroundColor: BaseViewColor.surface,
                showsProgress: true
            )
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.product.name)
                    .font(BaseViewFont.headline)
                    .lineLimit(3)
                    .foregroundStyle(isAvailable ? BaseViewColor.textPrimary : BaseViewColor.textSecondary)
                
                // Unavailable badge
                if !isAvailable {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("Not available at this store")
                            .font(BaseViewFont.uiMicro)
                    }
                    .foregroundStyle(Color.orange)
                    .padding(.top, 2)
                }
                
                if !item.displayCustomization.isEmpty {
                    Text(item.displayCustomization)
                        .font(BaseViewFont.uiCaption)
                        .foregroundStyle(BaseViewColor.textSecondary)
                        .lineLimit(2)
                }
                
                if let notes = item.customization.notes, !notes.isEmpty {
                    Text("note_prefix \(notes)")
                        .font(BaseViewFont.uiMicro)
                        .italic()
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                
                Button { onEdit() } label: {
                    Text("edit_button")
                        .font(BaseViewFont.uiMicro)
                        .foregroundStyle(BaseViewColor.accent)
                }
                .padding(.top, 4)
                
                Spacer(minLength: BaseViewLayout.spacing)
                
                HStack(spacing: 0) {
                    Text(item.totalPrice.formattedVND)
                        .font(BaseViewFont.monoBody)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(BaseViewColor.textSecondary)
                    
                    Spacer(minLength: 0)
                    
                    AppQuantityStepper(
                        quantity: item.quantity,
                        onDecrease: {
                            if item.quantity > 1 {
                                onUpdateQuantity(item.quantity - 1)
                            } else {
                                onRemove()
                            }
                        },
                        onIncrease: {
                            onUpdateQuantity(item.quantity + 1)
                        }
                    )
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
        VStack(spacing: BaseViewLayout.spacingXL) {
            Spacer()
            
            Text("cart_empty_title")
                .font(BaseViewFont.displayTitle)
                .foregroundColor(BaseViewColor.textPrimary)
            
            Text("cart_empty_message")
                .font(BaseViewFont.body)
                .foregroundColor(BaseViewColor.textSecondary)
            
            AppButton("browse_menu_button", style: .primary, fillsWidth: false, action: onBrowse)
            
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
        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
            Text("voucher_section_title")
                .textCase(.uppercase)
                .font(BaseViewFont.sectionHeader)
                .foregroundStyle(BaseViewColor.textPrimary)
            
            HStack(spacing: BaseViewLayout.spacingMedium) {
                TextField("promotion_code_placeholder", text: $code)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(BaseViewFont.monoBody)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay {
                        Capsule()
                            .strokeBorder(BaseViewColor.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: BaseViewLayout.dashedPattern))
                    }
                
                AppButton("apply_button", style: .primary, fillsWidth: false) {
                    Task {
                        await cartViewModel.applyVoucher(code: code)
                        code = ""
                    }
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
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text("cancel_button")
                            .font(BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("item_update_title")
                        .font(BaseViewFont.sectionHeader)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        var newItem = item
                        newItem.customization.size = selectedSize
                        newItem.customization.notes = notes
                        onSave(newItem)
                        dismiss()
                    } label: {
                        Text("save_button")
                            .font(BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.accent)
                    }
                }
                .padding(BaseViewLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    VStack(spacing: BaseViewLayout.spacingXL) {
                        // Product Header
                        HStack(spacing: BaseViewLayout.spacing) {
                        // CHANGED: Using CachedAsyncImage
                            AppRemoteImage(
                                url: URL(string: item.product.displayImageUrl ?? ""),
                                width: 60,
                                height: 60,
                                backgroundColor: BaseViewColor.surface,
                                showsProgress: true,
                                placeholderIcon: nil
                            )
                            
                            Text(item.product.name)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundColor(BaseViewColor.textPrimary)
                            
                            Spacer()
                        }
                        
                        // Size Option
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacingMedium) {
                            Text("size_section_title")
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            HStack(spacing: 0) {
                                ForEach(item.product.sizeOptions.filter { $0.isEnabled }, id: \.size) { option in
                                    Button {
                                        selectedSize = option.size
                                    } label: {
                                        Text(option.size.rawValue)
                                            .font(BaseViewFont.monoBody)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(selectedSize == option.size ? BaseViewColor.accent : BaseViewColor.background)
                                            .foregroundColor(selectedSize == option.size ? .white : BaseViewColor.textPrimary)
                                    }
                                }
                            }
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
                            )
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacingMedium) {
                            Text("notes_section_title")
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            TextField("notes_placeholder", text: $notes)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(BaseViewFont.body)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .overlay {
                                    Capsule()
                                        .strokeBorder(BaseViewColor.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: BaseViewLayout.dashedPattern))
                                }
                        }
                    }
                    .padding(BaseViewLayout.spacing)
                }
            }
        }
    }
}
