//
//  SearchView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
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
            Color.bgPrimary.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: AppLayout.spacing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(AppFont.navIcon)
                        .foregroundStyle(Color.textPrimary)
                        .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                        .background {
                            Capsule()
                                .fill(Color.bgPrimary)
                        }
                        .overlay {
                            Capsule()
                                .strokeBorder(Color.textPrimary, lineWidth: min(66.6, max(scrollOffset, 0.0)) / 66.6)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
                
                Text(String(localized: "common_search"))
                    .font(AppFont.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: AppLayout.touchTarget)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, AppLayout.spacing)
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Navigation Header (Scrollable)
                    HStack(alignment: .center, spacing: AppLayout.spacing) {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textPrimary)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                            .hidden()
                        
                        Text(String(localized: "common_search"))
                            .font(AppFont.displayTitle)
                            .lineLimit(1)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: AppLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, AppLayout.spacing)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    // Search Bar
                    HStack(spacing: AppLayout.spacingMedium) {
                        Image("magnifyingglass")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textSecondary)
                        
                        TextField("Search products...", text: $viewModel.searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(AppFont.body)
                            .foregroundStyle(Color.textPrimary)
                        
                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                            } label: {
                                Image("circle_x")
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.borderSecondary, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                    }
                    .padding(.horizontal, AppLayout.spacing)
                    
                    Color.secondary.frame(height: 1)
                        .padding(.top, AppLayout.spacing)
                        .padding(.horizontal, AppLayout.spacing)
                    
                    if viewModel.searchQuery.isEmpty {
                        // Recent Searches
                        if !viewModel.recentSearches.isEmpty {
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text(String(localized: "common_recent"))
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textPrimary)
                                
                                VStack(spacing: 0) {
                                    ForEach(Array(viewModel.recentSearches.enumerated()), id: \.element) { index, query in
                                        Button {
                                            viewModel.searchQuery = query
                                        } label: {
                                            VStack(spacing: 0) {
                                                HStack {
                                                    Text(query)
                                                        .font(AppFont.body)
                                                        .foregroundStyle(Color.textPrimary)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "arrow.up.left")
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(Color.textSecondary)
                                                }
                                                .padding(AppLayout.spacing)
                                                
                                                if index < viewModel.recentSearches.count - 1 {
                                                    Color.secondary.frame(height: 1)
                                                }
                                            }
                                        }
                                    }
                                }
                                .background(Color.bgPrimary)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.border, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, AppLayout.spacing)
                            .padding(.top, AppLayout.spacing)
                        }
                    } else {
                        // Search Results
                        if viewModel.isSearching {
                            ReceiptLoadingLog()
                                .padding(AppLayout.spacing)
                        } else if viewModel.searchResults.isEmpty {
                            VStack(spacing: AppLayout.spacing) {
                                Text(String(localized: "search_empty_title"))
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textPrimary)
                                
                                Text(String(localized: "search_empty_desc"))
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                            )
                            .padding(AppLayout.spacing)
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
                            .padding(.horizontal, AppLayout.spacing)
                            .padding(.top, AppLayout.spacing)
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
                HStack(spacing: AppLayout.spacing) {
                    // Product image
                    AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { phase in
                        switch phase {
                        case .empty, .failure:
                            Color.surfacePrimary
                                .overlay(
                                    Text(String(product.name.prefix(1)))
                                        .font(AppFont.sectionHeader)
                                        .foregroundStyle(Color.textSecondary)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
                        Capsule()
                            .strokeBorder(Color.border, lineWidth: 1)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(AppFont.body)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(2)
                        
                        if let description = product.description {
                            Text(description)
                                .font(AppFont.uiCaption)
                                .foregroundStyle(Color.textSecondary)
                                .lineLimit(2)
                        }
                        
                        Text(product.priceRange)
                            .font(AppFont.monoBody)
                            .foregroundStyle(Color.accentPrimary)
                    }
                    
                    Spacer()
                    
                    Image("chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.vertical, AppLayout.spacing)
                
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
