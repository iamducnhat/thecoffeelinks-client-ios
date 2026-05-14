//
//  CheckoutView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import CachedAsyncImage // CHANGED

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct CheckoutView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var storeViewModel: StoreViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var checkoutViewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var scrollOffset = CGFloat.zero
    @State private var voucherCode: String = ""
    @State private var redeemPoints: String = ""
    @State private var savedStoreId: String = ""
    @State private var showSuccess = false
    @State private var orderError: String?
    @State private var orderLog: [String] = []
    
    @State private var showEditSheet = false
    @State private var itemToEdit: CartItem? // For editing in sheet
    
    @State private var showDeliverySheet = false
    @State private var showStoreSheet = false
    @State private var showVoucherSheet = false
    @State private var showPaymentMethodSheet = false
    
    @FocusState private var focusedField: CheckoutField?
    
    enum CheckoutField: Hashable {
        case points
    }
    
    private var locationDisplayString: String {
        if cartViewModel.cart.mode == .delivery {
            return deliveryViewModel.selectedAddress?.shortAddress ?? String(localized: "select_delivery_address")
        } else {
            return storeViewModel.selectedStore?.name ?? String(localized: "select_store")
        }
    }
    
    private var isLocationSelected: Bool {
        if cartViewModel.cart.mode == .delivery {
            return deliveryViewModel.selectedAddress != nil
        } else {
            return storeViewModel.selectedStore != nil
        }
    }

    private var selectedVoucherDisplay: String {
        let applied = checkoutViewModel.appliedVoucher?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let applied, !applied.isEmpty {
            return applied
        }
        let typed = voucherCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty {
            return typed.uppercased()
        }
        return String(localized: "promotion_code_placeholder")
    }
    
    init() {
        let container = DependencyContainer.shared
        _checkoutViewModel = StateObject(wrappedValue: CheckoutViewModel(
            orderRepository: container.orderRepository,
            deliveryRepository: container.deliveryRepository,
            voucherRepository: container.voucherRepository,
            predictionRepository: container.predictionRepository,
            analyticsService: container.analyticsService,
            hapticService: container.hapticManager
        ))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
                .zIndex(-Double.infinity)
            
            if cartViewModel.cart.items.isEmpty {
                CheckoutEmptyState()
                    .onAppear {
                        debugLog("Cart empty")
                    }
            } else {
                orderPlacedObserver
                // Fixed Navigation Header
                HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
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
                    
                Text("Checkout")
                    .font(BaseViewFont.displayMedium)
                    .lineLimit(1)
                    .foregroundColor(BaseViewColor.textPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: BaseViewLayout.touchTarget)
            .padding(.horizontal, BaseViewLayout.spacing)
            .padding(.top, BaseViewLayout.spacingCompact)
            .zIndex(1)
            .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: 0) {
                    ScrollView(.vertical) { LazyVStack(spacing: BaseViewLayout.spacing) {
                        // Navigation Header (Scrollable)
                        VStack(spacing: BaseViewLayout.marginCompact) {
                            HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                                Button { dismiss() } label: {
                                    Image(systemName: "arrow.left")
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
                                .hidden()
                                
                                Text("Checkout")
                                    .font(BaseViewFont.displayMedium)
                                    .lineLimit(1)
                                    .foregroundColor(BaseViewColor.textPrimary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                            .frame(minHeight: BaseViewLayout.touchTarget)
                            .fixedSize(horizontal: false, vertical: true)
                            
                            Divider()
                                .background(BaseViewColor.borderSecondary)
                                .padding(.horizontal, -BaseViewLayout.spacing*2)
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
                            
                            // MARK: Order Type Section
                            
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                HStack {
                                    Text("order_type_section")
                                        .textCase(.uppercase)
                                        .font(BaseViewFont.sectionHeader)
                                        .foregroundColor(BaseViewColor.textPrimary)
                                    
                                    Spacer(minLength: 0)
                                    
                                    Button {
                                        // Toggle between modes
                                        let modes: [OrderingMode] = [.pickup, .dineIn, .delivery]
                                        if let currentIdx = modes.firstIndex(of: cartViewModel.cart.mode) {
                                            let nextIdx = (currentIdx + 1) % modes.count
                                            withAnimation(nil) {
                                                cartViewModel.cart.mode = modes[nextIdx]
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(cartViewModel.cart.mode.displayName)
                                                .textCase(.uppercase)
                                                .font(BaseViewFont.monoBody)
                                            Image(systemName: "arrow.left.arrow.right")
                                                .font(BaseViewFont.monoCaption)
                                        }
                                        .padding(.vertical, BaseViewLayout.spacingMicro)
                                        .padding(.horizontal, BaseViewLayout.spacing)
                                        .foregroundStyle(BaseViewColor.background)
                                        .background(BaseViewColor.accent)
                                        .clipShape(Capsule())
                                    }
                                }
                                
                                // Address/Location Selection
                                Button {
                                    if cartViewModel.cart.mode == .delivery {
                                        showDeliverySheet = true
                                    } else {
                                        showStoreSheet = true
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 4) {
                                                Text(cartViewModel.cart.mode == .delivery ? "delivery_address_header" : "store_location_header")
                                                    .font(BaseViewFont.uiMicro)
                                                    .foregroundStyle(BaseViewColor.textSecondary)
                                                
                                                // Show recommended badge if store matches recommendation
                                                if let recommended = cartViewModel.recommendedStore,
                                                   cartViewModel.cart.storeId == recommended.store.id,
                                                   cartViewModel.cart.mode == .delivery {
                                                    Text("⭐ RECOMMENDED")
                                                        .font(.system(size: 8, weight: .semibold))
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 2)
                                                        .background(Color.green)
                                                        .cornerRadius(3)
                                                }
                                            }
                                            
                                            Text(locationDisplayString)
                                                .font(BaseViewFont.body)
                                                .foregroundStyle(isLocationSelected ? BaseViewColor.textPrimary : BaseViewColor.textTertiary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundStyle(BaseViewColor.textSecondary)
                                    }
                                    .padding(12)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                            .strokeBorder(isLocationSelected ? BaseViewColor.border : BaseViewColor.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: isLocationSelected ? [] : BaseViewLayout.dashedPattern))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // H5 FIX: Table selector for dine-in
                            if cartViewModel.cart.mode == .dineIn {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("table_number_header")
                                        .font(BaseViewFont.uiMicro)
                                        .foregroundStyle(BaseViewColor.textSecondary)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                                        ForEach(1...20, id: \.self) { table in
                                            let tableStr = String(table)
                                            let isSelected = cartViewModel.cart.tableId == tableStr
                                            
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    cartViewModel.cart.tableId = isSelected ? nil : tableStr
                                                }
                                            } label: {
                                                Text("\(table)")
                                                    .font(BaseViewFont.monoBody)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 10)
                                                    .foregroundStyle(isSelected ? BaseViewColor.background : BaseViewColor.textPrimary)
                                                    .background(isSelected ? BaseViewColor.accent : BaseViewColor.surface)
                                                    .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusSmall))
                                                    .overlay {
                                                        RoundedRectangle(cornerRadius: BaseViewLayout.radiusSmall)
                                                            .strokeBorder(isSelected ? BaseViewColor.accent : BaseViewColor.border, lineWidth: 1)
                                                    }
                                            }
                                        }
                                    }
                                }
                                .padding(12)
                                .overlay {
                                    RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                        .strokeBorder(cartViewModel.cart.tableId != nil ? BaseViewColor.border : BaseViewColor.borderSecondary,
                                                      style: StrokeStyle(lineWidth: 1, dash: cartViewModel.cart.tableId != nil ? [] : BaseViewLayout.dashedPattern))
                                }
                            }

                            Divider().hidden()

                            // MARK: Price Breakdown
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacingSmall) {
                                Text("order_summary")
                                    .font(BaseViewFont.sectionHeader)
                                    .foregroundColor(BaseViewColor.textPrimary)

                                Divider()

                                // Subtotal
                                HStack {
                                    Text("subtotal_label")
                                        .font(BaseViewFont.body)
                                        .foregroundColor(BaseViewColor.textSecondary)
                                    Spacer()
                                    Text(cartViewModel.subtotal.formattedVND)
                                        .font(BaseViewFont.monoBody)
                                        .foregroundColor(BaseViewColor.textPrimary)
                                }

                                // Discount (if any)
                                if cartViewModel.discount > 0 {
                                    HStack {
                                        Text("discount_label")
                                            .font(BaseViewFont.body)
                                            .foregroundColor(BaseViewColor.accent)
                                        Spacer()
                                        Text("-\(cartViewModel.discount.formattedVND)")
                                            .font(BaseViewFont.monoBody)
                                            .foregroundColor(BaseViewColor.accent)
                                    }
                                }

                                // Points discount (if any)
                                if cartViewModel.pointsDiscount > 0 {
                                    HStack {
                                        Text("points_discount_label")
                                            .font(BaseViewFont.body)
                                            .foregroundColor(BaseViewColor.accent)
                                        Spacer()
                                        Text("-\(cartViewModel.pointsDiscount.formattedVND)")
                                            .font(BaseViewFont.monoBody)
                                            .foregroundColor(BaseViewColor.accent)
                                    }
                                }

                                // Membership & Promo Discount Explanation
                                if let user = authViewModel.currentUser, user.id != "guest" {
                                    let status = user.membershipStatus
                                    let tierPct = status.discountPercent
                                    let tierAmount = cartViewModel.subtotal * (tierPct / 100.0)
                                    
                                    if cartViewModel.currentDiscountSource == .tier && tierAmount > 0 {
                                        HStack {
                                            HStack(spacing: 4) {
                                                Image(systemName: "crown.fill")
                                                    .font(.system(size: 12))
                                                Text("\(user.membershipTier.displayName) -\(Int(tierPct))%")
                                                    .font(BaseViewFont.body)
                                            }
                                            Spacer()
                                            Text("-\(tierAmount.formattedVND)")
                                                .font(BaseViewFont.monoBody)
                                        }
                                        .foregroundColor(BaseViewColor.accent)
                                        
                                        Text("You are saving with your \(user.membershipTier.displayName) benefits.")
                                            .font(BaseViewFont.uiMicro)
                                            .foregroundColor(BaseViewColor.textSecondary)
                                    } else if cartViewModel.currentDiscountSource == .voucher && tierAmount > 0 {
                                        Text("Best available discount applied. Your \(user.membershipTier.displayName) benefit resumes when promo ends.")
                                            .font(BaseViewFont.uiMicro)
                                            .foregroundColor(BaseViewColor.textSecondary)
                                    }
                                }

                                // Tax (8%)
                                let totalDiscount = cartViewModel.bestDiscount
                                let taxable = max(0, cartViewModel.subtotal - totalDiscount - cartViewModel.pointsDiscount)
                                let taxAmount = taxable * 0.08
                                HStack {
                                    Text("tax_label")
                                        .font(BaseViewFont.body)
                                        .foregroundColor(BaseViewColor.textSecondary)
                                    Spacer()
                                    Text(taxAmount.formattedVND)
                                        .font(BaseViewFont.monoBody)
                                        .foregroundColor(BaseViewColor.textPrimary)
                                }

                                if cartViewModel.cart.mode == .delivery {
                                    HStack {
                                        Text("delivery_fee_label")
                                            .font(BaseViewFont.body)
                                            .foregroundColor(BaseViewColor.textSecondary)
                                        Spacer()
                                        Text(cartViewModel.deliveryFee.formattedVND)
                                            .font(BaseViewFont.monoBody)
                                            .foregroundColor(BaseViewColor.textPrimary)
                                    }
                                }

                                Divider()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().hidden()
                            
                            // MARK: Cart Items
                            ForEach(cartViewModel.cart.items) { item in
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
                                            .font(BaseViewFont.productTitle)
                                            .lineLimit(3)
                                            .foregroundColor(BaseViewColor.textPrimary)
                                        
                                        if !item.displayCustomization.isEmpty {
                                            Text(item.displayCustomization)
                                                .font(BaseViewFont.uiCaption)
                                                .foregroundStyle(BaseViewColor.textSecondary)
                                        }
                                        
                                        Spacer(minLength: BaseViewLayout.spacing)
                                        
                                        HStack(spacing: 0) {
                                            Text(item.totalPrice.formattedVND)
                                                .font(BaseViewFont.monoBody)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                                .foregroundColor(BaseViewColor.accent)
                                            
                                            Spacer(minLength: 0)
                                            
                                            // Quantity Controls
                                            HStack(spacing: BaseViewLayout.spacingSmall) {
                                                Button {
                                                    if item.quantity > 1 {
                                                        cartViewModel.updateQuantity(for: item.id, delta: -1)
                                                    } else {
                                                        cartViewModel.removeItem(item.id)
                                                    }
                                                } label: {
                                                    Text("\(Image(systemName: "minus"))")
                                                        .font(BaseViewFont.body)
                                                        .padding(BaseViewLayout.spacingMicro)
                                                        .foregroundStyle(BaseViewColor.background)
                                                        .background(BaseViewColor.accent)
                                                        .clipShape(Capsule())
                                                }
                                                .disabled(item.quantity <= 1)
                                                .opacity(item.quantity <= 1 ? 0.666 : 1.0)
                                                
                                                Text("\(item.quantity)")
                                                    .font(BaseViewFont.monoHeadline)
                                                    .frame(minWidth: BaseViewLayout.quantityMinWidth)
                                                
                                                Button {
                                                    cartViewModel.updateQuantity(for: item.id, delta: 1)
                                                } label: {
                                                    Text("\(Image(systemName: "plus"))")
                                                        .font(BaseViewFont.body)
                                                        .padding(BaseViewLayout.spacingMicro)
                                                        .foregroundStyle(BaseViewColor.background)
                                                        .background(BaseViewColor.accent)
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
                                .contentShape(Rectangle()) // Make entire row tappable
                                .onTapGesture {
                                    itemToEdit = item
                                    showEditSheet = true
                                }
                                
                                Divider()
                            }
                            
                            Divider().hidden()
                            
                            // MARK: Voucher Section
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                Text("voucher_section_title")
                                    .textCase(.uppercase)
                                    .font(BaseViewFont.sectionHeader)
                                    .foregroundColor(BaseViewColor.textPrimary)

                                Button {
                                    focusedField = nil
                                    showVoucherSheet = true
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("selected_voucher_header")
                                                .font(BaseViewFont.uiMicro)
                                                .foregroundStyle(BaseViewColor.textSecondary)

                                            Text(selectedVoucherDisplay)
                                                .font(BaseViewFont.body)
                                                .foregroundStyle(checkoutViewModel.appliedVoucher == nil ? BaseViewColor.textTertiary : BaseViewColor.textPrimary)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundStyle(BaseViewColor.textSecondary)
                                    }
                                    .padding(12)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                            .strokeBorder(BaseViewColor.border, lineWidth: 1)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().hidden()
                            
                            // MARK: Redeem Points Section
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                Text("redeem_point_section")
                                    .textCase(.uppercase)
                                    .font(BaseViewFont.sectionHeader)
                                    .foregroundColor(BaseViewColor.textPrimary)
                                
                                let points = authViewModel.currentUser?.points ?? 0
                                (
                                    Text("points_balance_info \(points)")
                                        .foregroundColor(BaseViewColor.textSecondary)
                                    +
                                    Text("points_info_link")
                                        .underline(pattern: .dot)
                                        .foregroundColor(BaseViewColor.accent)
                                )
                                .font(BaseViewFont.body)
                                
                                HStack(spacing: 8) {
                                    AppTextInput(
                                        title: nil,
                                        text: $redeemPoints,
                                        placeholder: String(localized: "redeem_points_placeholder"),
                                        leadingIcon: nil,
                                        keyboardType: .numberPad
                                    )
                                    .focused($focusedField, equals: .points)
                                    .submitLabel(.done)
                                    
                                    Button {
                                        focusedField = nil
                                        checkoutViewModel.applyPoints(input: redeemPoints, availablePoints: points, cartViewModel: cartViewModel)
                                    } label: {
                                        let pointsInput = Int(redeemPoints.trimmingCharacters(in: .whitespacesAndNewlines))
                                        let isUnchanged = pointsInput == checkoutViewModel.appliedPoints
                                        
                                        Text("\(Image(systemName: "checkmark"))")
                                            .font(BaseViewFont.uiButton)
                                            .foregroundColor(isUnchanged ? BaseViewColor.textSecondary : BaseViewColor.background)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .frame(minHeight: 48)
                                            .background(isUnchanged ? BaseViewColor.surface : BaseViewColor.accent)
                                            .clipShape(Capsule())
                                    }
                                    //                                    .opacity(Int(redeemPoints.trimmingCharacters(in: .whitespacesAndNewlines)) == checkoutViewModel.appliedPoints ? 0.3 : 1)
                                    .disabled(Int(redeemPoints.trimmingCharacters(in: .whitespacesAndNewlines)) == checkoutViewModel.appliedPoints)
                                }
                                
                                // Inline Validation Error
                                if let warning = checkoutViewModel.warning {
                                    Text(warning)
                                        .font(BaseViewFont.uiCaption)
                                        .foregroundColor(BaseViewColor.semanticError)
                                        .transition(.opacity)
                                }
                                
                                // Applied Confirmation
                                if checkoutViewModel.appliedPoints > 0 {
                                    Text("Points applied: -\(cartViewModel.pointsDiscount.formattedVND)")
                                        .font(BaseViewFont.monoBody)
                                        .foregroundColor(BaseViewColor.accent)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().hidden()
                            
                            // MARK: Payment Method Section
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                Text("payment_method_section")
                                    .textCase(.uppercase)
                                    .font(BaseViewFont.sectionHeader)
                                    .foregroundColor(BaseViewColor.textPrimary)

                                Button {
                                    focusedField = nil
                                    showPaymentMethodSheet = true
                                } label: {
                                    HStack {
                                        HStack(spacing: 10) {
                                            IconView(name: checkoutViewModel.paymentMethod.iconName)
                                                .font(BaseViewFont.navIcon)
                                            Text(checkoutViewModel.paymentMethod.displayName)
                                                .font(BaseViewFont.body)
                                                .foregroundStyle(BaseViewColor.textPrimary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundStyle(BaseViewColor.textSecondary)
                                    }
                                    .padding(12)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                            .strokeBorder(BaseViewColor.border, lineWidth: 1)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().hidden()
                            
                            // Error Display
                            //                            if let error = orderError {
                            //                                HStack {
                            //                                    Image("triangle_alert")
                            //                                        .foregroundColor(BaseViewColor.semanticError)
                            //                                    Text(error)
                            //                                        .font(BaseViewFont.uiMicro)
                            //                                        .foregroundColor(BaseViewColor.semanticError)
                            //                                }
                            //                                .padding(12)
                            //                                .frame(maxWidth: .infinity, alignment: .leading)
                            //                                .background(BaseViewColor.semanticError.opacity(0.1))
                            //                                .overlay(
                            //                                    Capsule()
                            //                                        .strokeBorder(BaseViewColor.semanticError, lineWidth: 1)
                            //                                )
                            //                            }
                            
                            // Order Log
                            //                            if checkoutViewModel.isPlacingOrder || !orderLog.isEmpty {
                            //                                VStack(alignment: .leading, spacing: 4) {
                            //                                    ForEach(orderLog, id: \.self) { log in
                            //                                        Text("> \(log)")
                            //                                            .font(BaseViewFont.uiMicro)
                            //                                            .foregroundColor(BaseViewColor.accent)
                            //                                    }
                            //                                }
                            //                                .padding(16)
                            //                                .frame(maxWidth: .infinity, alignment: .leading)
                            //                                .background(BaseViewColor.background)
                            //                                .overlay(
                            //                                    Capsule()
                            //                                        .strokeBorder(BaseViewColor.accent, lineWidth: 1)
                            //                                )
                            //                            }
                        }
                    }
                    .padding(.bottom, 72)
                    .padding(.horizontal, BaseViewLayout.spacing)
                    }
                    .coordinateSpace(name: "scroll")
                    .scrollIndicators(.hidden)
                    
                    // MARK: Total & Confirmation
                    ReceiptTotalBar(
                        totalLabel: "TOTAL",
                        totalValue: cartViewModel.total.formattedVND,
                        ctaTitle: checkoutViewModel.isPlacingOrder ? "placing_order_state" : "place_order_button",
                        action: placeOrder
                    )
//                    VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
//                        HStack(spacing: 0) {
//                            Text("total_label")
//                                .font(BaseViewFont.totalLabel)
//                                .lineLimit(1)
//                                .foregroundColor(BaseViewColor.textPrimary)
//                            
//                            Spacer(minLength: BaseViewLayout.spacing)
//                            
//                            Text(cartViewModel.total.formattedVND)
//                                .font(BaseViewFont.monoTitle)
//                                .foregroundColor(BaseViewColor.textPrimary)
//                        }
//                        if #available(iOS 26.0, *) {
//                            Button {
//                                placeOrder()
//                            } label: {
//                                
//                                Text(checkoutViewModel.isPlacingOrder ? "placing_order_state" : "place_order_button")
//                                    .font(BaseViewFont.monoCTA)
//                                    .foregroundColor(BaseViewColor.background)
//                                    .padding(.vertical, 12)
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    //.background(BaseViewColor.accent)
//                                    .clipShape(Capsule())
//                            }
//                            .buttonStyle(.glassProminent)
//                            .disabled(!cartViewModel.canCheckout || checkoutViewModel.isPlacingOrder)
//                            .tint(BaseViewColor.accent)
//                        } else {
//                            Button {
//                                placeOrder()
//                            } label: {
//                                Text(checkoutViewModel.isPlacingOrder ? "placing_order_state" : "place_order_button")
//                                    .font(BaseViewFont.monoCTA)
//                                    .foregroundColor(BaseViewColor.background)
//                                    .padding(.vertical, 12)
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    .background(BaseViewColor.accent)
//                                    .clipShape(Capsule())
//                            }
//                            .disabled(!cartViewModel.canCheckout || checkoutViewModel.isPlacingOrder)
//                        }
//                    }
//                    .padding(.vertical, 24)
//                    .frame(minHeight: BaseViewLayout.touchTarget)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal, BaseViewLayout.spacing)
//                    .background(BaseViewColor.background, ignoresSafeAreaEdges: .all)
//                    .background {
//                        WaveRect(stepWidth: BaseViewLayout.waveStepWidth, waveEdge: .top)
//                            .fill(BaseViewColor.background)
//                            .offset(x: 0, y: -9)
//                    }
//                    .overlay(alignment: .top) {
//                        WaveSeparator(stepWidth: BaseViewLayout.waveStepWidth)
//                            .stroke(Color.secondary, lineWidth: 1)
//                            .frame(height: 1)
//                            .offset(x: 0, y: -9)
//                    }
                }
                .zIndex(-Double.infinity+1)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let item = itemToEdit {
                ProductDetailSheet(product: item.product, cartItem: item)
            }
        }
        .fullScreenCover(isPresented: $showSuccess) {
            OrderSuccessView {
                showSuccess = false
                dismiss()
            }
        }
        .sheet(isPresented: $showDeliverySheet) {
            if cartViewModel.cart.mode == .delivery {
                DeliveryStorePickerSheet(
                    storeViewModel: storeViewModel,
                    deliveryViewModel: deliveryViewModel,
                    cartViewModel: cartViewModel
                )
            } else {
                DeliveryAddressSheet()
                    .environmentObject(deliveryViewModel)
            }
        }
        .sheet(isPresented: $showStoreSheet) {
            StorePickerSheet()
                .environmentObject(storeViewModel)
        }
        .sheet(isPresented: $showVoucherSheet) {
            VouchersView(
                onSelect: { voucher in
                    voucherCode = voucher.code
                    Task {
                        await checkoutViewModel.applyVoucher(code: voucher.code, cartViewModel: cartViewModel)
                    }
                },
                voucherRepository: DependencyContainer.shared.voucherRepository
            )
        }
        .sheet(isPresented: $showPaymentMethodSheet) {
            PaymentMethodPickerSheet(selectedMethod: $checkoutViewModel.paymentMethod)
        }
        .alert("Switch Store?", isPresented: $cartViewModel.showStoreConflictAlert) {
            Button("Cancel", role: .cancel) {
                cartViewModel.cancelStoreSwitch()
            }
            Button("Switch & Clear Cart", role: .destructive) {
                if let store = cartViewModel.conflictingStore {
                    cartViewModel.switchStore(to: store)
                }
            }
        } message: {
            if let storeName = cartViewModel.conflictingStore?.name {
                Text("Switching to \(storeName) will clear your current cart. Continue?")
            }
        }
        .sheet(isPresented: $checkoutViewModel.showingPaymentWebView) {
            if let url = checkoutViewModel.paymentUrl {
                PaymentWebView(url: url) { result in
                    checkoutViewModel.handlePaymentResult(result)
                } onCancel: {
                    checkoutViewModel.showingPaymentWebView = false
                }
            }
        }
        .overlay(alignment: .top) {
            // Store Recommendation Toast
            if cartViewModel.showStoreRecommendationToast,
               let recommended = cartViewModel.recommendedStore {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Better Store Available")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(recommended.store.name) has better delivery terms")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Switch") {
                            cartViewModel.switchStore(to: recommended.store)
                            cartViewModel.showStoreRecommendationToast = false
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    )
                }
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: cartViewModel.showStoreRecommendationToast)
            }
        }
        .onAppear {
            syncCartWithSelection()
            // Restore saved textfield and store values
            voucherCode = UserDefaults.standard.string(forKey: "checkoutVoucherCode") ?? ""
            redeemPoints = UserDefaults.standard.string(forKey: "checkoutRedeemPoints") ?? ""
            savedStoreId = UserDefaults.standard.string(forKey: "checkoutSelectedStoreId") ?? ""
            
            // Load stores if not already loaded
            if storeViewModel.stores.isEmpty {
                storeViewModel.loadStores()
            }
            
            // Restore store selection if saved
            if !savedStoreId.isEmpty {
                // Find and select the store if it exists
                Task {
                    if let store = storeViewModel.stores.first(where: { $0.id == savedStoreId }) {
                        storeViewModel.selectedStore = store
                    }
                }
            }
        }
        .onChange(of: storeViewModel.selectedStore) { newStore in
            syncCartWithSelection()
            if let store = newStore {
                savedStoreId = store.id
            }
        }
        .onChange(of: deliveryViewModel.selectedAddress) { _ in
            syncCartWithSelection()
        }
        .onChange(of: cartViewModel.cart.mode) { _ in
            syncCartWithSelection()
        }
        .onChange(of: focusedField) { newField in
            if newField != .points {
                let points = authViewModel.currentUser?.points ?? 0
                checkoutViewModel.applyPoints(input: redeemPoints, availablePoints: points, cartViewModel: cartViewModel)
            }
        }
        .onDisappear {
            // Save all values when view is dismissed
            UserDefaults.standard.set(voucherCode, forKey: "checkoutVoucherCode")
            UserDefaults.standard.set(redeemPoints, forKey: "checkoutRedeemPoints")
            UserDefaults.standard.set(savedStoreId, forKey: "checkoutSelectedStoreId")
        }
    }
    
    private func syncCartWithSelection() {
        if cartViewModel.cart.mode == .delivery {
            if let address = deliveryViewModel.selectedAddress {
                cartViewModel.setDeliveryAddress(address.id, address: address)
            }
        } else {
            if let store = storeViewModel.selectedStore {
                cartViewModel.setStore(store.id)
            }
        }
    }
    
    private func placeOrder() {
        // H5 FIX: Validate table selection for dine-in
        if cartViewModel.cart.mode == .dineIn && cartViewModel.cart.tableId == nil {
            orderError = String(localized: "error_select_table")
            return
        }
        
        orderLog = [String(localized: "status_connecting")]
        orderError = nil
        
        Task {
            orderLog.append(String(localized: "status_creating_order"))
            
            // Use applied points if valid, otherwise try parsing raw input (but applied is safer)
            let points = checkoutViewModel.appliedPoints
            _ = await checkoutViewModel.placeOrder(cart: cartViewModel.cart, pointsToRedeem: points, voucherCode: voucherCode)
            
            if checkoutViewModel.showingPaymentWebView {
                orderLog.append(String(localized: "status_opening_gateway"))
            } else if let order = checkoutViewModel.orderPlaced {
                handleOrderSuccess(order)
            } else if let error = checkoutViewModel.error {
                orderError = error.localizedDescription
                orderLog.append("✗ Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleOrderSuccess(_ order: Order) {
        orderLog.append(String(localized: "status_success_format \(order.id.prefix(8))"))
        orderLog.append(String(localized: "status_confirmed"))
        cartViewModel.clearCart()
        DependencyContainer.shared.hapticManager.playSuccess()
        showSuccess = true
    }
}

extension CheckoutView {
    var orderPlacedObserver: some View {
        EmptyView()
            .onChange(of: checkoutViewModel.orderPlaced) { newOrder in
                if let order = newOrder {
                    handleOrderSuccess(order)
                }
            }
            .onChange(of: checkoutViewModel.error?.localizedDescription) { newErrorDescription in
                if let errorDescription = newErrorDescription {
                    orderError = errorDescription
                    orderLog.append("✗ Error: \(errorDescription)")
                }
            }
    }
}

// MARK: - Payment Method Picker

struct PaymentMethodPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMethod: PaymentMethod

    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: BaseViewLayout.marginCompact) {
                    HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                        Text("payment_method_section")
                            .font(BaseViewFont.displayMedium)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(BaseViewColor.textPrimary)
                                .padding(12)
                                .background { Circle().fill(BaseViewColor.background) }
                                .overlay { Circle().strokeBorder(BaseViewColor.borderSecondary, lineWidth: 1) }
                        }
                    }
                    .frame(minHeight: BaseViewLayout.touchTarget)

                    Divider()
                        .background(BaseViewColor.borderSecondary)
                        .padding(.horizontal, -BaseViewLayout.spacing)
                }
                .padding(.horizontal, BaseViewLayout.spacing)
                .padding(.top, BaseViewLayout.spacing)
                .background(BaseViewColor.background)

                ScrollView {
                    LazyVStack(spacing: BaseViewLayout.spacing) {
                        ForEach(PaymentMethod.validForCheckout, id: \.self) { method in
                            Button {
                                selectedMethod = method
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    IconView(name: method.iconName)
                                        .font(BaseViewFont.navIcon)
                                        .foregroundStyle(BaseViewColor.textPrimary)

                                    Text(method.displayName)
                                        .font(BaseViewFont.body)
                                        .foregroundStyle(BaseViewColor.textPrimary)

                                    Spacer()

                                    if method == selectedMethod {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(BaseViewColor.accent)
                                    }
                                }
                                .padding(12)
                                .overlay {
                                    RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous)
                                        .strokeBorder(method == selectedMethod ? BaseViewColor.accent : BaseViewColor.border, lineWidth: 1)
                                }
                            }
                        }
                    }
                    .padding(BaseViewLayout.spacing)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}


// MARK: - Empty State

struct CheckoutEmptyState: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: BaseViewLayout.spacingXL) {
            Text("cart_empty_title")
                .font(BaseViewFont.displayTitle)
                .foregroundColor(BaseViewColor.textPrimary)
            
            Text("cart_empty_message_checkout")
                .font(BaseViewFont.body)
                .foregroundColor(BaseViewColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                dismiss()
            } label: {
                Text("return_to_menu_button")
                    .font(BaseViewFont.monoCTA)
                    .foregroundColor(BaseViewColor.background)
                    .padding(.vertical, 12)
                    .frame(width: 200)
                    .background(BaseViewColor.accent)
                    .clipShape(Capsule())
            }
        }
    }
}
