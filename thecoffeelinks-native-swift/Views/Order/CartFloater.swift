import SwiftUI

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
    
    var body: some View {
        Button {
            showCheckout = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Cart • \(cartManager.totalAmount.toVND())")
                            .font(.footnote.bold())
                            .foregroundStyle(.primary)
                        Text("\(cartManager.items.count) item\(cartManager.items.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Group {
                        Text("Checkout")
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote.bold())                        
                }
                .padding(.horizontal)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showCheckout) {
            CheckoutView()
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
                            .fill(Color.brandAccent.gradient)
                            .frame(width: 36, height: 36)
                        
                        Text("\(cartManager.items.count)")
                            .font(.brandSans(14))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .shadow(color: Color.brandAccent.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Ready to order?")
                            .font(.brandSans(12))
                            .foregroundStyle(Color.secondary)
                        
                        Text(cartManager.totalAmount.toVND())
                            .font(.brandSerif(18))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.brandPrimary)
                    }
                    
                    Spacer()
                    
                    // Checkout Button
                    HStack(spacing: 6) {
                        Text("Checkout")
                            .font(.brandSans(15))
                            .fontWeight(.bold)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.brandAccent.gradient)
                    .clipShape(Capsule())
                    .shadow(color: Color.brandAccent.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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
                CheckoutView()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
