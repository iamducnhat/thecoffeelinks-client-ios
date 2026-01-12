import SwiftUI

struct ProductCard: View {
    let product: Product
    var width: CGFloat? = 160
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Color.coffeeRich.opacity(0.05)
                    Image(systemName: "cup.and.saucer.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40)
                        .foregroundStyle(Color.coffeeRich.opacity(0.2))
                }
            }
            .frame(width: width, height: width) // Square image
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.brandSerif(16)) // New York Style
                    .fontWeight(.bold)
                    .foregroundStyle(Color.coffeeDark)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(product.category?.rawValue.capitalized ?? "Item")
                    .font(.brandSans(12))
                    .foregroundStyle(Color.secondary)
                    .textCase(.uppercase)
                    .padding(.top, 2)
                
                HStack {
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.brandSans(16))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.brandAccent)
                    
                    Spacer()
                    
                    // Add Button (Visual only for now)
                    Circle()
                        .fill(Color.coffeeDark)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                }
                .padding(.top, 4)
            }
        }
        .frame(width: width)
        .padding(12)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
