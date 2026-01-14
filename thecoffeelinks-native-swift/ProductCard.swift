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
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .empty:
                                ZStack {
                                    Color.coffeeRich.opacity(0.05)
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                }
                                .frame(width: width, height: width)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Subtle gradient overlay
                    LinearGradient(
                        colors: [Color.black.opacity(0.15), Color.clear],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    
                    // Available Sizes
                    if !product.availableSizes.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(product.availableSizes, id: \.size) { size in
                                Text(size.size.prefix(1))
                                    .font(.brandSans(10))
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.coffeeDark.opacity(0.6))
                                    .frame(width: 18, height: 18)
                                    .background(Color.coffeeRich.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    // Price - show medium price or first available
                    if let sizeOptions = product.sizeOptions {
                        let displayPrice: Double? = {
                            if sizeOptions.medium.enabled {
                                return sizeOptions.medium.price
                            } else if sizeOptions.large.enabled {
                                return sizeOptions.large.price
                            } else if sizeOptions.small.enabled {
                                return sizeOptions.small.price
                            }
                            return nil
                        }()
                        
                        if let price = displayPrice {
                            Text(price.toVND())
                                .font(.brandSans(16))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.brandAccent)
                        }
                    } else {
                        Text("Price varies")
                            .font(.brandSans(14))
                            .foregroundStyle(Color.secondary)
                    }
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
