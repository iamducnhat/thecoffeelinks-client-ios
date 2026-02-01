import SwiftUI

/// Refactored StoresView - Design System v2
/// Clean list with capsule search and view toggle
struct StoresView: View {
    @EnvironmentObject var viewModel: StoresViewModel
    @State private var selectedStore: Store?
    @State private var viewMode = 0 // 0: List, 1: Map
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppSpacing.lg) {
                    SectionHeader(title: "Stores", subtitle: "Find a location near you")
                        .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Search
                    CapsuleTextField(
                        placeholder: "Search by name or address...",
                        text: $viewModel.searchQuery,
                        icon: "magnifyingglass"
                    )
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // View mode toggle
                    CapsuleSegmentedPicker(
                        selection: $viewMode,
                        options: [
                            (0, "List"),
                            (1, "Map")
                        ]
                    )
                    .padding(.horizontal, AppSpacing.screenPadding)
                    
                    Divider().background(Color.borderSecondary)
                }
                .padding(.top, AppSpacing.sm)
                .background(Color.bgPrimary)
                
                // Content
                if viewModel.filteredStores.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    if viewMode == 0 {
                        listView
                    } else {
                        mapView
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedStore) { store in
            StoreDetailView(store: store, viewModel: viewModel)
        }
        .onAppear {
            Task { await viewModel.load() }
        }
    }
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(viewModel.filteredStores) { store in
                    StoreCard_v2(store: store, viewModel: viewModel)
                        .onTapGesture {
                            selectedStore = store
                        }
                }
            }
            .padding(AppSpacing.screenPadding)
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        StoreMapView(
            stores: viewModel.filteredStores,
            selectedStore: $selectedStore
        )
        .padding(AppSpacing.screenPadding)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.textTertiary)
            
            Text("No stores found")
                .font(AppTypography.displayMedium)
                .foregroundStyle(Color.textPrimary)
            
            Text("Try adjusting your search")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxHeight: .infinity)
        .padding(AppSpacing.xxl)
    }
}

// MARK: - Store Card v2

struct StoreCard_v2: View {
    let store: Store
    let viewModel: StoresViewModel
    
    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            // Store image
            if let imageUrl = store.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        Rectangle()
                            .fill(Color.surfacePrimary)
                            .overlay {
                                ProgressView()
                                    .tint(Color.textTertiary)
                            }
                    case .failure:
                        Rectangle()
                            .fill(Color.surfacePrimary)
                            .overlay {
                                Image(systemName: "building.2")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.textTertiary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
            } else {
                Rectangle()
                    .fill(Color.surfacePrimary)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "building.2")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(store.name)
                    .font(AppTypography.labelLarge)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                
                Text(store.address)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                
                // Distance calculation would go here if location services enabled
                // For now, hide distance display
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(AppSpacing.lg)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(Color.borderSecondary, lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    StoresView()
        .environmentObject(DependencyContainer.shared.makeStoresViewModel())
}
