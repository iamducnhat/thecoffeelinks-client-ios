//
//  QuickOrderWidget.swift
//  thecoffeelinks-native-swift
//
//  Premium Lounge Host - Quick Order Widget
//  2-tap ordering for returning users
//

import SwiftUI

// MARK: - Quick Order Widget

struct QuickOrderWidget: View {
    @StateObject private var quickOrderService = QuickOrderService.shared
    @ObservedObject private var cartManager = CartManager.shared
    @EnvironmentObject var appState: AppState
    
    @State private var showCheckoutSheet = false
    @State private var selectedItem: QuickOrderItem?
    @State private var showAddedFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with streak
            headerSection
            
            if quickOrderService.yourUsuals.isEmpty {
                emptyState
            } else {
                // Quick order cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(quickOrderService.yourUsuals) { item in
                            QuickOrderCard(
                                item: item,
                                onTap: { handleQuickAdd(item) },
                                onLongPress: { handleQuickCheckout(item) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.forestCanopy.opacity(0.08), radius: 16, x: 0, y: 4)
        .padding(.horizontal)
        .overlay(alignment: .topTrailing) {
            if showAddedFeedback {
                addedFeedbackBadge
            }
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingCopy)
                    .font(.brandSerif(18))
                    .foregroundStyle(Color.forestCanopy)
                
                if quickOrderService.currentStreak > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(Color.sunRay)
                        Text("\(quickOrderService.currentStreak) days strong")
                            .font(.caption)
                            .foregroundStyle(Color.neutral600)
                    }
                }
            }
            
            Spacer()
            
            if !quickOrderService.yourUsuals.isEmpty {
                Text("Tap to add • Hold for instant order")
                    .font(.caption2)
                    .foregroundStyle(Color.neutral500)
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer")
                .font(.title2)
                .foregroundStyle(Color.neutral400)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Your favorites will appear here")
                    .font(.subheadline)
                    .foregroundStyle(Color.neutral600)
                Text("Order something to get started")
                    .font(.caption)
                    .foregroundStyle(Color.neutral500)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.neutral100)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var addedFeedbackBadge: some View {
        Text("Noted.")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.forestCanopy)
            .cornerRadius(12)
            .padding(8)
            .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Greeting Copy (Premium Lounge Host)
    
    private var greetingCopy: String {
        switch appState.timeMode {
        case .morning:
            if quickOrderService.yourUsuals.isEmpty {
                return "Rise and grind"
            } else {
                return "Your morning ritual"
            }
        case .day:
            if quickOrderService.yourUsuals.isEmpty {
                return "Afternoon push"
            } else {
                return "Need a lift?"
            }
        case .evening:
            if quickOrderService.yourUsuals.isEmpty {
                return "Winding down?"
            } else {
                return "The usual?"
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleQuickAdd(_ item: QuickOrderItem) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Add to cart
        _ = quickOrderService.quickReorder(item: item)
        
        // Show feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showAddedFeedback = true
        }
        
        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showAddedFeedback = false
            }
        }
    }
    
    private func handleQuickCheckout(_ item: QuickOrderItem) {
        // Strong haptic for instant checkout
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        selectedItem = item
        showCheckoutSheet = true
    }
}

// MARK: - Quick Order Card

struct QuickOrderCard: View {
    let item: QuickOrderItem
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image
            if let imageURL = item.product.image, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        productPlaceholder
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                productPlaceholder
            }
            
            // Product info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.forestCanopy)
                    .lineLimit(1)
                
                Text(item.priceForSize.toVND())
                    .font(.caption)
                    .foregroundStyle(Color.neutral600)
            }
            
            // Customization badges
            if let sugar = item.customization.sugar, sugar != "normal" {
                HStack(spacing: 4) {
                    Text(sugar.capitalized)
                        .font(.caption2)
                        .foregroundStyle(Color.neutral500)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.neutral100)
                        .cornerRadius(4)
                }
            }
        }
        .padding(12)
        .frame(width: 120)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.neutral200, lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }) {
            onLongPress()
        }
    }
    
    private var productPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.neutral100)
            .frame(width: 80, height: 80)
            .overlay {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title2)
                    .foregroundStyle(Color.neutral300)
            }
    }
}

// MARK: - Quick Checkout Sheet (1-tap confirm)

struct QuickCheckoutSheet: View {
    let item: QuickOrderItem
    let onConfirm: () async -> Bool
    let onDismiss: () -> Void
    
    @State private var isProcessing = false
    @State private var orderSuccess = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.sunRay)
                
                Text("Instant Order")
                    .font(.brandSerif(24))
                    .foregroundStyle(Color.forestCanopy)
                
                Text("One tap. We're on it.")
                    .font(.subheadline)
                    .foregroundStyle(Color.neutral600)
            }
            
            // Order summary
            HStack(spacing: 16) {
                // Product image
                if let imageURL = item.product.image, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.neutral100
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.forestCanopy)
                    
                    Text("\(item.customization.size) • \(item.customization.sugar?.capitalized ?? "Normal")")
                        .font(.caption)
                        .foregroundStyle(Color.neutral600)
                }
                
                Spacer()
                
                Text(item.priceForSize.toVND())
                    .font(.title3.bold())
                    .foregroundStyle(Color.sunRay)
            }
            .padding()
            .background(Color.neutral50)
            .cornerRadius(16)
            
            // Store info
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.filteredLight)
                Text("Nearest store")
                    .font(.subheadline)
                    .foregroundStyle(Color.neutral600)
                Spacer()
                Text("Auto-selected")
                    .font(.caption)
                    .foregroundStyle(Color.neutral500)
            }
            
            Spacer()
            
            // Confirm button
            if orderSuccess {
                successState
            } else {
                LiquidGlassPrimaryButton(
                    "Confirm Order",
                    icon: "checkmark",
                    isLoading: isProcessing,
                    tint: .forestCanopy
                ) {
                    Task {
                        isProcessing = true
                        let success = await onConfirm()
                        isProcessing = false
                        
                        if success {
                            // Success haptic
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                orderSuccess = true
                            }
                            
                            // Dismiss after celebration
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                onDismiss()
                            }
                        }
                    }
                }
            }
            
            // Cancel
            if !orderSuccess {
                Button("Not now") {
                    onDismiss()
                }
                .font(.subheadline)
                .foregroundStyle(Color.neutral500)
            }
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private var successState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.successGreen)
            
            Text("Perfect. We're on it.")
                .font(.headline)
                .foregroundStyle(Color.forestCanopy)
            
            Text("Your order is being prepared")
                .font(.subheadline)
                .foregroundStyle(Color.neutral600)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Preview

#Preview("Quick Order Widget - With Items") {
    VStack {
        QuickOrderWidget()
            .environmentObject(AppState())
    }
    .background(Color.morningFog)
}

#Preview("Quick Order Widget - Empty") {
    VStack {
        QuickOrderWidget()
            .environmentObject(AppState())
    }
    .background(Color.morningFog)
}
