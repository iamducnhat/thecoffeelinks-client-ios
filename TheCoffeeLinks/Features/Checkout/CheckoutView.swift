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
        redesignedBody
    }

    private var redesignedBody: some View {
        ZStack {
            BaseViewColor.background.ignoresSafeArea()

            if cartViewModel.cart.items.isEmpty {
                CheckoutEmptyState()
            } else {
                orderPlacedObserver

                VStack(alignment: .leading, spacing: 0) {
                    CheckoutFlowHeader(title: "Thanh toán") {
                        dismiss()
                    }
                    .padding(.horizontal, CheckoutMetric.horizontalInset)
                    .padding(.top, CheckoutMetric.topInset)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            orderDetailsSection
                            paymentSection
                            voucherSection
                        }
                        .padding(.horizontal, CheckoutMetric.horizontalInset)
                        .padding(.top, CheckoutMetric.headerToSectionGap)
                        .padding(.bottom, CheckoutMetric.contentBottomPadding)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !cartViewModel.cart.items.isEmpty {
                CartCTAOverlay(
                    label: "Thành tiền",
                    amount: cartViewModel.total.formattedVND,
                    title: checkoutViewModel.isPlacingOrder ? "ĐANG ĐẶT HÀNG" : "ĐẶT HÀNG",
                    isLoading: checkoutViewModel.isPlacingOrder,
                    isDisabled: !cartViewModel.canCheckout || checkoutViewModel.isPlacingOrder,
                    action: placeOrder
                )
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
        .fullScreenCover(isPresented: $showSuccess) {
            OrderSuccessView {
                showSuccess = false
                dismiss()
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
        .alert("Không thể đặt hàng", isPresented: Binding(
            get: { orderError != nil },
            set: { if !$0 { orderError = nil } }
        )) {
            Button("Đồng ý", role: .cancel) {}
        } message: {
            Text(orderError ?? "")
        }
        .onAppear {
            voucherCode = UserDefaults.standard.string(forKey: "checkoutVoucherCode") ?? ""
            redeemPoints = UserDefaults.standard.string(forKey: "checkoutRedeemPoints") ?? ""
            savedStoreId = UserDefaults.standard.string(forKey: "checkoutSelectedStoreId") ?? ""
            syncCartWithSelection()
        }
        .onDisappear {
            UserDefaults.standard.set(voucherCode, forKey: "checkoutVoucherCode")
            UserDefaults.standard.set(redeemPoints, forKey: "checkoutRedeemPoints")
            UserDefaults.standard.set(savedStoreId, forKey: "checkoutSelectedStoreId")
        }
    }

    private var orderDetailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Chi tiết đơn hàng")
                .font(BaseViewFont.bodyStrong)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.bottom, CheckoutMetric.summaryTopGap)

            CheckoutAmountRow(label: "\(cartViewModel.itemCount) sản phẩm", amount: cartViewModel.subtotal.formattedVND)
            CheckoutAmountRow(label: "Phí giao hàng", amount: cartViewModel.deliveryFee.formattedVND)

            if totalDiscount > 0 {
                CheckoutAmountRow(
                    label: "Ưu đãi",
                    amount: "-\(totalDiscount.formattedVND)",
                    amountColor: BaseViewColor.accent
                )
            }
        }
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: CheckoutMetric.sectionTitleToRowGap) {
            Text("Phương thức thanh toán")
                .font(BaseViewFont.bodyStrong)
                .foregroundStyle(BaseViewColor.textPrimary)

            CheckoutSelectionRow(
                title: checkoutViewModel.paymentMethod.displayName,
                iconName: checkoutViewModel.paymentMethod.iconName,
                action: { showPaymentMethodSheet = true }
            )
        }
        .padding(.top, CheckoutMetric.sectionGap)
    }

    private var voucherSection: some View {
        VStack(alignment: .leading, spacing: CheckoutMetric.sectionTitleToRowGap) {
            Text("Ưu đãi")
                .font(BaseViewFont.bodyStrong)
                .foregroundStyle(BaseViewColor.textPrimary)

            CheckoutSelectionRow(
                title: voucherSummaryText,
                iconName: nil,
                action: { showVoucherSheet = true }
            )
        }
        .padding(.top, CheckoutMetric.sectionGap)
    }

    private var totalDiscount: Double {
        cartViewModel.bestDiscount + cartViewModel.pointsDiscount
    }

    private var voucherSummaryText: String {
        if let applied = checkoutViewModel.appliedVoucher, !applied.isEmpty {
            return applied
        }
        if cartViewModel.summary.discount > 0 {
            return "Đã chọn ưu đãi"
        }
        return "Chọn ưu đãi"
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

private struct CheckoutFlowHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(BaseViewFont.screenTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .frame(maxWidth: .infinity)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(BaseViewColor.accentForeground)
                        .frame(width: CheckoutMetric.navButtonSize, height: CheckoutMetric.navButtonSize)
                        .background(BaseViewColor.accent)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .frame(minHeight: CheckoutMetric.navButtonSize)
    }
}

private struct CheckoutAmountRow: View {
    let label: String
    let amount: String
    var amountColor: Color = BaseViewColor.textPrimary

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textSecondary)

            Spacer(minLength: 16)

            Text(amount)
                .font(BaseViewFont.label)
                .foregroundStyle(amountColor)
                .lineLimit(1)
        }
        .padding(.bottom, CheckoutMetric.summaryRowGap)
    }
}

private struct CheckoutSelectionRow: View {
    let title: String
    let iconName: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                if let iconName {
                    IconView(name: iconName)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .frame(width: 23, height: 23)
                }

                Text(title)
                    .font(BaseViewFont.bodyStrong)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 13)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(BaseViewColor.textSecondary)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, minHeight: CheckoutMetric.selectionRowMinHeight, alignment: .leading)
            .overlay {
                Rectangle().strokeBorder(BaseViewColor.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private enum CheckoutMetric {
    static let horizontalInset: CGFloat = 23
    static let topInset: CGFloat = 23
    static let navButtonSize: CGFloat = 23
    static let headerToSectionGap: CGFloat = 28
    static let summaryTopGap: CGFloat = 23
    static let summaryRowGap: CGFloat = 13
    static let sectionGap: CGFloat = 31
    static let sectionTitleToRowGap: CGFloat = 23
    static let selectionRowMinHeight: CGFloat = 49
    static let contentBottomPadding: CGFloat = 140
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
