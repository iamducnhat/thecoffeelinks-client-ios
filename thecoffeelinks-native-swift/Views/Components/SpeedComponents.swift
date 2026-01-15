//
//  SpeedComponents.swift
//  thecoffeelinks-native-swift
//
//  Reusable UI components for ultra-fast ordering.
//  Includes: FavoriteButton, PopularityBadge, UndoToast, OrderAgainButton, etc.
//

import SwiftUI

// MARK: - Favorite Button (Heart Toggle)

struct FavoriteButton: View {
    let product: Product
    let customization: OrderCustomization
    @ObservedObject private var favoritesService = FavoritesService.shared
    @State private var isAnimating = false
    
    private var isFavorite: Bool {
        favoritesService.isFavorite(product: product, customization: customization)
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isAnimating = true
                favoritesService.toggleFavorite(product: product, customization: customization)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 20))
                .foregroundStyle(isFavorite ? Color.red : Color.neutral400)
                .scaleEffect(isAnimating ? 1.3 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

/// Simpler version for product-only (any customization)
struct FavoriteButtonSimple: View {
    let product: Product
    @ObservedObject private var favoritesService = FavoritesService.shared
    
    private var hasAnyFavorite: Bool {
        favoritesService.isProductFavorited(product)
    }
    
    var body: some View {
        Image(systemName: hasAnyFavorite ? "heart.fill" : "heart")
            .font(.system(size: 16))
            .foregroundStyle(hasAnyFavorite ? Color.red : Color.neutral400)
    }
}

// MARK: - Popularity Badge

struct PopularityBadge: View {
    let orderCount: Int
    let showCount: Bool
    
    init(orderCount: Int, showCount: Bool = false) {
        self.orderCount = orderCount
        self.showCount = showCount
    }
    
    var body: some View {
        if orderCount >= 5 { // Anti-herd: only show if truly popular
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                if showCount {
                    Text("\(orderCount) today")
                        .font(.system(size: 10, weight: .medium))
                }
            }
            .foregroundStyle(Color.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Regular Status Badge

struct RegularStatusBadge: View {
    let orderCount: Int
    
    var statusText: String {
        switch orderCount {
        case 0..<10: return ""
        case 10..<25: return "Regular"
        case 25..<50: return "Loyal"
        case 50..<100: return "VIP"
        default: return "Legend"
        }
    }
    
    var statusColor: Color {
        switch orderCount {
        case 0..<10: return .clear
        case 10..<25: return .forestCanopy
        case 25..<50: return .brandAccent
        case 50..<100: return .brandPremium
        default: return .sunRay
        }
    }
    
    var body: some View {
        if orderCount >= 10 {
            Text(statusText)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Undo Toast (30-second cancel window)

struct UndoToast: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void
    
    @State private var progress: Double = 1.0
    @State private var timer: Timer?
    
    private let duration: Double = 30.0
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 28, height: 28)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
            
            Button("UNDO") {
                timer?.invalidate()
                onUndo()
            }
            .font(.subheadline.bold())
            .foregroundStyle(Color.sunRay)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.forestCanopy)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        let interval = 0.1
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                progress -= interval / duration
                if progress <= 0 {
                    timer?.invalidate()
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Order Again Button

struct OrderAgainButton: View {
    let order: Order
    let onReorder: () async -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        Button {
            Task {
                isLoading = true
                await onReorder()
                isLoading = false
            }
        } label: {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text("Order Again")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.forestCanopy)
            .cornerRadius(8)
        }
        .disabled(isLoading)
    }
}

// MARK: - Quick Checkout Button

struct QuickCheckoutButton: View {
    let title: String
    let subtitle: String?
    let price: Double
    let isLoading: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(price.toVND())
                        .font(.headline.bold())
                        .foregroundStyle(Color.sunRay)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.forestCanopy)
            .cornerRadius(16)
        }
        .disabled(isLoading)
    }
}

// MARK: - Delivery Mode Toggle

struct DeliveryModeToggle: View {
    @Binding var selectedMode: DeliveryOption
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([DeliveryOption.takeAway, .dineIn, .delivery], id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMode = mode
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: iconFor(mode))
                            .font(.system(size: 18))
                        Text(labelFor(mode))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selectedMode == mode ? Color.white : Color.neutral600)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedMode == mode ? Color.forestCanopy : Color.clear)
                    .cornerRadius(12)
                }
            }
        }
        .padding(4)
        .background(Color.neutral100)
        .cornerRadius(16)
    }
    
    private func iconFor(_ mode: DeliveryOption) -> String {
        switch mode {
        case .takeAway: return "bag"
        case .dineIn: return "fork.knife"
        case .delivery: return "bicycle"
        }
    }
    
    private func labelFor(_ mode: DeliveryOption) -> String {
        switch mode {
        case .takeAway: return "Pickup"
        case .dineIn: return "Dine In"
        case .delivery: return "Delivery"
        }
    }
}

// MARK: - Inline Cart Quantity Editor

struct InlineQuantityEditor: View {
    @Binding var quantity: Int
    let minQuantity: Int
    let maxQuantity: Int
    let onDelete: (() -> Void)?
    
    init(quantity: Binding<Int>, min: Int = 1, max: Int = 10, onDelete: (() -> Void)? = nil) {
        self._quantity = quantity
        self.minQuantity = min
        self.maxQuantity = max
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if quantity > minQuantity {
                    quantity -= 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else if let onDelete = onDelete {
                    onDelete()
                }
            } label: {
                Image(systemName: quantity <= minQuantity && onDelete != nil ? "trash" : "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(quantity <= minQuantity && onDelete == nil ? Color.neutral300 : Color.forestCanopy)
                    .frame(width: 28, height: 28)
                    .background(Color.neutral100)
                    .clipShape(Circle())
            }
            .disabled(quantity <= minQuantity && onDelete == nil)
            
            Text("\(quantity)")
                .font(.system(size: 16, weight: .semibold))
                .frame(minWidth: 24)
            
            Button {
                if quantity < maxQuantity {
                    quantity += 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(quantity >= maxQuantity ? Color.neutral300 : Color.forestCanopy)
                    .frame(width: 28, height: 28)
                    .background(Color.neutral100)
                    .clipShape(Circle())
            }
            .disabled(quantity >= maxQuantity)
        }
    }
}

// MARK: - Notes Display (Read-only for checkout)

struct NotesDisplayBadge: View {
    let notes: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "note.text")
                .font(.system(size: 10))
            Text(notes)
                .font(.system(size: 11))
                .lineLimit(1)
        }
        .foregroundStyle(Color.neutral600)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.neutral100)
        .cornerRadius(6)
    }
}

// MARK: - Delivery Trust Signal

struct DeliveryTrustSignal: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.successGreen)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Color.neutral600)
        }
    }
}

// MARK: - Previews

#Preview("Favorite Button") {
    let product = Product(
        id: "1",
        name: "Iced Latte",
        description: nil,
        category: "coffee",
        categoryId: nil,
        categoryType: nil,
        image: nil,
        imageUrl: nil,
        isPopular: true,
        isNew: nil,
        isActive: true,
        isAvailable: true,
        isDeliverable: nil,
        deliveryPrepMinutes: nil,
        sizeOptions: ProductSizeOptions(
            small: SizeOption(enabled: true, price: 49000),
            medium: SizeOption(enabled: true, price: 59000),
            large: SizeOption(enabled: true, price: 69000)
        ),
        availableToppings: nil
    )
    
    let customization = OrderCustomization(size: "M", ice: "normal", sugar: "50", toppings: nil)
    
    FavoriteButton(product: product, customization: customization)
        .padding()
}

#Preview("Undo Toast") {
    ZStack {
        Color.morningFog.ignoresSafeArea()
        
        VStack {
            Spacer()
            UndoToast(
                message: "Order placed",
                onUndo: { print("Undo tapped") },
                onDismiss: { print("Dismissed") }
            )
            .padding()
        }
    }
}

#Preview("Delivery Mode Toggle") {
    DeliveryModeToggle(selectedMode: .constant(.takeAway))
        .padding()
}
