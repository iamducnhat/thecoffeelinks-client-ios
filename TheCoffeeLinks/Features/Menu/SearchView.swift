//
//  SearchView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import Combine

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    @EnvironmentObject private var cartViewModel: CartViewModel
    @State private var showingProductDetail: Product?
    @State private var scrollOffset = CGFloat.zero
    @Environment(\.dismiss) var dismiss
    
    init(productRepository: ProductRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(productRepository: productRepository))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .padding(12)
                        .background {
                            Circle()
                                .fill(BaseViewColor.background)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(BaseViewColor.border, lineWidth: 1)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
                
                Text(String(localized: "common_search"))
                    .font(BaseViewFont.sectionTitle)
                    .lineLimit(1)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .fixedSize()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: BaseViewLayout.touchTarget)
            .padding(.horizontal, BaseViewLayout.spacing)
            .padding(.top, 8)
            .zIndex(1)
            .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Navigation Header (Scrollable)
                    VStack(spacing: BaseViewLayout.marginCompact) {
                        HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(BaseViewColor.textPrimary)
                                .padding(12)
                                .hidden()
                            
                            Text(String(localized: "common_search"))
                                .font(BaseViewFont.sectionTitle)
                                .lineLimit(1)
                                .foregroundColor(BaseViewColor.textPrimary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                        
                        Divider()
                            .background(BaseViewColor.borderSecondary)
                            .padding(.horizontal, -BaseViewLayout.spacing)
                    }
                    .padding(.horizontal, BaseViewLayout.spacing)
                    .padding(.top, BaseViewLayout.spacingCompact)
                    .background(BaseViewColor.background)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    // Search Bar
                    HStack(spacing: BaseViewLayout.spacingMedium) {
                        Image("magnifyingglass")
                            .font(BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.textSecondary)
                        
                        TextField("Search products...", text: $viewModel.searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(BaseViewFont.body)
                            .foregroundStyle(BaseViewColor.textPrimary)
                        
                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                            } label: {
                                Image("circle_x")
                                    .font(BaseViewFont.body)
                                    .foregroundStyle(BaseViewColor.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, BaseViewLayout.badgeInset)
                    .frame(height: 49)
                    .background(BaseViewColor.elevatedSurface)
                    .padding(.horizontal, BaseViewLayout.spacing)
                    
                    Color.secondary.frame(height: 1)
                        .padding(.top, BaseViewLayout.spacing)
                        .padding(.horizontal, BaseViewLayout.spacing)
                    
                    if viewModel.searchQuery.isEmpty {
                        // Recent Searches
                        if !viewModel.recentSearches.isEmpty {
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                Text(String(localized: "common_recent"))
                                    .textCase(.uppercase)
                                    .font(BaseViewFont.labelStrong)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                
                                VStack(spacing: 0) {
                                    ForEach(Array(viewModel.recentSearches.enumerated()), id: \.element) { index, query in
                                        Button {
                                            viewModel.searchQuery = query
                                        } label: {
                                            VStack(spacing: 0) {
                                                HStack {
                                                    Text(query)
                                                        .font(BaseViewFont.body)
                                                        .foregroundStyle(BaseViewColor.textPrimary)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "arrow.up.left")
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(BaseViewColor.textSecondary)
                                                }
                                                .padding(BaseViewLayout.spacing)
                                                
                                                if index < viewModel.recentSearches.count - 1 {
                                                    Color.secondary.frame(height: 1)
                                                }
                                            }
                                        }
                                    }
                                }
                                .background(BaseViewColor.elevatedSurface)
                                .overlay(
                                    Rectangle()
                                        .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
                                )
                            }
                            .padding(.horizontal, BaseViewLayout.spacing)
                            .padding(.top, BaseViewLayout.spacing)
                        }
                    } else {
                        // Search Results
                        if viewModel.isSearching {
                            ReceiptLoadingLog()
                                .padding(BaseViewLayout.spacing)
                        } else if viewModel.searchResults.isEmpty {
                            VStack(spacing: BaseViewLayout.spacing) {
                                Text(String(localized: "search_empty_title"))
                                    .font(BaseViewFont.sectionTitle)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                
                                Text(String(localized: "search_empty_desc"))
                                    .font(BaseViewFont.body)
                                    .foregroundStyle(BaseViewColor.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                            .overlay(
                                Rectangle()
                                    .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
                            )
                            .padding(BaseViewLayout.spacing)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, product in
                                    SearchResultRow(
                                        product: product,
                                        showDivider: index < viewModel.searchResults.count - 1
                                    ) {
                                        showingProductDetail = product
                                    }
                                }
                            }
                            .padding(.horizontal, BaseViewLayout.spacing)
                            .padding(.top, BaseViewLayout.spacing)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            }
            .zIndex(-Double.infinity)
        }
        .fullScreenCover(item: $showingProductDetail) { product in
            ProductDetailSheet(product: product)
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let product: Product
    var showDivider: Bool = true
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: BaseViewLayout.spacing) {
                    // Product image
                    AppRemoteImage(
                        url: URL(string: product.displayImageUrl ?? ""),
                        source: .native,
                        width: 64,
                        height: 64,
                        cornerRadius: BaseViewLayout.radiusMedium,
                        backgroundColor: BaseViewColor.surface,
                        borderColor: BaseViewColor.border,
                        placeholderIcon: nil,
                        placeholderText: String(product.name.prefix(1))
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(BaseViewFont.cardTitle)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .lineLimit(2)
                        
                        if let description = product.description {
                            Text(description)
                                .font(BaseViewFont.label)
                                .foregroundStyle(BaseViewColor.textSecondary)
                                .lineLimit(2)
                        }
                        
                        Text(product.priceRange)
                            .font(BaseViewFont.labelStrong)
                            .foregroundStyle(BaseViewColor.accent)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                .padding(.vertical, BaseViewLayout.spacing)
                
                if showDivider {
                    Color.secondary.frame(height: 1)
                }
            }
        }
    }
}

// MARK: - Search ViewModel

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [Product] = []
    @Published var recentSearches: [String] = []
    @Published var isSearching = false
    
    private let productRepository: ProductRepositoryProtocol
    private var searchTask: Task<Void, Never>?
    
    init(productRepository: ProductRepositoryProtocol) {
        self.productRepository = productRepository
        loadRecentSearches()
        setupSearchDebounce()
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "recentSearches"),
           let searches = try? JSONDecoder().decode([String].self, from: data) {
            recentSearches = searches
        }
    }
    
    private func saveRecentSearch(_ query: String) {
        guard !query.isEmpty else { return }
        recentSearches.removeAll { $0 == query }
        recentSearches.insert(query, at: 0)
        recentSearches = Array(recentSearches.prefix(10))
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: "recentSearches")
        }
    }
    
    private func setupSearchDebounce() {
        Task {
            for await query in $searchQuery.values {
                searchTask?.cancel()
                
                guard !query.isEmpty else {
                    searchResults = []
                    isSearching = false
                    continue
                }
                
                isSearching = true
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    await performSearch(query: query)
                }
            }
        }
    }
    
    private func performSearch(query: String) async {
        do {
            let menu = try await productRepository.getMenu()
            searchResults = menu.products.filter { product in
                product.name.localizedCaseInsensitiveContains(query) ||
                product.description?.localizedCaseInsensitiveContains(query) == true
            }
            saveRecentSearch(query)
        } catch {}
        isSearching = false
    }
}
