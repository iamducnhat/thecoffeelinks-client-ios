import SwiftUI

struct CheckoutView: View {
    @ObservedObject var cartManager = CartManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isPlacingOrder = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var itemToEdit: CartItem?
    @State private var showEditCustomization = false
    
    // Payment Options
    let paymentMethods: [PaymentMethod] = [.cash, .card, .momo, .zalopay]
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    @State private var bottomBarHeight: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.brandBackground.ignoresSafeArea()
                
                if cartManager.items.isEmpty {
                    emptyState
                } else {
                    GeometryReader { g in
                        ScrollView {
                            // Header
                            checkoutHeader
                            
                            // Order Items Section Header (app style)
                            sectionHeader(title: "Order Items")
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                            
                            // Custom List-style view with swipe-to-delete
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
                                        Divider()
                                            .padding(.leading, 84)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            
                            // Other sections outside List
                            VStack(spacing: 24) {
                                // Order Method Section
                                orderMethodSection
                                
                                Divider().padding(.horizontal, 20)
                                
                                // Payment Method Section
                                paymentMethodSection
                                
                                Divider().padding(.horizontal, 20)
                                
                                // Notes Section
                                notesSection
                                
                                // Bottom Spacer
                                Color.clear.frame(height: bottomBarHeight + 40)
                            }
                            .padding(.top, 24)
                        }
                    }
                    
                    // Bottom Action Bar
                    bottomActionBar
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
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    cartManager.clearCart()
                    dismiss()
                }
            } message: {
                Text("Your order has been placed successfully.")
            }
            .sheet(isPresented: $showEditCustomization) {
                if let item = itemToEdit {
                    OrderCustomizationView(product: item.product, editingItem: item)
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
            
            Text("\(cartManager.totalItemCount) item\(cartManager.totalItemCount > 1 ? "s" : "") in your order")
                .font(.brandSans(14))
                .foregroundColor(.neutral500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Cart Item Row
    
    func cartItemRow(item: CartItem, onProductTap: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            // Product area - tappable for edit
            HStack(alignment: .top, spacing: 12) {
                // Product Image
                AsyncImage(url: URL(string: item.product.displayImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.neutral200)
                }
                .frame(width: 56, height: 56)
                .cornerRadius(10)
                
                // Product Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product.name)
                        .font(.brandSans(16))
                        .fontWeight(.medium)
                        .foregroundColor(.coffeeDark)
                        .lineLimit(1)
                    
                    // Customization details
                    HStack(spacing: 4) {
                        Text(item.customization.size)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.neutral100)
                            .cornerRadius(4)
                        
                        if let ice = item.customization.ice {
                            Text(ice)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.neutral100)
                                .cornerRadius(4)
                        }
                        
                        if let sugar = item.customization.sugar {
                            Text(sugar)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.neutral100)
                                .cornerRadius(4)
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.neutral600)
                    
                    if let toppings = item.customization.toppings, !toppings.isEmpty {
                        Text("+ \(toppings.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.neutral500)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Edit indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.neutral400)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onProductTap()
            }
            
            // Bottom row: Price and Quantity
            HStack {
                // Price
                Text(item.finalPrice.toVND())
                    .font(.brandSans(16))
                    .fontWeight(.semibold)
                    .foregroundColor(.brandAccent)
                
                Spacer()
                
                // Quantity Stepper
                HStack(spacing: 12) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        updateQuantity(for: item, delta: -1)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(item.quantity > 1 ? .coffeeDark : .neutral300)
                            .frame(width: 28, height: 28)
                            .background(Color.neutral100)
                            .cornerRadius(8)
                    }
                    .disabled(item.quantity <= 1)
                    
                    Text("\(item.quantity)")
                        .font(.brandSans(16))
                        .fontWeight(.bold)
                        .foregroundColor(.coffeeDark)
                        .frame(minWidth: 20)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        updateQuantity(for: item, delta: 1)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.coffeeDark)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
    }
    
    // MARK: - Order Method Section
    
    var orderMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Order Type")
            
            Picker("Method", selection: $cartManager.selectedDeliveryOption) {
                Text("Take Away").tag(DeliveryOption.takeAway)
                Text("Dine In").tag(DeliveryOption.dineIn)
                Text("Delivery").tag(DeliveryOption.delivery)
            }
            .pickerStyle(.segmented)
            .onChange(of: cartManager.selectedDeliveryOption) { _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
            // Conditional input based on order type
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
            } else if cartManager.selectedDeliveryOption == .delivery {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.neutral400)
                    
                    TextField("Delivery Address", text: $cartManager.deliveryAddress)
                        .font(.brandSans(15))
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cartManager.deliveryAddress.isEmpty ? Color.red.opacity(0.5) : Color.neutral200, lineWidth: 1)
                )
                
                if cartManager.deliveryAddress.isEmpty {
                    Text("Please enter a delivery address")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // Order Method Content (for List section)
    var orderMethodContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Method", selection: $cartManager.selectedDeliveryOption) {
                Text("Take Away").tag(DeliveryOption.takeAway)
                Text("Dine In").tag(DeliveryOption.dineIn)
                Text("Delivery").tag(DeliveryOption.delivery)
            }
            .pickerStyle(.segmented)
            .onChange(of: cartManager.selectedDeliveryOption) { _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
            if cartManager.selectedDeliveryOption == .dineIn {
                HStack(spacing: 12) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 18))
                        .foregroundColor(.neutral400)
                    
                    TextField("Table Number (Optional)", text: $cartManager.deliveryNotes)
                        .font(.brandSans(15))
                }
                .padding(14)
                .background(Color.neutral100)
                .cornerRadius(12)
            } else if cartManager.selectedDeliveryOption == .delivery {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.neutral400)
                        
                        TextField("Delivery Address", text: $cartManager.deliveryAddress)
                            .font(.brandSans(15))
                    }
                    .padding(14)
                    .background(Color.neutral100)
                    .cornerRadius(12)
                    
                    if cartManager.deliveryAddress.isEmpty {
                        Text("Please enter a delivery address")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    // MARK: - Payment Method Section
    
    var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Payment Method")
            
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
    
    // Payment Method Content (for List section)
    var paymentMethodContent: some View {
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
    
    // Notes Content (for List section)
    var notesContent: some View {
        TextField("Add notes for your order (optional)", text: $cartManager.deliveryNotes, axis: .vertical)
            .font(.brandSans(15))
            .lineLimit(3...5)
    }
    
    // MARK: - Bottom Action Bar
    
    var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 16) {
                // Price Breakdown
                VStack(spacing: 8) {
                    breakdownRow(label: "Subtotal", value: cartManager.totalAmount)
                    // Tax is included in price
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.brandSerif(18))
                            .foregroundColor(.coffeeDark)
                        Spacer()
                        Text(cartManager.totalAmount.toVND())
                            .font(.brandSerif(22))
                            .fontWeight(.bold)
                            .foregroundColor(.coffeeDark)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: cartManager.totalAmount)
                    }
                }
                
                // Place Order Button
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
    
    var isOrderValid: Bool {
        !cartManager.items.isEmpty &&
        (cartManager.selectedDeliveryOption != .delivery || !cartManager.deliveryAddress.isEmpty)
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
    
    func updateQuantity(for item: CartItem, delta: Int) {
        if let index = cartManager.items.firstIndex(where: { $0.id == item.id }) {
            let newQuantity = cartManager.items[index].quantity + delta
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
        
        Task {
            do {
                let service = OrderService()
                let total = cartManager.totalAmount
                
                // 1. Verify Payment
                let token = try await service.verifyPayment(
                    amount: total,
                    paymentMethod: selectedPaymentMethod.rawValue,
                    storeId: cartManager.selectedStoreId,
                    items: cartManager.items
                )
                
                // 2. Create Order
                print("Payment verified, token: \(token)")
                
                _ = try await service.createOrder(
                    items: cartManager.items,
                    total: total,
                    deliveryOption: cartManager.selectedDeliveryOption,
                    storeId: cartManager.selectedStoreId,
                    deliveryAddress: cartManager.deliveryAddress.isEmpty ? nil : cartManager.deliveryAddress,
                    deliveryNotes: cartManager.deliveryNotes.isEmpty ? nil : cartManager.deliveryNotes,
                    paymentMethod: selectedPaymentMethod,
                    paymentToken: token
                )
                
                showSuccess = true
            } catch {
                print("Order placement error: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
            isPlacingOrder = false
        }
    }
}
// MARK: - Swipe to Delete Row Component
// Based on https://stackoverflow.com/a/76980028 by Ihor Chernysh

struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    let content: () -> Content
    
    @State private var offset: CGFloat = 0
    
    private let deleteButtonWidth: CGFloat = 80
    private let swipeThreshold: CGFloat = -40 // Minimum swipe to show button
    
    init(onDelete: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.onDelete = onDelete
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main content
                content()
                    .frame(width: geometry.size.width)
                    .background(Color.white)
                
                // Delete button
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
                        // Prevent swipe to the right in default position
                        if offset == 0 && gesture.translation.width > 0 {
                            return
                        }
                        
                        // If already swiped and dragging right
                        if offset < 0 && gesture.translation.width > 0 {
                            let newOffset = offset + gesture.translation.width
                            
                            // If dragged far enough right, reset to zero
                            if newOffset > -deleteButtonWidth / 2 {
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                    offset = 0
                                }
                                return
                            }
                            
                            // Otherwise update the offset
                            self.offset = min(0, newOffset)
                            return
                        }
                        
                        // Swiping left - allow unlimited stretch like native
                        if gesture.translation.width < 0 {
                            offset = gesture.translation.width
                        }
                    }
                    .onEnded { gesture in
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                            // If swiped far enough, lock at delete button width
                            if offset < swipeThreshold {
                                // If swiped way past, trigger delete
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
                            
                            // Not swiped enough, reset
                            offset = 0
                        }
                    }
            )
        }
        .frame(height: 120)
        .clipped()
    }
}
