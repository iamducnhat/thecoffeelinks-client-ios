//
//  CheckoutView.swift
//  thecoffeelinks-native-swift
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
    @State private var showSuccess = false
    @State private var orderError: String?
    @State private var orderLog: [String] = []
    
    @State private var showEditSheet = false
    @State private var itemToEdit: CartItem? // For editing in sheet
    
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
            Color.backgroundPaper.ignoresSafeArea()
                .zIndex(-Double.infinity)
            
            if cartViewModel.cart.items.isEmpty {
                CheckoutEmptyState()
                    .onAppear {
                        print("Cart empty")
                    }
            } else {
                // Fixed Navigation Header
                HStack(alignment: .center, spacing: AppLayout.spacing) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                            .background {
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .fill(Color.backgroundPaper)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.textInk, lineWidth: min(66.6, max(scrollOffset, 0.0)) / 66.6)
                                    .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                            }
                    }
                    
                    Text("Checkout")
                        .font(AppFont.displayTitle)
                        .lineLimit(1)
                        .foregroundColor(Color.textInk)
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
                                .foregroundStyle(Color.textInk)
                                .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                                .hidden()
                            
                            Text("Checkout")
                                .font(AppFont.displayTitle)
                                .lineLimit(1)
                                .foregroundColor(Color.textInk)
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
                                    Text("Order type")
                                        .textCase(.uppercase)
                                        .font(AppFont.sectionHeader)
                                        .foregroundColor(Color.textInk)
                                    
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
                                        .foregroundStyle(Color.backgroundPaper)
                                        .background(Color.primaryEspresso)
                                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                                    }
                                }
                                
                                // Address/Location Selection
                                Button {
                                    // Show address picker
                                } label: {
                                    Text(cartViewModel.cart.mode == .delivery ? "Delivery Address" : storeViewModel.selectedStore?.name ?? "Select Location")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(AppFont.body)
                                        .foregroundStyle(Color.textTertiary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                                .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
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
                                            .fill(Color.surfaceCard) // CHANGED
                                            .overlay { // CHANGED
                                                ProgressView() // CHANGED
                                                    .tint(Color.primaryEspresso) // CHANGED
                                            } // CHANGED
                                    case .success(let image): // CHANGED
                                        image // CHANGED
                                            .resizable() // CHANGED
                                            .aspectRatio(contentMode: .fill) // CHANGED
                                    case .failure: // CHANGED
                                        Rectangle() // CHANGED
                                            .fill(Color.textInk.opacity(0.1)) // CHANGED
                                            .overlay { // CHANGED
                                                Image(systemName: "photo") // CHANGED
                                                    .font(AppFont.productTitle) // CHANGED
                                                    .foregroundStyle(Color.textInk) // CHANGED
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
                                            .foregroundColor(Color.textInk)
                                        
                                        if !item.displayCustomization.isEmpty {
                                            Text(item.displayCustomization)
                                                .font(AppFont.uiCaption)
                                                .foregroundStyle(Color.textMuted)
                                        }
                                        
                                        Spacer(minLength: AppLayout.spacing)
                                        
                                        HStack(spacing: 0) {
                                            Text(item.totalPrice.formattedCurrency)
                                                .font(AppFont.monoBody)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                                .foregroundColor(Color.primaryEspresso)
                                            
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
                                                        .foregroundStyle(Color.backgroundPaper)
                                                        .background(Color.primaryEspresso)
                                                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
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
                                                        .foregroundStyle(Color.backgroundPaper)
                                                        .background(Color.primaryEspresso)
                                                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
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
                                Text("Voucher")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundColor(Color.textInk)
                                
                                TextField("Promotion Code", text: $voucherCode)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(AppFont.monoBody)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                            .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                    }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().hidden()
                            
                            // MARK: Redeem Points Section
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("Redeem Point")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundColor(Color.textInk)
                                
                                let points = authViewModel.currentUser?.points ?? 0
                                (
                                    Text("You have \(points) points. 1 point = 1000₫. ")
                                        .foregroundColor(Color.textMuted)
                                    +
                                    Text("How to get more points?")
                                        .underline(pattern: .dot)
                                        .foregroundColor(Color.primaryEspresso)
                                )
                                .font(AppFont.body)
                                
                                TextField("Enter points to redeem", text: $redeemPoints)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(AppFont.monoBody)
                                    .keyboardType(.numberPad)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                            .stroke(Color.borderTertiary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                                    }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().hidden()
                            
                            // MARK: Payment Method Section
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("Payment Method")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundColor(Color.textInk)
                                
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
                                                .background(checkoutViewModel.paymentMethod == method ? Color.primaryEspresso : Color.clear)
                                                .foregroundColor(checkoutViewModel.paymentMethod == method ? Color.backgroundPaper : Color.textInk)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                                        .stroke(Color.border, lineWidth: 1)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
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
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(Color.semanticError)
                                    Text(error)
                                        .font(AppFont.uiMicro)
                                        .foregroundColor(Color.semanticError)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.semanticError.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.semanticError, lineWidth: 1)
                                )
                            }
                            
                            // Order Log
                            if checkoutViewModel.isPlacingOrder || !orderLog.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(orderLog, id: \.self) { log in
                                        Text("> \(log)")
                                            .font(AppFont.uiMicro)
                                            .foregroundColor(Color.primaryEspresso)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.backgroundPaper)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.primaryEspresso, lineWidth: 1)
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
                            Text("TOTAL")
                                .font(AppFont.totalLabel)
                                .lineLimit(1)
                                .foregroundColor(Color.textInk)
                            
                            Spacer(minLength: AppLayout.spacing)
                            
                            Text(cartViewModel.total.formattedCurrency)
                                .font(AppFont.monoTitle)
                                .foregroundColor(Color.textInk)
                        }
                        
                        Button {
                            placeOrder()
                        } label: {
                            Text(checkoutViewModel.isPlacingOrder ? "Placing order..." : "Place Order")
                                .font(AppFont.monoCTA)
                                .foregroundColor(Color.backgroundPaper)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.primaryEspresso)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        }
                        .disabled(checkoutViewModel.isPlacingOrder)
                    }
                    .padding(.vertical, 24)
                    .frame(minHeight: AppLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppLayout.spacing)
                    .background(Color.backgroundPaper, ignoresSafeAreaEdges: .all)
                    .background {
                        WaveRect(stepWidth: AppLayout.waveStepWidth, waveEdge: .top)
                            .fill(Color.backgroundPaper)
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
    }
    
    private func placeOrder() {
        orderLog = ["Connecting to server..."]
        orderError = nil
        
        Task {
            orderLog.append("Creating order...")
            
            if let order = await checkoutViewModel.placeOrder(cart: cartViewModel.cart) {
                orderLog.append("Order #\(order.id.prefix(8)) created successfully!")
                orderLog.append("Payment processing...")
                
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                orderLog.append("✓ Order confirmed!")
                cartViewModel.clearCart()
                DependencyContainer.shared.hapticManager.playSuccess()
                showSuccess = true
            } else if let error = checkoutViewModel.error {
                orderError = error.localizedDescription
                orderLog.append("✗ Error: \(error.localizedDescription)")
            }
        }
    }
}


// MARK: - Empty State

struct CheckoutEmptyState: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: AppLayout.spacingXL) {
            Text("Cart is empty")
                .font(AppFont.displayTitle)
                .foregroundColor(Color.textInk)
            
            Text("Your cart is empty. Please add some items before checking out.")
                .font(AppFont.body)
                .foregroundColor(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                dismiss()
            } label: {
                Text("Return to Menu")
                    .font(AppFont.monoCTA)
                    .foregroundColor(Color.backgroundPaper)
                    .padding(.vertical, 12)
                    .frame(width: 200)
                    .background(Color.primaryEspresso)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
        }
    }
}

