import SwiftUI

struct CheckoutView: View {
    @ObservedObject var cartManager = CartManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isPlacingOrder = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Payment Options
    let paymentMethods: [PaymentMethod] = [.cash, .card, .momo, .zalopay]
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea()
                
                if cartManager.items.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.coffeeDark)
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
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "basket")
                .font(.system(size: 64))
                .foregroundColor(.neutral400)
            Text("Your cart is empty")
                .font(.brandSerif(20))
                .foregroundColor(.coffeeDark)
            Button("Browse Menu") { dismiss() }
                .foregroundColor(.brandAccent)
        }
    }
    
    var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 1. Order Method
                sectionHeader("Order Method")
                VStack(spacing: 12) {
                    Picker("Method", selection: $cartManager.selectedDeliveryOption) {
                        Text("Take Away").tag(DeliveryOption.takeAway)
                        Text("Dine In").tag(DeliveryOption.dineIn)
                        Text("Delivery").tag(DeliveryOption.delivery)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if cartManager.selectedDeliveryOption == .dineIn { // Dine In - Table input could go here
                        TextField("Table Number (Optional)", text: $cartManager.deliveryNotes)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    } else if cartManager.selectedDeliveryOption == .delivery { // Delivery Address
                        TextField("Delivery Address", text: $cartManager.deliveryAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                }
                
                // 2. Order Summary
                sectionHeader("Order Summary")
                VStack(spacing: 16) {
                    ForEach(cartManager.items) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(item.quantity)x")
                                .font(.brandSans(14))
                                .fontWeight(.bold)
                                .foregroundColor(.brandAccent)
                                .frame(width: 30, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.product.name)
                                    .font(.brandSans(16))
                                    .foregroundColor(.coffeeDark)
                                
                                Text("\(item.customization.size) • \(item.customization.ice) Ice • \(item.customization.sugar) Sugar")
                                    .font(.caption)
                                    .foregroundColor(.neutral600)
                                
                                if let toppings = item.customization.toppings, !toppings.isEmpty {
                                    Text(item.toppingsString)
                                        .font(.caption)
                                        .foregroundColor(.neutral500)
                                        .italic()
                                }
                            }
                            
                            Spacer()
                            
                            Text((item.finalPrice * Double(item.quantity)).toVND())
                                .font(.brandSans(15))
                                .foregroundColor(.coffeeDark)
                        }
                        .padding(.horizontal)
                        
                        Divider().padding(.leading, 58)
                    }
                }
                .padding(.vertical)
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 3. Payment Method
                sectionHeader("Payment Method")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(paymentMethods, id: \.self) { method in
                            paymentCard(method: method, isSelected: selectedPaymentMethod == method) {
                                selectedPaymentMethod = method
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 4. Breakdown
                VStack(spacing: 12) {
                    breakdownRow(label: "Subtotal", value: cartManager.totalAmount)
                    breakdownRow(label: "Tax (8%)", value: cartManager.totalAmount * 0.08)
                    Divider()
                    HStack {
                        Text("Total")
                            .font(.brandSerif(20))
                            .foregroundColor(.coffeeDark)
                        Spacer()
                        Text((cartManager.totalAmount * 1.08).toVND())
                            .font(.brandSerif(20))
                            .fontWeight(.bold)
                            .foregroundColor(.coffeeDark)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 5. Place Order Button
                Button(action: placeOrder) {
                    if isPlacingOrder {
                        ProgressView().tint(.white)
                    } else {
                        Text("Place Order")
                            .font(.brandSans(18))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.coffeeDark)
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.bottom, 24)
                .disabled(isPlacingOrder || (cartManager.selectedDeliveryOption == .delivery && cartManager.deliveryAddress.isEmpty))
                .opacity(isPlacingOrder ? 0.7 : 1)
            }
        }
    }
    
    // MARK: - Components
    
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.brandSans(18))
            .fontWeight(.semibold)
            .foregroundColor(.coffeeDark)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 8)
    }
    
    func paymentCard(method: PaymentMethod, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: methodIcon(for: method))
                    .font(.system(size: 24))
                Text(method.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .ivory : .coffeeDark)
            .frame(width: 100, height: 80)
            .background(isSelected ? Color.coffeeDark : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.coffeeDark : Color.neutral300, lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.coffeeDark.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
        }
    }
    
    func breakdownRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.brandSans(15))
                .foregroundColor(.neutral600)
            Spacer()
            Text(value.toVND())
                .font(.brandSans(15))
                .foregroundColor(.coffeeDark)
        }
    }
    
    func methodIcon(for method: PaymentMethod) -> String {
        switch method {
        case .cash: return "banknote"
        case .card: return "creditcard"
        case .momo: return "m.square" // system icon placeholder
        case .zalopay: return "z.square" // system icon placeholder
        }
    }
    
    // MARK: - Actions
    
    func placeOrder() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        isPlacingOrder = true
        
        Task {
            do {
                let service = OrderService()
                let total = cartManager.totalAmount * 1.08 // Include tax
                
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
