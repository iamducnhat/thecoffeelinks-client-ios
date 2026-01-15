//
//  ReadyToOrderCard.swift
//  thecoffeelinks-native-swift
//
//  AI-powered Ready-to-Order card for zero-thinking ordering.
//  "This is what you probably want. Do you want it or not?"
//

import SwiftUI

struct ReadyToOrderCard: View {
    @ObservedObject private var predictionEngine = PredictionEngine.shared
    @ObservedObject private var cartManager = CartManager.shared
    @EnvironmentObject var appState: AppState
    
    @State private var isExpanded = true
    @State private var showCheckoutConfirm = false
    @State private var isAddingToCart = false
    
    var body: some View {
        Group {
            if let cart = predictionEngine.readyToOrderCart {
                cardContent(cart: cart)
            } else if predictionEngine.isLoading {
                loadingState
            }
        }
        .task {
            await predictionEngine.generatePrediction()
        }
    }
    
    // MARK: - Card Content
    
    @ViewBuilder
    private func cardContent(cart: PredictedCart) -> some View {
        VStack(spacing: 0) {
            // Header with confidence indicator
            headerSection(cart: cart)
            
            if isExpanded {
                // Items preview
                itemsSection(cart: cart)
                
                // Action buttons
                actionSection(cart: cart)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.forestCanopy.opacity(0.1), radius: 16, x: 0, y: 4)
        .padding(.horizontal)
        .animation(.spring(response: 0.3), value: isExpanded)
    }
    
    private func headerSection(cart: PredictedCart) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.sunRay)
                    
                    Text(cart.reason)
                        .font(.caption)
                        .foregroundStyle(Color.neutral600)
                }
                
                Text(greetingText)
                    .font(.brandSerif(18))
                    .foregroundStyle(Color.forestCanopy)
            }
            
            Spacer()
            
            // Collapse/expand toggle
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.neutral400)
                    .frame(width: 32, height: 32)
                    .background(Color.neutral100)
                    .clipShape(Circle())
            }
        }
        .padding(16)
    }
    
    private func itemsSection(cart: PredictedCart) -> some View {
        VStack(spacing: 12) {
            ForEach(cart.items) { item in
                HStack(spacing: 12) {
                    // Product image
                    AsyncImage(url: URL(string: item.product.displayImageUrl ?? "")) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.neutral100)
                            .overlay {
                                Image(systemName: "cup.and.saucer.fill")
                                    .foregroundStyle(Color.neutral300)
                            }
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // Product info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.product.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.forestCanopy)
                        
                        Text("\(item.customization.size) • \(item.customization.sugar ?? "Normal") sugar")
                            .font(.caption)
                            .foregroundStyle(Color.neutral500)
                    }
                    
                    Spacer()
                    
                    // Price
                    Text(item.price.toVND())
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.sunRay)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private func actionSection(cart: PredictedCart) -> some View {
        VStack(spacing: 12) {
            // Primary: Add to cart and go to checkout
            Button {
                addToCartAndCheckout(cart: cart)
            } label: {
                HStack {
                    if isAddingToCart {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Yes, Order This")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    Text(cart.totalPrice.toVND())
                        .font(.headline.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.forestCanopy)
                .cornerRadius(14)
            }
            .disabled(isAddingToCart)
            
            // Secondary: Not now
            Button {
                predictionEngine.dismissPrediction()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Text("Show me something else")
                    .font(.subheadline)
                    .foregroundStyle(Color.neutral500)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var loadingState: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Thinking of your usual...")
                .font(.subheadline)
                .foregroundStyle(Color.neutral500)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func addToCartAndCheckout(cart: PredictedCart) {
        isAddingToCart = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Add all items to cart
        for item in cart.items {
            cartManager.addToCart(
                product: item.product,
                quantity: item.quantity,
                finalPrice: item.price / Double(item.quantity),
                customization: item.customization
            )
        }
        
        // Record prediction acceptance
        predictionEngine.acceptPrediction()
        
        // Short delay then trigger checkout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAddingToCart = false
            showCheckoutConfirm = true
        }
    }
    
    // MARK: - Copy
    
    private var greetingText: String {
        switch appState.timeMode {
        case .morning: return "Your morning ritual?"
        case .day: return "The usual pick-me-up?"
        case .evening: return "One for the road?"
        }
    }
}

// MARK: - Ghost Cart View (Pre-filled cart on Home)

struct GhostCartView: View {
    @ObservedObject private var predictionEngine = PredictionEngine.shared
    @ObservedObject private var cartManager = CartManager.shared
    
    @State private var isVisible = true
    
    var body: some View {
        if let cart = predictionEngine.readyToOrderCart, isVisible {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "cart.fill")
                        .foregroundStyle(Color.forestCanopy)
                    
                    Text("Your cart (auto-filled)")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.forestCanopy)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            isVisible = false
                            predictionEngine.dismissPrediction()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .foregroundStyle(Color.neutral400)
                            .frame(width: 24, height: 24)
                            .background(Color.neutral100)
                            .clipShape(Circle())
                    }
                }
                
                // Items
                ForEach(cart.items) { item in
                    HStack {
                        Text(item.product.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(item.price.toVND())
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.sunRay)
                    }
                }
                
                Divider()
                
                // Total and action
                HStack {
                    Text("Total")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(cart.totalPrice.toVND())
                        .font(.headline.bold())
                        .foregroundStyle(Color.forestCanopy)
                }
                
                // Checkout button
                Button {
                    addAllToCart(cart: cart)
                } label: {
                    Text("Checkout")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.forestCanopy)
                        .cornerRadius(12)
                }
            }
            .padding(16)
            .background(Color.filteredLight.opacity(0.3))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.forestCanopy.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
    
    private func addAllToCart(cart: PredictedCart) {
        for item in cart.items {
            cartManager.addToCart(
                product: item.product,
                quantity: item.quantity,
                finalPrice: item.price / Double(item.quantity),
                customization: item.customization
            )
        }
        predictionEngine.acceptPrediction()
    }
}

// MARK: - Preview

#Preview("Ready To Order Card") {
    ZStack {
        Color.morningFog.ignoresSafeArea()
        
        VStack {
            ReadyToOrderCard()
                .environmentObject(AppState())
            
            Spacer()
        }
        .padding(.top, 100)
    }
}
