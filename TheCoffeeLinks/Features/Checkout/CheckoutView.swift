//
//  CheckoutView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
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
    
    @FocusState private var focusedField: CheckoutField?
    
    enum CheckoutField: Hashable {
        case voucher
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
            Color.bgPrimary.ignoresSafeArea()
                .zIndex(-Double.infinity)
            
            if cartViewModel.cart.items.isEmpty {
                CheckoutEmptyState()
                    .onAppear {
                        print("Cart empty")
                    }
            } else {
                orderPlacedObserver
                // Fixed Navigation Header
                HStack(alignment: .center, spacing: AppLayout.spacing) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textPrimary)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                            .background {
                                Capsule()
                                    .fill(Color.surfacePrimary)
                            }
                            .overlay {
                                Capsule()
                                    .stroke(Color.textPrimary, lineWidth: min(66.6, max(scrollOffset, 0.0)) / 66.6)
                                    .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                            }
                    }
                    
                    Text("checkout_title")
                        .font(AppFont.displayTitle)
                        .lineLimit(1)
                        .foregroundColor(Color.textPrimary)
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
                            Image(systemName: "arrow.left")
                                .font(AppFont.navIcon)
                                .foregroundStyle(Color.textPrimary)
                                .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                                .hidden()
                            
                            Text("Checkout")
                                .font(AppFont.displayTitle)
                                .lineLimit(1)
                                .foregroundColor(Color.textPrimary)
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
                            
                            // MARK: Order Type Section
                            
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                HStack {
                                    Text("order_type_section")
                                        .textCase(.uppercase)
                                        .font(AppFont.sectionHeader)
                                        .foregroundColor(Color.textPrimary)
                                    
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
                                                .font(AppFont.monoBody)
                                            Image(systemName: "arrow.left.arrow.right")
                                                .font(AppFont.monoCaption)
                                        }
                                        .padding(AppLayout.spacingMicro)
                                        .foregroundStyle(Color.bgPrimary)
                                        .background(Color.accentPrimary)
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
                                            Text(cartViewModel.cart.mode == .delivery ? "delivery_address_header" : "store_location_header")
                                                .font(AppFont.uiMicro)
                                                .foregroundStyle(Color.textSecondary)
                                            
                                            Text(locationDisplayString)
                                                .font(AppFont.body)
                                                .foregroundStyle(isLocationSelected ? Color.textPrimary : Color.textTertiary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Image("chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                    .padding(12)
                                    .overlay {
                                        Capsule()
                                            .stroke(isLocationSelected ? Color.border : Color.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: isLocationSelected ? [] : AppLayout.dashedPattern))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().hidden()
                            
                            // MARK: Cart Items
                            ForEach(cartViewModel.cart.items) { item in
                                HStack(spacing: AppLayout.spacingMedium) {
                                    // Image Placeholder
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
                                            .font(AppFont.productTitle)
                                            .lineLimit(3)
                                            .foregroundColor(Color.textPrimary)
                                        
                                        if !item.displayCustomization.isEmpty {
                                            Text(item.displayCustomization)
                                                .font(AppFont.uiCaption)
                                                .foregroundStyle(Color.textSecondary)
                                        }
                                        
                                        Spacer(minLength: AppLayout.spacing)
                                        
                                        HStack(spacing: 0) {
                                            Text(item.totalPrice.formattedVND)
                                                .font(AppFont.monoBody)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                                .foregroundColor(Color.accentPrimary)
                                            
                                            Spacer(minLength: 0)
                                            
                                            // Quantity Controls
                                            HStack(spacing: AppLayout.spacingSmall) {
                                                Button {
                                                    if item.quantity > 1 {
                                                        cartViewModel.updateQuantity(for: item.id, delta: -1)
                                                    } else {
                                                        cartViewModel.removeItem(item.id)
                                                    }
                                                } label: {
                                                    Text("\(Image(systemName: "minus"))")
                                                        .font(AppFont.body)
                                                        .padding(AppLayout.spacingMicro)
                                                        .foregroundStyle(Color.bgPrimary)
                                                        .background(Color.accentPrimary)
                                                        .clipShape(Capsule())
                                                }
                                                .disabled(item.quantity <= 1)
                                                .opacity(item.quantity <= 1 ? 0.666 : 1.0)
                                                
                                                Text("\(item.quantity)")
                                                    .font(AppFont.monoHeadline)
                                                    .frame(minWidth: AppLayout.quantityMinWidth)
                                                
                                                Button {
                                                    cartViewModel.updateQuantity(for: item.id, delta: 1)
                                                } label: {
                                                    Text("\(Image(systemName: "plus"))")
                                                        .font(AppFont.body)
                                                        .padding(AppLayout.spacingMicro)
                                                        .foregroundStyle(Color.bgPrimary)
                                                        .background(Color.accentPrimary)
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
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("voucher_section_title")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundColor(Color.textPrimary)
                                
                                HStack(spacing: 8) {
                                    CapsuleTextField(
                                        placeholder: String(localized: "promotion_code_placeholder"),
                                        text: $voucherCode,
                                        icon: "ticket"
                                    )
                                    .focused($focusedField, equals: .voucher)
                                    .submitLabel(.done)
                                    
                                    Button {
                                        focusedField = nil
                                        Task {
                                            await checkoutViewModel.applyVoucher(code: voucherCode, cartViewModel: cartViewModel)
                                        }
                                    } label: {
                                        Text("Apply")
                                            .font(AppFont.monoBody)
                                            .foregroundColor(voucherCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == checkoutViewModel.appliedVoucher ? Color.textSecondary : Color.bgPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(voucherCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == checkoutViewModel.appliedVoucher ? Color.surfacePrimary : Color.accentPrimary)
                                            .clipShape(Capsule())
                                    }
                                    .disabled(voucherCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == checkoutViewModel.appliedVoucher)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().hidden()
                            
                            // MARK: Redeem Points Section
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("redeem_point_section")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundColor(Color.textPrimary)
                                
                                let points = authViewModel.currentUser?.points ?? 0
                                (
                                    Text("points_balance_info \(points)")
                                        .foregroundColor(Color.textSecondary)
                                    +
                                    Text("points_info_link")
                                        .underline(pattern: .dot)
                                        .foregroundColor(Color.accentPrimary)
                                )
                                .font(AppFont.body)
                                
                                HStack(spacing: 8) {
                                    CapsuleTextField(
                                        placeholder: String(localized: "redeem_points_placeholder"),
                                        text: $redeemPoints,
                                        icon: "star",
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
                                        
                                        Text("Apply")
                                            .font(AppFont.monoBody)
                                            .foregroundColor(isUnchanged ? Color.textSecondary : Color.bgPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(isUnchanged ? Color.surfacePrimary : Color.accentPrimary)
                                            .clipShape(Capsule())
                                    }
                                    .disabled(Int(redeemPoints.trimmingCharacters(in: .whitespacesAndNewlines)) == checkoutViewModel.appliedPoints)
                                }
                                
                                // Inline Validation Error
                                if let warning = checkoutViewModel.warning {
                                    Text(warning)
                                        .font(AppFont.uiCaption)
                                        .foregroundColor(Color.stateError)
                                        .transition(.opacity)
                                }
                                
                                // Applied Confirmation
                                if checkoutViewModel.appliedPoints > 0 {
                                    Text("Points applied: -\(cartViewModel.pointsDiscount.formattedVND)")
                                        .font(AppFont.monoCaption)
                                        .foregroundColor(Color.accentPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().hidden()
                            
                            // MARK: Payment Method Section
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("payment_method_section")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundColor(Color.textPrimary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppLayout.spacingMedium) {
                                        ForEach(PaymentMethod.validForCheckout, id: \.self) { method in
                                            Button {
                                                checkoutViewModel.paymentMethod = method
                                            } label: {
                                                VStack(spacing: 4) {
                                                    Image(systemName: method.iconName)
                                                        .font(AppFont.navIcon)
                                                    Text(method.displayName)
                                                        .font(AppFont.monoBody)
                                                }
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 16)
                                                .frame(minWidth: 100)
                                                .background(checkoutViewModel.paymentMethod == method ? Color.accentPrimary : Color.clear)
                                                .foregroundColor(checkoutViewModel.paymentMethod == method ? Color.bgPrimary : Color.textPrimary)
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.border, lineWidth: 1)
                                                )
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(.horizontal, AppLayout.spacing)
                                }
                                .padding(.horizontal, -AppLayout.spacing)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().hidden()
                            
                            // Error Display
                            if let error = orderError {
                                HStack {
                                    Image("triangle_alert")
                                        .foregroundColor(Color.stateError)
                                    Text(error)
                                        .font(AppFont.uiMicro)
                                        .foregroundColor(Color.stateError)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.stateError.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.stateError, lineWidth: 1)
                                )
                            }
                            
                            // Order Log
                            if checkoutViewModel.isPlacingOrder || !orderLog.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(orderLog, id: \.self) { log in
                                        Text("> \(log)")
                                            .font(AppFont.uiMicro)
                                            .foregroundColor(Color.accentPrimary)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.bgPrimary)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.accentPrimary, lineWidth: 1)
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppLayout.spacing)
                        .padding(.bottom, 72)
                    }
                    .coordinateSpace(name: "scroll")
                    .scrollIndicators(.hidden)
                    
                    // MARK: Total & Confirmation
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        HStack(spacing: 0) {
                            Text("total_label")
                                .font(AppFont.totalLabel)
                                .lineLimit(1)
                                .foregroundColor(Color.textPrimary)
                            
                            Spacer(minLength: AppLayout.spacing)
                            
                            Text(cartViewModel.total.formattedVND)
                                .font(AppFont.monoTitle)
                                .foregroundColor(Color.textPrimary)
                        }
                        
                        Button {
                            placeOrder()
                        } label: {
                            Text(checkoutViewModel.isPlacingOrder ? "placing_order_state" : "place_order_button")
                                .font(AppFont.monoCTA)
                                .foregroundColor(Color.bgPrimary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.accentPrimary)
                                .clipShape(Capsule())
                        }
                        .disabled(!cartViewModel.canCheckout || checkoutViewModel.isPlacingOrder)
                    }
                    .padding(.vertical, 24)
                    .frame(minHeight: AppLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppLayout.spacing)
                    .background(Color.bgPrimary, ignoresSafeAreaEdges: .all)
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
            DeliveryAddressSheet()
                .environmentObject(deliveryViewModel)
        }
        .sheet(isPresented: $showStoreSheet) {
            StorePickerSheet()
                .environmentObject(storeViewModel)
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
        .onAppear {
            syncCartWithSelection()
            // Restore saved textfield and store values
            voucherCode = UserDefaults.standard.string(forKey: "checkoutVoucherCode") ?? ""
            redeemPoints = UserDefaults.standard.string(forKey: "checkoutRedeemPoints") ?? ""
            savedStoreId = UserDefaults.standard.string(forKey: "checkoutSelectedStoreId") ?? ""
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
            // Apply logic when focus is lost (newField is nil or different)
            if newField != .voucher {
                Task {
                    await checkoutViewModel.applyVoucher(code: voucherCode, cartViewModel: cartViewModel)
                }
            }
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


// MARK: - Empty State

struct CheckoutEmptyState: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: AppLayout.spacingXL) {
            Text("cart_empty_title")
                .font(AppFont.displayTitle)
                .foregroundColor(Color.textPrimary)
            
            Text("cart_empty_message_checkout")
                .font(AppFont.body)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                dismiss()
            } label: {
                Text("return_to_menu_button")
                    .font(AppFont.monoCTA)
                    .foregroundColor(Color.bgPrimary)
                    .padding(.vertical, 12)
                    .frame(width: 200)
                    .background(Color.accentPrimary)
                    .clipShape(Capsule())
            }
        }
    }
}

