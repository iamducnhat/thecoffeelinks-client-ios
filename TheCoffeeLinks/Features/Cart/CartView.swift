//
//  CartView.swift
//  thecoffeelinks-client-ios
//
//  Cart checkout flow matching the SVG cart/info/checkout sequence.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject private var cartViewModel: CartViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingInfo = false
    @State private var editingItem: CartItem?

    var body: some View {
        NavigationStack {
            ZStack {
                BaseViewColor.background.ignoresSafeArea()

                if cartViewModel.isEmpty {
                    EmptyCartView(onBrowse: { dismiss() })
                } else {
                    cartContent
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showingInfo) {
                CartInfoView()
            }
        }
        .sheet(item: $editingItem) { item in
            ProductDetailSheet(product: item.product, cartItem: item)
        }
    }

    private var cartContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            CartFlowHeader(title: "Giỏ hàng", backSymbol: "chevron.left") {
                dismiss()
            }
            .padding(.horizontal, CartFlowMetric.horizontalInset)
            .padding(.top, CartFlowMetric.topInset)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text("Sản phẩm đã chọn")
                        .font(CartFlowFont.sectionTitle)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .padding(.horizontal, CartFlowMetric.horizontalInset)
                        .padding(.top, CartFlowMetric.headerToSectionGap)
                        .padding(.bottom, CartFlowMetric.sectionToListGap)

                    ForEach(cartViewModel.cart.items.sorted(by: { $0.addedAt < $1.addedAt })) { item in
                        CartProductRow(
                            item: item,
                            storeId: cartViewModel.cart.storeId,
                            onDecrease: { handleDecrease(item) },
                            onIncrease: { cartViewModel.updateQuantity(for: item.id, delta: 1) },
                            onDelete: { cartViewModel.removeItem(item.id) },
                            onEdit: { editingItem = item }
                        )
                    }
                }
                .padding(.bottom, CartFlowMetric.contentBottomPadding)
            }
            .background(BaseViewColor.background)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CartCTAOverlay(
                label: "\(cartViewModel.itemCount) sản phẩm",
                amount: cartViewModel.subtotal.formattedVND,
                title: "TIẾP TỤC",
                isDisabled: cartViewModel.isEmpty
            ) {
                showingInfo = true
            }
        }
    }

    private func handleDecrease(_ item: CartItem) {
        if item.quantity > 1 {
            cartViewModel.updateQuantity(for: item.id, delta: -1)
        }
    }
}

struct CartInfoView: View {
    @EnvironmentObject private var cartViewModel: CartViewModel
    @EnvironmentObject private var storeViewModel: StoreViewModel
    @EnvironmentObject private var deliveryViewModel: DeliveryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingStoreSheet = false
    @State private var showingAddressSheet = false
    @State private var showingCheckout = false

    private let orderingModes: [OrderingMode] = [.delivery, .pickup, .dineIn]

    var body: some View {
        ZStack {
            BaseViewColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                CartFlowHeader(title: "Thông tin", backSymbol: "chevron.left") {
                    dismiss()
                }
                .padding(.horizontal, CartFlowMetric.horizontalInset)
                .padding(.top, CartFlowMetric.topInset)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        storeSection
                        orderingModeSection

                        if cartViewModel.cart.mode == .delivery {
                            addressSection
                        }
                    }
                    .padding(.horizontal, CartFlowMetric.horizontalInset)
                    .padding(.top, CartFlowMetric.headerToSectionGap)
                    .padding(.bottom, CartFlowMetric.contentBottomPadding)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CartCTAOverlay(
                label: deliveryFeeLabel,
                amount: displayedDeliveryFee.formattedVND,
                title: "TIẾP TỤC",
                isDisabled: !canContinue
            ) {
                syncCartSelection()
                showingCheckout = true
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showingCheckout) {
            CheckoutView()
        }
        .sheet(isPresented: $showingStoreSheet) {
            StorePickerSheet()
                .environmentObject(storeViewModel)
        }
        .sheet(isPresented: $showingAddressSheet) {
            DeliveryAddressSheet()
                .environmentObject(deliveryViewModel)
        }
        .onAppear {
            if storeViewModel.stores.isEmpty {
                storeViewModel.loadStores()
            }
            Task {
                await deliveryViewModel.loadAddresses()
                syncCartSelection()
            }
        }
        .onChange(of: storeViewModel.selectedStore) { _ in syncCartSelection() }
        .onChange(of: deliveryViewModel.selectedAddress) { _ in syncCartSelection() }
    }

    private var storeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Cửa hàng")
                .font(CartFlowFont.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)

            Text("Chọn cửa hàng phụ trách đơn hàng của bạn")
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textSecondary)

            StoreInfoCard(
                store: storeViewModel.selectedStore,
                onEdit: { showingStoreSheet = true }
            )
            .padding(.top, CartFlowMetric.infoCardTopGap)
        }
    }

    private var orderingModeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Nhận hàng")
                .font(CartFlowFont.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.top, CartFlowMetric.infoSectionGap)

            VStack(alignment: .leading, spacing: CartFlowMetric.orderingModeOptionGap) {
                ForEach(orderingModes, id: \.self) { mode in
                    OrderingModeRow(
                        title: orderingModeTitle(for: mode),
                        isSelected: cartViewModel.cart.mode == mode,
                        action: { selectOrderingMode(mode) }
                    )
                }
            }
            .padding(.top, CartFlowMetric.infoCardTopGap)
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Địa chỉ giao hàng")
                .font(CartFlowFont.sectionTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(.top, CartFlowMetric.infoSectionGap)

            DeliveryAddressCard(address: deliveryViewModel.selectedAddress)
                .padding(.top, CartFlowMetric.infoCardTopGap)

            Button {
                showingAddressSheet = true
            } label: {
                Text("ĐỔI ĐỊA CHỈ")
                    .font(BaseViewFont.cta)
                    .tracking(2)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CartFlowMetric.outlineButtonVerticalPadding)
                    .frame(minHeight: CartFlowMetric.outlineButtonMinHeight)
                    .overlay {
                        Rectangle().strokeBorder(BaseViewColor.border, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .padding(.top, CartFlowMetric.addressButtonGap)
        }
    }

    private var canContinue: Bool {
        guard storeViewModel.selectedStore != nil else { return false }
        guard cartViewModel.cart.mode == .delivery else { return true }
        return deliveryViewModel.selectedAddress != nil
    }

    private var displayedDeliveryFee: Double {
        cartViewModel.cart.mode == .delivery ? cartViewModel.deliveryFee : 0
    }

    private var deliveryFeeLabel: String {
        guard cartViewModel.cart.mode == .delivery else {
            return "Phí giao hàng"
        }

        if let eta = deliveryViewModel.estimatedETA {
            return "Giờ cao điểm • \(eta)"
        }
        return "Phí giao hàng"
    }

    private func orderingModeTitle(for mode: OrderingMode) -> String {
        switch mode {
        case .delivery:
            return "Tại nhà"
        case .pickup:
            return "Lấy tại quán"
        case .dineIn:
            return "Dùng tại quán"
        }
    }

    private func selectOrderingMode(_ mode: OrderingMode) {
        cartViewModel.setMode(mode)
        syncCartSelection()
    }

    private func syncCartSelection() {
        if let store = storeViewModel.selectedStore {
            cartViewModel.setStore(store.id)
        }

        guard cartViewModel.cart.mode == .delivery else { return }

        if let address = deliveryViewModel.selectedAddress {
            cartViewModel.setDeliveryAddress(address.id, address: address)
        }
    }
}

private struct CartProductRow: View {
    let item: CartItem
    let storeId: String?
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void

    @State private var showingDeleteConfirm = false
    @State private var isDeleteRevealed = false
    @State private var rowOffset: CGFloat = 0

    private var isAvailable: Bool {
        item.product.isAvailableAt(storeId: storeId)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteAction
            rowContent
                .background(BaseViewColor.background)
                .offset(x: rowOffset)
                .gesture(swipeGesture)
        }
        .clipped()
        .alert("Xoá sản phẩm?", isPresented: $showingDeleteConfirm) {
            Button("Huỷ", role: .cancel) {
                closeDelete()
            }
            Button("Xoá", role: .destructive) {
                closeDelete()
                onDelete()
            }
        } message: {
            Text("Sản phẩm này đang có số lượng 1. Bạn có muốn xoá khỏi giỏ hàng không?")
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BaseViewColor.border)
                .frame(height: 0.5)
        }
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: CartFlowMetric.productContentGap) {
            AppRemoteImage(
                url: URL(string: item.product.displayImageUrl ?? ""),
                width: CartFlowMetric.productImageSize,
                height: CartFlowMetric.productImageSize,
                cornerRadius: 0,
                backgroundColor: BaseViewColor.placeholder,
                showsProgress: true,
                placeholderIcon: nil
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: handleContentTap)

            VStack(alignment: .leading, spacing: 0) {
                Text(item.product.name)
                    .font(BaseViewFont.bodyStrong)
                    .foregroundStyle(isAvailable ? BaseViewColor.textPrimary : BaseViewColor.textSecondary)
                    .lineLimit(1)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: handleContentTap)

                if !visibleCustomizationText.isEmpty {
                    Text(visibleCustomizationText)
                        .font(BaseViewFont.label)
                        .foregroundStyle(BaseViewColor.textSecondary)
                        .lineLimit(3)
                        .padding(.top, 2)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: handleContentTap)
                }

                Spacer(minLength: 0)

                HStack(alignment: .center, spacing: 0) {
                    Text(item.totalPrice.formattedVND.uppercased())
                        .font(BaseViewFont.labelStrong)
                        .tracking(2)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: handleContentTap)

                    Spacer(minLength: CartFlowMetric.productContentGap)

                    CartQuantityControl(
                        quantity: item.quantity,
                        onDecrease: {
                            if item.quantity == 1 {
                                showingDeleteConfirm = true
                            } else {
                                onDecrease()
                            }
                        },
                        onIncrease: onIncrease
                    )
                }
                .padding(.top, CartFlowMetric.priceTopGap)
            }
            .frame(maxWidth: .infinity, minHeight: CartFlowMetric.productImageSize, alignment: .topLeading)
        }
        .padding(.horizontal, CartFlowMetric.horizontalInset)
        .padding(.vertical, CartFlowMetric.productRowVerticalPadding)
    }

    private var deleteAction: some View {
        Button {
            showingDeleteConfirm = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .regular))
                Text("Xoá")
                    .font(BaseViewFont.labelStrong)
            }
            .foregroundStyle(BaseViewColor.accentForeground)
            .frame(width: CartFlowMetric.deleteRevealWidth)
            .frame(minHeight: CartFlowMetric.productImageSize + CartFlowMetric.productRowVerticalPadding * 2)
            .background(BaseViewColor.accent)
        }
        .buttonStyle(.plain)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let baseOffset = isDeleteRevealed ? -CartFlowMetric.deleteRevealWidth : 0
                rowOffset = min(0, max(-CartFlowMetric.deleteRevealWidth, baseOffset + value.translation.width))
            }
            .onEnded { value in
                let shouldReveal = value.predictedEndTranslation.width < -CartFlowMetric.deleteRevealWidth / 2
                    || rowOffset < -CartFlowMetric.deleteRevealWidth / 2
                if shouldReveal {
                    revealDelete()
                } else {
                    closeDelete()
                }
            }
    }

    private func handleContentTap() {
        if isDeleteRevealed {
            closeDelete()
        } else {
            onEdit()
        }
    }

    private func revealDelete() {
        withAnimation(.easeOut(duration: 0.18)) {
            isDeleteRevealed = true
            rowOffset = -CartFlowMetric.deleteRevealWidth
        }
    }

    private func closeDelete() {
        withAnimation(.easeOut(duration: 0.18)) {
            isDeleteRevealed = false
            rowOffset = 0
        }
    }

    private var visibleCustomizationText: String {
        var parts: [String] = []
        if let sugar = item.customization.sugar {
            parts.append(sugar.displayName)
        }
        if let ice = item.customization.ice {
            parts.append(ice.displayName)
        }
        parts.append(contentsOf: item.customization.toppings.map(\.name))
        return parts.joined(separator: " • ")
    }
}

private struct CartQuantityControl: View {
    let quantity: Int
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: CartFlowMetric.quantityGap) {
            quantityButton(systemName: "minus", action: onDecrease)

            Text("\(quantity)")
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textPrimary)
                .frame(width: CartFlowMetric.quantityValueWidth, height: CartFlowMetric.quantityControlSize)
                .overlay {
                    Rectangle().strokeBorder(BaseViewColor.border, lineWidth: 1)
                }

            quantityButton(systemName: "plus", action: onIncrease)
        }
        .fixedSize()
    }

    private func quantityButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(BaseViewColor.accentForeground)
                .frame(width: CartFlowMetric.quantityControlSize, height: CartFlowMetric.quantityControlSize)
                .background(BaseViewColor.accent)
        }
        .buttonStyle(.plain)
    }
}

private struct StoreInfoCard: View {
    let store: Store?
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 13) {
                AppRemoteImage(
                    url: URL(string: store?.imageUrl ?? ""),
                    width: CartFlowMetric.storeImageSize,
                    height: CartFlowMetric.storeImageSize,
                    cornerRadius: 0,
                    backgroundColor: BaseViewColor.placeholder,
                    showsProgress: true,
                    placeholderIcon: nil
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text((store?.name ?? "Chọn cửa hàng").uppercased())
                        .font(BaseViewFont.bodyStrong)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .lineLimit(2)

                    Text("-- km")
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textPrimary)

                    Text(todayHoursText)
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textPrimary)
                }
                .padding(.top, 9)

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(BaseViewColor.border)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                Text(store == nil ? "CHƯA CHỌN" : "ĐÃ CHỌN")
                    .font(BaseViewFont.cta)
                    .tracking(2)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: CartFlowMetric.storeActionHeight)

                Button(action: onEdit) {
                    Text("SỬA")
                        .font(BaseViewFont.cta)
                        .tracking(2)
                        .foregroundStyle(BaseViewColor.accentForeground)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: CartFlowMetric.storeActionHeight)
                        .background(BaseViewColor.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay {
            Rectangle().strokeBorder(BaseViewColor.border, lineWidth: 1)
        }
    }

    private var todayHoursText: String {
        guard let hours = store?.openingHours?.first(where: { $0.dayOfWeek == Calendar.current.component(.weekday, from: Date()) }) else {
            return "--:-- - --:--"
        }
        return "\(hours.openTime) - \(hours.closeTime)"
    }
}

private struct DeliveryAddressCard: View {
    let address: DeliveryAddress?

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(address?.shortAddress ?? "Chọn địa chỉ giao hàng")
                .font(BaseViewFont.bodyStrong)
                .foregroundStyle(BaseViewColor.textPrimary)
                .lineLimit(1)

            Text(address?.fullAddress ?? "Bạn cần chọn địa chỉ để tính phí giao hàng.")
                .font(BaseViewFont.label)
                .foregroundStyle(BaseViewColor.textSecondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, minHeight: CartFlowMetric.addressCardMinHeight, alignment: .topLeading)
        .overlay {
            Rectangle().strokeBorder(BaseViewColor.border, lineWidth: 1)
        }
    }
}

private struct OrderingModeRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                OrderingModeIndicator(isSelected: isSelected)

                Text(title)
                    .font(BaseViewFont.body)
                    .foregroundStyle(isSelected ? BaseViewColor.textPrimary : BaseViewColor.textSecondary)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct OrderingModeIndicator: View {
    let isSelected: Bool

    var body: some View {
        Rectangle()
            .fill(isSelected ? BaseViewColor.textPrimary : Color.clear)
            .frame(width: 10, height: 10)
            .overlay {
                Rectangle()
                    .stroke(isSelected ? BaseViewColor.textPrimary : BaseViewColor.textSecondary, lineWidth: 1.5)
            }
            .rotationEffect(.degrees(45))
            .padding(3)
    }
}

struct CartCTAOverlay: View {
    let label: String
    let amount: String
    let title: String
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(BaseViewFont.labelStrong)
                    .foregroundStyle(BaseViewColor.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 16)

                Text(amount)
                    .font(BaseViewFont.sectionTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Button(action: action) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(BaseViewColor.accentForeground)
                    }

                    Text(title)
                        .font(BaseViewFont.cta)
                        .tracking(2)
                        .foregroundStyle(BaseViewColor.accentForeground)
                        .opacity(isLoading ? 0 : 1)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .frame(minHeight: CartFlowMetric.ctaButtonMinHeight)
                .background(BaseViewColor.accent)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled || isLoading)
            .opacity(isDisabled ? 0.55 : 1)
            .padding(.top, CartFlowMetric.ctaButtonTopGap)
        }
        .padding(.horizontal, CartFlowMetric.horizontalInset)
        .padding(.top, CartFlowMetric.ctaTopInset)
        .padding(.bottom, CartFlowMetric.ctaBottomInset)
        .background(BaseViewColor.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BaseViewColor.border)
                .frame(height: 0.5)
        }
    }
}

private struct CartFlowHeader: View {
    let title: String
    let backSymbol: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(BaseViewFont.screenTitle)
                .foregroundStyle(BaseViewColor.textPrimary)
                .frame(maxWidth: .infinity)

            HStack {
                Button(action: onBack) {
                    Image(systemName: backSymbol)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(BaseViewColor.accentForeground)
                        .frame(width: CartFlowMetric.navButtonSize, height: CartFlowMetric.navButtonSize)
                        .background(BaseViewColor.accent)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .frame(minHeight: CartFlowMetric.navButtonSize)
    }
}

struct EmptyCartView: View {
    let onBrowse: () -> Void

    var body: some View {
        VStack(spacing: BaseViewLayout.spacingXL) {
            Spacer()

            Text("cart_empty_title")
                .font(BaseViewFont.displayTitle)
                .foregroundStyle(BaseViewColor.textPrimary)

            Text("cart_empty_message")
                .font(BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textSecondary)

            AppButton("browse_menu_button", style: .primary, fillsWidth: false, action: onBrowse)

            Spacer()
        }
        .padding(32)
    }
}

private enum CartFlowMetric {
    static let horizontalInset: CGFloat = 23
    static let topInset: CGFloat = 23
    static let navButtonSize: CGFloat = 23
    static let headerToSectionGap: CGFloat = 28
    static let sectionToListGap: CGFloat = 20
    static let productImageSize: CGFloat = 116
    static let productContentGap: CGFloat = 13
    static let productRowVerticalPadding: CGFloat = 13
    static let priceTopGap: CGFloat = 13
    static let quantityControlSize: CGFloat = 18
    static let quantityValueWidth: CGFloat = 36
    static let quantityGap: CGFloat = 8
    static let deleteRevealWidth: CGFloat = 76
    static let contentBottomPadding: CGFloat = 140
    static let ctaTopInset: CGFloat = 23
    static let ctaButtonTopGap: CGFloat = 13
    static let ctaButtonMinHeight: CGFloat = 38
    static let ctaBottomInset: CGFloat = 23
    static let infoCardTopGap: CGFloat = 23
    static let infoSectionGap: CGFloat = 40
    static let orderingModeOptionGap: CGFloat = 22
    static let storeImageSize: CGFloat = 116
    static let storeActionHeight: CGFloat = 38
    static let addressCardMinHeight: CGFloat = 98
    static let addressButtonGap: CGFloat = 13
    static let outlineButtonVerticalPadding: CGFloat = 10
    static let outlineButtonMinHeight: CGFloat = 38
}

private enum CartFlowFont {
    static let sectionTitle = Font.custom("BeVietnamPro-Medium", size: 18)
}
