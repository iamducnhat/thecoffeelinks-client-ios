import SwiftUI

struct ProductCard: View {
    let product: Product
    var width: CGFloat? = 160
    
    @State private var showingCustomization = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            showingCustomization = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Image with gradient overlay
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { phase in
                        switch phase {
                        case .success(let img):
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: width, height: width)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        case .failure(_):
                            ZStack {
                                Color.coffeeRich.opacity(0.05)
                                Image(systemName: "cup.and.saucer.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40)
                                    .foregroundStyle(Color.coffeeRich.opacity(0.2))
                            }
                            .frame(width: width, height: width)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        case .empty:
                            ZStack {
                                Color.coffeeRich.opacity(0.05)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            }
                            .frame(width: width, height: width)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        @unknown default:
                            ZStack {
                                Color.coffeeRich.opacity(0.05)
                                Image(systemName: "cup.and.saucer.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40)
                                    .foregroundStyle(Color.coffeeRich.opacity(0.2))
                            }
                            .frame(width: width, height: width)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    
                    // Subtle gradient overlay
                    LinearGradient(
                        colors: [Color.black.opacity(0.3), Color.clear],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    // Category Badge
                    Text(product.category?.rawValue.capitalized ?? "Item")
                        .font(.brandSans(10))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandAccent)
                        .textCase(.uppercase)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brandAccent.opacity(0.1))
                        .clipShape(Capsule())
                    
                    // Product Name
                    Text(product.name)
                        .font(.brandSerif(16)) // New York Style
                        .fontWeight(.bold)
                        .foregroundStyle(Color.coffeeDark)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Price
                    Text(product.price.toVND())
                        .font(.brandSans(16))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.brandAccent)
                }
            }
            .frame(width: width)
            .padding(12)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .sheet(isPresented: $showingCustomization) {
            OrderCustomizationView(product: product)
        }
    }
}
