//
//  MenuViewModel.swift
//  thecoffeelinks-native-swift
//
//  Product catalog with categories and filtering
//

import Foundation
import Combine

@MainActor
final class MenuViewModel: ObservableObject {
    @Published var menu: Menu?
    @Published var categories: [Category] = []
    @Published var products: [Product] = []
    @Published var toppings: [Topping] = []
    @Published var selectedCategory: Category?
    @Published var searchQuery = ""
    @Published var searchResults: [Product] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var error: Error?
    @Published var showDeliverableOnly = false
    @Published var orderingMode: OrderingMode = .pickup
    
    private let productRepository: ProductRepositoryProtocol
    private let cacheService: CacheServiceProtocol
    private let refreshCoordinator: ContentRefreshCoordinator
    private var cancellables = Set<AnyCancellable>()
    
    init(productRepository: ProductRepositoryProtocol, cacheService: CacheServiceProtocol, refreshCoordinator: ContentRefreshCoordinator) {
        self.productRepository = productRepository
        self.cacheService = cacheService
        self.refreshCoordinator = refreshCoordinator
        setupSearchDebounce()
    }
    
    var filteredProducts: [Product] {
        var result = selectedCategory != nil ? products.filter { $0.categoryId == selectedCategory?.id } : products
        if showDeliverableOnly || orderingMode == .delivery { result = result.filter { $0.canBeDelivered } }
        return result.filter { $0.isActive }
    }
    
    func load() async {
        // 1. Load Cache
        if let cachedMenu = await productRepository.getCachedMenu() {
            self.updateMenu(cachedMenu)
        }
        
        // 2. Schedule Refresh
        await refreshCoordinator.schedule(id: "menu_refresh", priority: .high) { [weak self] in
            await self?.performRefresh()
        }
    }
    
    private func performRefresh() async {
        isLoading = true; error = nil
        do {
            let menu = try await productRepository.refreshMenu()
            updateMenu(menu)
        } catch { self.error = error }
        isLoading = false
    }
    
    private func updateMenu(_ menu: Menu) {
        self.menu = menu
        self.categories = menu.categories.filter { $0.isActive }.sorted { $0.sortOrder < $1.sortOrder }
        self.products = menu.products
        self.toppings = menu.toppings
    }
    
    func refresh() async { await load() }
    func selectCategory(_ category: Category?) { selectedCategory = category }
    
    private func setupSearchDebounce() {
        $searchQuery.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in Task { await self?.performSearch(query) } }
            .store(in: &cancellables)
    }
    
    private func performSearch(_ query: String) async {
        guard !query.isEmpty else { searchResults = []; return }
        isSearching = true
        let lowercased = query.lowercased()
        searchResults = products.filter { $0.name.lowercased().contains(lowercased) || $0.description?.lowercased().contains(lowercased) ?? false }
        if searchResults.count < 3 {
            if let apiResults = try? await productRepository.searchProducts(query: query) {
                let existingIds = Set(searchResults.map { $0.id })
                searchResults.append(contentsOf: apiResults.filter { !existingIds.contains($0.id) })
            }
        }
        isSearching = false
    }
    
    func clearSearch() { searchQuery = ""; searchResults = [] }
    func getProduct(id: String) -> Product? { products.first { $0.id == id } }
    func getToppings(for product: Product) -> [Topping] { toppings.filter { product.availableToppings.contains($0.id) && $0.isAvailable } }
    func setOrderingMode(_ mode: OrderingMode) { orderingMode = mode; showDeliverableOnly = mode == .delivery }
}
