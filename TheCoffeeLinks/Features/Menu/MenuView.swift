import SwiftUI

/// Refactored MenuView - Design System v2
/// Capsule search, simplified categories, clean grid
struct MenuView: View {
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var selectedProduct: Product?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with search
                VStack(spacing: AppSpacing.lg) {
                    // Search field
                    CapsuleTextField(
                        placeholder: "Search menu...",
                        text: $menuViewModel.searchQuery,
                        icon: "magnifyingglass"
                    )
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            CategoryChip(
                                title: "All",
                                isSelected: menuViewModel.selectedCategory == nil
                            ) {
                                menuViewModel.selectCategory(nil)
                            }
                            
                            ForEach(menuViewModel.categories) { category in
                                CategoryChip(
                                    title: category.displayName,
                                    isSelected: menuViewModel.selectedCategory == category
                                ) {
                                    menuViewModel.selectCategory(category)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    
                    Divider()
                        .background(Color.borderSecondary)
                }
                .padding(.top, AppSpacing.sm)
                .background(Color.bgPrimary)
                
                // Product Grid
                ScrollView {
                    if menuViewModel.isLoading && menuViewModel.filteredProducts.isEmpty {
                        ProductGridSkeleton()
                    } else if menuViewModel.filteredProducts.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: AppSpacing.lg),
                                GridItem(.flexible(), spacing: AppSpacing.lg)
                            ],
                            spacing: AppSpacing.lg
                        ) {
                            ForEach(menuViewModel.filteredProducts) { product in
                                ProductCard_v2(product: product)
                                    .onTapGesture {
                                        selectedProduct = product
                                    }
                            }
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, AppSpacing.lg)
                        .padding(.bottom, cartViewModel.isEmpty ? AppSpacing.xl : 100)
                    }
                }
                .refreshable {
                    await menuViewModel.refresh()
                }
            }
        }
        .sheet(item: $selectedProduct) { product in
            ProductDetailSheet(product: product)
        }
        .onAppear {
            Task { await menuViewModel.load() }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.textTertiary)
            
            Text("No items found")
                .font(AppTypography.displayMedium)
                .foregroundStyle(Color.textPrimary)
            
            Text("Try adjusting your search or filters")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xxl)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.labelMedium)
                .foregroundStyle(isSelected ? Color.white : Color.textSecondary)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? Color.white.opacity(0.2) : Color.surfacePrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.white.opacity(0.3) : Color.borderPrimary, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Product Card v2

struct ProductCard_v2: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Image
            GeometryReader { geo in
                let size = geo.size.width
                AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.surfacePrimary)
                            .overlay {
                                ProgressView()
                                    .tint(Color.textTertiary)
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.surfacePrimary)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.textTertiary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
            .aspectRatio(1, contentMode: .fit)
            
            // Name
            Text(product.name)
                .font(AppTypography.labelLarge)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Price
            if let mediumPrice = product.sizeOptions.first(where: { $0.size == .medium })?.price {
                Text(mediumPrice.formattedVND)
                    .font(AppTypography.monoMedium)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MenuView()
        .environmentObject(DependencyContainer.shared.makeMenuViewModel())
        .environmentObject(DependencyContainer.shared.makeCartViewModel())
}
