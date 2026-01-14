import SwiftUI
import Combine

// MARK: - Cart Accessory Modifier (handles iOS version availability)
struct CartAccessoryModifier: ViewModifier {
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: isEnabled) {
                CartAccessoryView()
            }
        } else {
            content
        }
    }
}

// MARK: - iOS 26+ Tab Bar Bottom Accessory
@available(iOS 26, *)
struct CartAccessoryView: View {
    @ObservedObject var cartManager = CartManager.shared
    @State private var showCheckout = false
    @State private var isPressed = false
    
    var body: some View {
        Button {
            showCheckout = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack(spacing: 12) {
                // Item count badge
                ZStack {
                    Circle()
                        .fill(Color.sunRay)
                        .frame(width: 28, height: 28)
                    
                    Text("\(cartManager.totalItemCount)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.forestCanopy)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    // Premium microcopy
                    Text(cartCopy)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(cartManager.totalAmount.toVND())
                        .font(.footnote.bold())
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // CTA
                HStack(spacing: 4) {
                    Text("Let's wrap this up")
                        .font(.caption.bold())
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .foregroundStyle(Color.forestCanopy)
            }
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .sheet(isPresented: $showCheckout) {
            StreamlinedCheckoutView()
        }
    }
    
    private var cartCopy: String {
        let count = cartManager.totalItemCount
        if count == 1 {
            return "1 item ready"
        } else {
            return "\(count) items ready"
        }
    }
}

// MARK: - Legacy iOS < 26 Floating Cart
struct CartFloater: View {
    @ObservedObject var cartManager = CartManager.shared
    @State private var showCheckout = false
    @State private var isPressed = false
    
    var body: some View {
        if !cartManager.items.isEmpty {
            Button(action: {
                showCheckout = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                HStack(spacing: 16) {
                    // Item Counter Badge
                    ZStack {
                        Circle()
                            .fill(Color.sunRay.gradient)
                            .frame(width: 40, height: 40)
                        
                        Text("\(cartManager.totalItemCount)")
                            .font(.brandSans(16))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.forestCanopy)
                    }
                    .shadow(color: Color.sunRay.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Premium microcopy
                        Text(cartCopy)
                            .font(.brandSans(12))
                            .foregroundStyle(Color.neutral600)
                        
                        Text(cartManager.totalAmount.toVND())
                            .font(.brandSerif(18))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.forestCanopy)
                    }
                    
                    Spacer()
                    
                    // Checkout Button - Premium copy
                    HStack(spacing: 6) {
                        Text("Wrap it up")
                            .font(.brandSans(14))
                            .fontWeight(.bold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.forestCanopy.gradient)
                    .clipShape(Capsule())
                    .shadow(color: Color.forestCanopy.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white)
                        .shadow(color: Color.forestCanopy.opacity(0.08), radius: 16, x: 0, y: 4)
                }
                .scaleEffect(isPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 60)
            .sheet(isPresented: $showCheckout) {
                StreamlinedCheckoutView()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private var cartCopy: String {
        let count = cartManager.totalItemCount
        if count == 1 {
            return "1 item • Ready when you are"
        } else {
            return "\(count) items • Ready when you are"
        }
    }
}

// MARK: - Streamlined Checkout View (Single Screen)

struct StreamlinedCheckoutView: View {
    @ObservedObject var cartManager = CartManager.shared
    @ObservedObject var paymentStore = SavedPaymentStore.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isPlacingOrder = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Edit Mode State
    @State private var itemToEdit: CartItem?
    @State private var showCustomization = false
    
    // Voucher State
    @State private var voucherCode = ""
    @State private var isApplyingVoucher = false
    
    // Payment Confirmation
    @State private var showPaymentConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.morningFog.ignoresSafeArea()
                
                if cartManager.items.isEmpty {
                    emptyState
                } else if showSuccess {
                    successState
                } else {
                    checkoutContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Clear Cart
                if !cartManager.items.isEmpty && !showSuccess {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            cartManager.clearCart()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.neutral500)
                        }
                    }
                }
            }
            .sheet(item: $itemToEdit) { item in
                OrderCustomizationView(product: item.product, editingItem: item)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Main Content
    
    private var checkoutContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header
                    
                    // Order Summary (compact)
                    orderSummarySection
                    
                    // Voucher Section
                    voucherSection
                    
                    // Payment Method (saved)
                    paymentSection
                    
                    // Store/Pickup Info
                    pickupSection
                    
                    Spacer().frame(height: 120)
                }
                .padding(.top, 16)
            }
            
            // Bottom CTA
            checkoutButton
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Let's wrap this up")
                .font(.brandSerif(28))
                .foregroundStyle(Color.forestCanopy)
            
            Text("\(cartManager.totalItemCount) item\(cartManager.totalItemCount > 1 ? "s" : "") • \(cartManager.totalAmount.toVND())")
                .font(.subheadline)
                .foregroundStyle(Color.neutral600)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Order Summary
    
    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Your order")
            
            VStack(spacing: 0) {
                ForEach(cartManager.items) { item in
                    orderItemRow(item)
                        .background(Color.white)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    cartManager.removeFromCart(item: item)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    
                    if item.id != cartManager.items.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.forestCanopy.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
    }
    
    private func orderItemRow(_ item: CartItem) -> some View {
        HStack(spacing: 12) {
            // Edit Tap Area
            Button {
                itemToEdit = item
            } label: {
                HStack(spacing: 12) {
                    // Image or Placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.neutral100)
                        .frame(width: 48, height: 48)
                        .overlay {
                            if let url = item.product.displayImageUrl {
                                AsyncImage(url: URL(string: url)) { img in
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.neutral200
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Product info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.product.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.forestCanopy)
                            .lineLimit(1)
                        
                        Text("\(item.customization.size) • \(item.customization.sugar ?? "Normal")")
                            .font(.caption)
                            .foregroundStyle(Color.neutral500)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Quantity Stepper
            HStack(spacing: 0) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        cartManager.updateQuantity(item: item, delta: -1)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption2)
                        .frame(width: 28, height: 28)
                        .background(Color.neutral100)
                        .foregroundStyle(Color.coffeeDark)
                        .clipShape(Circle())
                }
                
                Text("\(item.quantity)")
                    .font(.subheadline.monospacedDigit())
                    .frame(minWidth: 24)
                    .multilineTextAlignment(.center)
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        cartManager.updateQuantity(item: item, delta: 1)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption2)
                        .frame(width: 28, height: 28)
                        .background(Color.coffeeDark)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            }
            
            // Price
            Text((item.finalPrice * Double(item.quantity)).toVND())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.forestCanopy)
                .frame(minWidth: 70, alignment: .trailing)
        }
        .padding(14)
    }
    
    // MARK: - Voucher Section
    
    private var voucherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Promo Code")
            
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .foregroundColor(.brandAccent)
                
                TextField("Enter voucher code", text: $voucherCode)
                    .textInputAutocapitalization(.characters)
                    .submitLabel(.done)
                    .onSubmit {
                        Task { await applyVoucher() }
                    }
                
                if isApplyingVoucher {
                    ProgressView()
                } else if cartManager.discountAmount > 0 {
                    Button {
                        // Remove voucher
                        cartManager.discountAmount = 0
                        voucherCode = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button("Apply") {
                        Task { await applyVoucher() }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(voucherCode.isEmpty ? Color.secondary : Color.brandAccent)
                    .disabled(voucherCode.isEmpty)
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            
            if let error = cartManager.voucherError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func applyVoucher() async {
        isApplyingVoucher = true
        await cartManager.applyVoucher(voucherCode)
        isApplyingVoucher = false
    }
    
    // MARK: - Payment Section
    
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Payment")
                Spacer()
                if paymentStore.savedMethods.count > 1 {
                    Button("Change") {
                        // Show payment picker logic
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color.forestCanopy)
                }
            }
            
            // Saved payment display
            Button {
                 // Confirm Payment Method trigger
                 // For now just consistent UI
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: paymentStore.selectedMethod.icon)
                        .font(.title3)
                        .foregroundStyle(Color.forestCanopy)
                        .frame(width: 44, height: 44)
                        .background(Color.filteredLight.opacity(0.3))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(paymentStore.selectedMethod.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.forestCanopy)
                        
                        Text("Default method")
                            .font(.caption)
                            .foregroundStyle(Color.neutral500)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.neutral400)
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.forestCanopy.opacity(0.04), radius: 8, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Pickup Section
    
    private var pickupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Pickup")
            
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.sunRay)
                    .frame(width: 44, height: 44)
                    .background(Color.sunRay.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nearest store")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.forestCanopy)
                    
                    Text("Ready in ~5 min")
                        .font(.caption)
                        .foregroundStyle(Color.neutral500)
                }
                
                Spacer()
                
                // Order type toggle
                Picker("Type", selection: $cartManager.selectedDeliveryOption) {
                    Text("Pickup").tag(DeliveryOption.takeAway)
                    Text("Dine In").tag(DeliveryOption.dineIn)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.forestCanopy.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Checkout Button
    
    private var checkoutButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 12) {
                // Total Breakdown
                VStack(spacing: 4) {
                    HStack {
                        Text("Subtotal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(cartManager.totalAmount.toVND())
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                    
                    if cartManager.discountAmount > 0 {
                        HStack {
                            Text("Discount")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Spacer()
                            Text("- " + cartManager.discountAmount.toVND())
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    HStack {
                        Text("Total")
                            .font(.subheadline)
                            .foregroundStyle(Color.neutral600)
                        Spacer()
                        Text((cartManager.totalAmount - cartManager.discountAmount).toVND())
                            .font(.title3.bold())
                            .foregroundStyle(Color.forestCanopy)
                            .contentTransition(.numericText())
                    }
                }
                
                // CTA Button
                Button {
                    showPaymentConfirmation = true
                } label: {
                    HStack {
                        if isPlacingOrder {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Place Order")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.forestCanopy.gradient)
                    .cornerRadius(16)
                }
                .disabled(isPlacingOrder)
                .confirmationDialog("Confirm Payment", isPresented: $showPaymentConfirmation, titleVisibility: .visible) {
                    Button("Pay with \(paymentStore.selectedMethod.displayName)") {
                        placeOrder()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Your card will be charged \((cartManager.totalAmount - cartManager.discountAmount).toVND())")
                }
            }
            .padding(20)
            .background(Color.white)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "cup.and.saucer")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color.neutral300)
            
            VStack(spacing: 8) {
                Text("Ready when you are")
                    .font(.brandSerif(22))
                    .foregroundStyle(Color.forestCanopy)
                
                Text("Add something delicious to get started")
                    .font(.subheadline)
                    .foregroundStyle(Color.neutral500)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Browse Menu")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.forestCanopy)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.filteredLight.opacity(0.3))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Success State
    
    private var successState: some View {
        VStack(spacing: 24) {
            // Success animation
            if #available(iOS 17.0, *) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.successGreen)
                    .symbolEffect(.bounce, value: showSuccess)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.successGreen)
            }
            
            VStack(spacing: 8) {
                Text("Perfect. We're on it.")
                    .font(.brandSerif(24))
                    .foregroundStyle(Color.forestCanopy)
                
                Text("Order #8291 • Being prepared")
                    .font(.subheadline)
                    .foregroundStyle(Color.neutral600)
            }
            
            // Estimated time
            HStack(spacing: 8) {
                Image(systemName: "clock")
                Text("Ready in ~5 minutes")
            }
            .font(.subheadline)
            .foregroundStyle(Color.neutral500)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.neutral100)
            .cornerRadius(20)
            
            Button {
                // In real app, persist order receipt to User Store logic here
                cartManager.clearCart()
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.forestCanopy.gradient)
                    .cornerRadius(25)
            }
            .padding(.top, 16)
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Helpers
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(Color.neutral500)
            .textCase(.uppercase)
            .tracking(0.5)
    }
    
    // MARK: - Actions
    
    private func placeOrder() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        Task {
            let success = await cartManager.placeOrder()
            
            await MainActor.run {
                if success {
                    // Success haptic
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showSuccess = true
                    }
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    errorMessage = cartManager.checkoutError ?? "Something went wrong"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Saved Payment Store

class SavedPaymentStore: ObservableObject {
    static let shared = SavedPaymentStore()
    
    @Published var savedMethods: [SavedPaymentMethod] = [
        SavedPaymentMethod(type: .applePay, displayName: "Apple Pay", isDefault: true),
        SavedPaymentMethod(type: .card, displayName: "•••• 4242", isDefault: false)
    ]
    
    var selectedMethod: SavedPaymentMethod {
        savedMethods.first(where: { $0.isDefault }) ?? savedMethods.first!
    }
    
    private init() {
        loadSavedMethods()
    }
    
    private func loadSavedMethods() {
        // Load from UserDefaults or Keychain in production
    }
    
    func setDefault(_ method: SavedPaymentMethod) {
        for i in savedMethods.indices {
            savedMethods[i].isDefault = (savedMethods[i].id == method.id)
        }
    }
}

struct SavedPaymentMethod: Identifiable {
    let id = UUID()
    let type: PaymentType
    let displayName: String
    var isDefault: Bool
    
    var icon: String {
        switch type {
        case .applePay: return "apple.logo"
        case .card: return "creditcard.fill"
        case .cash: return "banknote"
        case .momo: return "m.circle.fill"
        }
    }
    
    enum PaymentType {
        case applePay, card, cash, momo
    }
}

// MARK: - Preview

#Preview("Cart Floater") {
    ZStack {
        Color.morningFog.ignoresSafeArea()
        
        VStack {
            Spacer()
            CartFloater()
        }
    }
}

#Preview("Streamlined Checkout") {
    StreamlinedCheckoutView()
}
