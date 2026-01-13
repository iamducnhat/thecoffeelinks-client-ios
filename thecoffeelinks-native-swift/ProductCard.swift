import SwiftUI

struct ProductCard: View {
    let product: Product
    var width: CGFloat? = 160
    
    @State private var showingCustomization = false
    
    var body: some View {
        Button(action: {
            showingCustomization = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Image with gradient overlay
                ZStack(alignment: .bottomLeading) {
                    if let imageUrl = product.displayImageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: width, height: width)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            case .failure:
                                ZStack {
                                    Color.coffeeRich.opacity(0.05)
                                    Image("coffee")
                                        .resizable()
                                        .renderingMode(.template)
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
                                    Image("coffee")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40)
                                        .foregroundStyle(Color.coffeeRich.opacity(0.2))
                                }
                                .frame(width: width, height: width)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                    } else {
                        ZStack {
                            Color.coffeeRich.opacity(0.05)
                            Image("coffee")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40)
                                .foregroundStyle(Color.coffeeRich.opacity(0.2))
                        }
                        .frame(width: width, height: width)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }

                    // Subtle gradient overlay
                    LinearGradient(
                        colors: [Color.black.opacity(0.15), Color.clear],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                Spacer(minLength: 0)
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    // Category Badge
                    Text(product.category?.capitalized ?? "Item")
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
        }
        .buttonStyle(ProductCardButtonStyle())
        .sheet(isPresented: $showingCustomization) {
            OrderCustomizationView(product: product)
        }
    }
}

struct ProductCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
