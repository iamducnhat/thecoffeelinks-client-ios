import SwiftUI

struct CheckoutView: View {
    @ObservedObject var cartManager = CartManager.shared
    @ObservedObject var deliveryService = DeliveryService.shared
    @ObservedObject var userPreferences = UserPreferencesManager.shared
    @ObservedObject var favoritesService = FavoritesService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isPlacingOrder = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var itemToEdit: CartItem?
    @State private var showEditCustomization = false
    @State private var showAddressPicker = false
    
    // Speed optimization: Pre-fill from last order
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    
    // 30-second undo window
    @State private var showUndoToast = false
    @State private var pendingOrderId: String?
    
    let paymentMethods: [PaymentMethod] = [.cash, .card, .momo, .zalopay]
    @State private var bottomBarHeight: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.brandBackground.ignoresSafeArea()
                
                if cartManager.items.isEmpty && !showUndoToast {
                    emptyState
                } else {
                    GeometryReader { g in
                        ScrollView {
                            checkoutHeader
                            
                            sectionHeader(title: "Order Items")
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                            
                            VStack(spacing: 0) {
                                ForEach(cartManager.items) { item in
                                    SwipeToDeleteRow(
                                        onDelete: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                cartManager.removeFromCart(item: item)
                                            }
                                        }
                                    ) {
                                        cartItemRow(item: item) {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            itemToEdit = item
                                            showEditCustomization = true
                                        }
                                        .background(Color.white)
                                    }
                                    
                                    if item.id != cartManager.items.last?.id {
                                        Divider().padding(.leading, 84)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            
                            VStack(spacing: 24) {
                                // Order Type with Delivery Integration
                                orderMethodSection
                                
                                // Delivery-specific section (if delivery selected)
                                if cartManager.selectedDeliveryOption == .delivery {
                                    deliveryDetailsSection
                                }
                                
                                Divider().padding(.horizontal, 20)
                                
                                // Payment Method (Pre-filled from preferences)
                                paymentMethodSection
                                
                                Divider().padding(.horizontal, 20)
                                
                                // Notes Section with Favorite Notes Display
                                notesSection
                                
                                Color.clear.frame(height: bottomBarHeight + 40)
                            }
                            .padding(.top, 24)
                        }
                    }
                    
                    bottomActionBar
                }
                
                // 30-second Undo Toast
                if showUndoToast {
                    VStack {
                        Spacer()
                        UndoToast(
                            message: "Order placed",
                            onUndo: {
                                cancelOrder()
                            },
                            onDismiss: {
                                finalizeOrder()
                            }
                        )
                        .padding()
                        .padding(.bottom, 80)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.coffeeDark)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !cartManager.items.isEmpty {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            cartManager.clearCart()
                        }) {
                            Text("Clear All")
                                .font(.brandSans(14))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Order Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showEditCustomization) {
                if let item = itemToEdit {
                    OrderCustomizationView(product: item.product, editingItem: item)
                }
            }
            .sheet(isPresented: $showAddressPicker) {
                AddressPickerSheet { address in
                    cartManager.deliveryAddress = address.fullAddress
                    deliveryService.selectAddress(address)
                }
            }
            .onAppear {
                // Pre-fill payment method from last order
                if let lastMethod = userPreferences.lastPaymentMethod {
                    selectedPaymentMethod = PaymentMethod(rawValue: lastMethod) ?? .cash
                }
                
                // Auto-select delivery address if delivery mode
                if cartManager.selectedDeliveryOption == .delivery {
                    deliveryService.autoSelectAddress()
                    if let addr = deliveryService.selectedAddress {
                        cartManager.deliveryAddress = addr.fullAddress
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 72, weight: .light))
                .foregroundColor(.neutral300)
            
            VStack(spacing: 8) {
                Text("Your cart is empty")
                    .font(.brandSerif(24))
                    .foregroundColor(.coffeeDark)
                
                Text("Add some delicious items to get started")
                    .font(.brandSans(14))
                    .foregroundColor(.neutral500)
            }
            
            LiquidGlassPrimaryButton("Browse Menu") {
                dismiss()
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header
    
    var checkoutHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Checkout")
                .font(.brandSerif(32))
                .foregroundColor(.coffeeDark)
            
            HStack {
                Text("\(cartManager.totalItemCount) item\(cartManager.totalItemCount > 1 ? "s" : "") in your order")
                    .font(.brandSans(14))
                    .foregroundColor(.neutral500)
                
                Spacer()
                
                // Cart badge for visibility
                HStack(spacing: 4) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 12))
                    Text("\(cartManager.totalItemCount)")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.forestCanopy)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Cart Item Row with Inline Editing
    
    func cartItemRow(item: CartItem, onProductTap: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: item.product.displayImageUrl ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.neutral200)
                }
                .frame(width: 56, height: 56)
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.product.name)
                            .font(.brandSans(16))
                            .fontWeight(.medium)
                            .foregroundColor(.coffeeDark)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Favorite indicator
                        if favoritesService.isProductFavorited(item.product) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                    }
                    
                    // Inline customization tags
                    HStack(spacing: 4) {
                        Text(item.customization.size)
                            .inlineTag()
                        
                        if let ice = item.customization.ice {
                            Text(ice)
                                .inlineTag()
                        }
                        
                        if let sugar = item.customization.sugar {
                            Text(sugar)
                                .inlineTag()
                        }
                    }
                    
                    // Display notes from favorites (read-only)
                    if let favorite = favoritesService.getFavorite(product: item.product, customization: item.customization),
                       let notesText = favorite.notesDisplay {
                        NotesDisplayBadge(notes: notesText)
                    }
                    
                    if let toppings = item.customization.toppings, !toppings.isEmpty {
                        Text("+ \(toppings.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.neutral500)
                            .lineLimit(1)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.neutral400)
            }
            .contentShape(Rectangle())
            .onTapGesture { onProductTap() }
            
            // Bottom row: Price and Inline Quantity Editor
            HStack {
                Text(item.finalPrice.toVND())
                    .font(.brandSans(16))
                    .fontWeight(.semibold)
                    .foregroundColor(.brandAccent)
                
                Spacer()
                
                // Inline quantity editor with delete option
                InlineQuantityEditor(
                    quantity: .init(
                        get: { item.quantity },
                        set: { newQty in updateQuantity(for: item, to: newQty) }
                    ),
                    onDelete: {
                        withAnimation { cartManager.removeFromCart(item: item) }
                    }
                )
            }
        }
        .padding(16)
    }
    
    // MARK: - Order Method Section with DeliveryModeToggle
    
    var orderMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Order Type")
            
            DeliveryModeToggle(selectedMode: $cartManager.selectedDeliveryOption)
            
            if cartManager.selectedDeliveryOption == .dineIn {
                HStack(spacing: 12) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 18))
                        .foregroundColor(.neutral400)
                    
                    TextField("Table Number (Optional)", text: $cartManager.deliveryNotes)
                        .font(.brandSans(15))
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.neutral200, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .onChange(of: cartManager.selectedDeliveryOption) { newValue in
            if newValue == .delivery {
                deliveryService.autoSelectAddress()
                if let addr = deliveryService.selectedAddress {
                    cartManager.deliveryAddress = addr.fullAddress
                }
            }
        }
    }
    
    // MARK: - Delivery Details Section (ETA, Fees, Address)
    
    var deliveryDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Delivery Details")
            
            VStack(spacing: 12) {
                // Address Row
                Button {
                    showAddressPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.forestCanopy)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if let address = deliveryService.selectedAddress {
                                Text(address.label)
                                    .font(.caption)
                                    .foregroundStyle(Color.neutral500)
                                Text(address.fullAddress)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.coffeeDark)
                                    .lineLimit(1)
                            } else if !cartManager.deliveryAddress.isEmpty {
                                Text(cartManager.deliveryAddress)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.coffeeDark)
                            } else {
                                Text("Select delivery address")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.red)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.neutral400)
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                // ETA Row
                if let etaDisplay = deliveryService.etaDisplay {
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 18))
                            .foregroundColor(.neutral400)
                        
                        Text(etaDisplay)
                            .font(.subheadline)
                            .foregroundStyle(Color.coffeeDark)
                        
                        Spacer()
                        
                        // Delivery trust signal
                        DeliveryTrustSignal(text: "Tracked delivery")
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                // Delivery Fee Row
                if deliveryService.deliveryFee > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: "bicycle")
                            .font(.system(size: 18))
                            .foregroundColor(.neutral400)
                        
                        Text("Delivery Fee")
                            .font(.subheadline)
                            .foregroundStyle(Color.coffeeDark)
                        
                        Spacer()
                        
                        Text(deliveryService.feeDisplay)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.brandAccent)
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                // Zone warning
                if !deliveryService.isInDeliveryZone {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("This address is outside our delivery zone")
                            .font(.caption)
                            .foregroundStyle(Color.orange)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(cartManager.deliveryAddress.isEmpty ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Payment Method Section (Pre-filled)
    
    var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Payment Method")
                
                // Show "remembered" indicator
                if userPreferences.lastPaymentMethod != nil {
                    Text("(remembered)")
                        .font(.caption)
                        .foregroundStyle(Color.neutral500)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(paymentMethods, id: \.self) { method in
                    paymentCard(method: method, isSelected: selectedPaymentMethod == method) {
                        selectedPaymentMethod = method
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Notes Section
    
    var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Special Instructions")
            
            TextField("Add notes for your order (optional)", text: $cartManager.deliveryNotes, axis: .vertical)
                .font(.brandSans(15))
                .lineLimit(3...5)
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.neutral200, lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Bottom Action Bar
    
    var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    breakdownRow(label: "Subtotal", value: cartManager.totalAmount)
                    
                    if cartManager.selectedDeliveryOption == .delivery && deliveryService.deliveryFee > 0 {
                        breakdownRow(label: "Delivery Fee", value: deliveryService.deliveryFee)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.brandSerif(18))
                            .foregroundColor(.coffeeDark)
                        Spacer()
                        Text(totalWithDelivery.toVND())
                            .font(.brandSerif(22))
                            .fontWeight(.bold)
                            .foregroundColor(.coffeeDark)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: totalWithDelivery)
                    }
                }
                
                LiquidGlassPrimaryButton(
                    "Place Order",
                    icon: "arrow.right",
                    isLoading: isPlacingOrder,
                    isDisabled: !isOrderValid
                ) {
                    placeOrder()
                }
            }
            .padding(20)
            .background(Color.brandBackground.opacity(0.95))
            .background(.ultraThinMaterial)
        }
        .onGeometryChange(for: CGFloat.self) { geo in
            geo.size.height
        } action: { newValue in
            bottomBarHeight = newValue
        }
    }
    
    var totalWithDelivery: Double {
        var total = cartManager.totalAmount
        if cartManager.selectedDeliveryOption == .delivery {
            total += deliveryService.deliveryFee
        }
        return total
    }
    
    var isOrderValid: Bool {
        !cartManager.items.isEmpty &&
        (cartManager.selectedDeliveryOption != .delivery || (!cartManager.deliveryAddress.isEmpty && deliveryService.isInDeliveryZone))
    }
    
    // MARK: - Components
    
    func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.brandSerif(14).bold())
            .foregroundColor(.coffeeDark)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func paymentCard(method: PaymentMethod, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: methodIcon(for: method))
                    .font(.system(size: 20))
                
                Text(method.rawValue.capitalized)
                    .font(.brandSans(14))
                    .fontWeight(.medium)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.sage)
                }
            }
            .foregroundColor(isSelected ? .coffeeDark : .neutral600)
            .padding(14)
            .background(isSelected ? Color.sage.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.sage : Color.neutral200, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
    
    func breakdownRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.brandSans(14))
                .foregroundColor(.neutral500)
            Spacer()
            Text(value.toVND())
                .font(.brandSans(14))
                .foregroundColor(.coffeeDark)
        }
    }
    
    func methodIcon(for method: PaymentMethod) -> String {
        switch method {
        case .cash: return "banknote"
        case .card: return "creditcard"
        case .momo: return "m.square"
        case .zalopay: return "z.square"
        }
    }
    
    // MARK: - Actions
    
    func updateQuantity(for item: CartItem, to newQuantity: Int) {
        if let index = cartManager.items.firstIndex(where: { $0.id == item.id }) {
            if newQuantity >= 1 && newQuantity <= 99 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    cartManager.items[index].quantity = newQuantity
                }
            }
        }
    }
    
    func placeOrder() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        isPlacingOrder = true
        
        // Remember payment method
        userPreferences.lastPaymentMethod = selectedPaymentMethod.rawValue
        
        Task {
            do {
                let service = OrderService()
                let total = totalWithDelivery
                
                let token = try await service.verifyPayment(
                    amount: total,
                    paymentMethod: selectedPaymentMethod.rawValue,
                    storeId: cartManager.selectedStoreId,
                    items: cartManager.items
                )
                
                let orderId = try await service.createOrder(
                    items: cartManager.items,
                    total: total,
                    deliveryOption: cartManager.selectedDeliveryOption,
                    storeId: cartManager.selectedStoreId,
                    deliveryAddress: cartManager.deliveryAddress.isEmpty ? nil : cartManager.deliveryAddress,
                    deliveryNotes: cartManager.deliveryNotes.isEmpty ? nil : cartManager.deliveryNotes,
                    paymentMethod: selectedPaymentMethod,
                    paymentToken: token
                )
                
                // Record for learning
                let context = PredictionContext()
                FavoritesService.shared.recordOrder(items: cartManager.items)
                PredictionEngine.shared.recordOrder(items: cartManager.items, context: context)
                
                // Show undo toast instead of immediate success
                pendingOrderId = orderId
                withAnimation(.spring(response: 0.3)) {
                    showUndoToast = true
                }
                
            } catch {
                print("Order placement error: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
            isPlacingOrder = false
        }
    }
    
    func cancelOrder() {
        // Cancel the pending order
        if let orderId = pendingOrderId {
            Task {
                do {
                    try await OrderService().cancelOrder(orderId: orderId)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } catch {
                    print("Failed to cancel order: \(error)")
                }
            }
        }
        
        withAnimation {
            showUndoToast = false
        }
        pendingOrderId = nil
    }
    
    func finalizeOrder() {
        // Order confirmed, clear cart and dismiss
        withAnimation {
            showUndoToast = false
        }
        cartManager.clearCart()
        dismiss()
    }
}

// MARK: - Address Picker Sheet

struct AddressPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var deliveryService = DeliveryService.shared
    
    let onSelect: (DeliveryAddress) -> Void
    
    @State private var newAddressText = ""
    @State private var newAddressLabel = "Home"
    @State private var showingNewAddress = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBackground.ignoresSafeArea()
                
                if deliveryService.savedAddresses.isEmpty && !showingNewAddress {
                    emptyState
                } else {
                    List {
                        if !deliveryService.savedAddresses.isEmpty {
                            Section("Saved Addresses") {
                                ForEach(deliveryService.savedAddresses) { address in
                                    Button {
                                        onSelect(address)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(address.label)
                                                    .font(.caption.bold())
                                                    .foregroundStyle(Color.forestCanopy)
                                                Text(address.fullAddress)
                                                    .font(.subheadline)
                                                    .foregroundStyle(Color.coffeeDark)
                                                    .lineLimit(2)
                                            }
                                            
                                            Spacer()
                                            
                                            if address.isDefault {
                                                Text("Default")
                                                    .font(.caption2)
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.forestCanopy)
                                                    .cornerRadius(4)
                                            }
                                        }
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            deliveryService.deleteAddress(address.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        
                        Section("Add New Address") {
                            VStack(spacing: 12) {
                                HStack {
                                    ForEach(["Home", "Work", "Other"], id: \.self) { label in
                                        Button {
                                            newAddressLabel = label
                                        } label: {
                                            Text(label)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(newAddressLabel == label ? Color.forestCanopy : Color.neutral100)
                                                .foregroundStyle(newAddressLabel == label ? .white : Color.coffeeDark)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                
                                TextField("Enter full address", text: $newAddressText, axis: .vertical)
                                    .lineLimit(2...4)
                                
                                Button {
                                    guard !newAddressText.isEmpty else { return }
                                    let newAddress = DeliveryAddress(
                                        label: newAddressLabel,
                                        fullAddress: newAddressText,
                                        isDefault: deliveryService.savedAddresses.isEmpty
                                    )
                                    deliveryService.addAddress(newAddress)
                                    onSelect(newAddress)
                                    dismiss()
                                } label: {
                                    Text("Add & Use This Address")
                                        .font(.subheadline.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(newAddressText.isEmpty ? Color.neutral300 : Color.forestCanopy)
                                        .foregroundStyle(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(newAddressText.isEmpty)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Delivery Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.neutral300)
            
            Text("No saved addresses")
                .font(.headline)
            
            Button {
                showingNewAddress = true
            } label: {
                Text("Add Your First Address")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.forestCanopy)
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - Helper Extensions

extension Text {
    func inlineTag() -> some View {
        self
            .font(.caption2)
            .foregroundColor(.neutral600)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.neutral100)
            .cornerRadius(4)
    }
}

// MARK: - Swipe to Delete Row Component

struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    let content: () -> Content
    
    @State private var offset: CGFloat = 0
    
    private let deleteButtonWidth: CGFloat = 80
    private let swipeThreshold: CGFloat = -40
    
    init(onDelete: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.onDelete = onDelete
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                content()
                    .frame(width: geometry.size.width)
                    .background(Color.white)
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        offset = -geometry.size.width
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onDelete()
                    }
                } label: {
                    ZStack {
                        Color.red
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: max(deleteButtonWidth, -offset))
            }
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if offset == 0 && gesture.translation.width > 0 { return }
                        
                        if offset < 0 && gesture.translation.width > 0 {
                            let newOffset = offset + gesture.translation.width
                            if newOffset > -deleteButtonWidth / 2 {
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                    offset = 0
                                }
                                return
                            }
                            self.offset = min(0, newOffset)
                            return
                        }
                        
                        if gesture.translation.width < 0 {
                            offset = gesture.translation.width
                        }
                    }
                    .onEnded { gesture in
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                            if offset < swipeThreshold {
                                if offset < -geometry.size.width * 0.6 {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        offset = -geometry.size.width
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        onDelete()
                                    }
                                } else {
                                    offset = -deleteButtonWidth
                                }
                                return
                            }
                            offset = 0
                        }
                    }
            )
        }
        .frame(height: 140)
        .clipped()
    }
}
