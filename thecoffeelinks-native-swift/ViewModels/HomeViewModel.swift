import Foundation
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var activeOrder: Order?
    
    // New Data Sources
    @Published var highlights: [HighlightItem] = [] // Vouchers + Events
    @Published var trendingProducts: [Product] = [] // Popular == true
    @Published var recentProducts: [Product] = [] // From Past Orders
    @Published var allProducts: [Product] = [] // For context-aware filtering
    
    // Popularity tracking (orders today per product)
    @Published var orderCounts: [String: Int] = [:]
    
    // Social signals
    @Published var regularsAtStore: Int = 0
    @Published var connectedUsersAtStore: [String] = []
    
    private let productService = ProductService()
    private let orderService = OrderService()
    private let voucherService = VoucherService()
    
    private let productsCacheKey = "home_products_cache"
    private let ordersCacheKey = "home_orders_cache"
    private let vouchersCacheKey = "home_vouchers_cache"
    
    init() {
        loadFromCache()
    }
    
    private func loadFromCache() {
        let cachedProducts = CacheManager.shared.load([Product].self, for: productsCacheKey)
        let cachedOrders = CacheManager.shared.load([Order].self, for: ordersCacheKey)
        let cachedVouchers = CacheManager.shared.load([Voucher].self, for: vouchersCacheKey)
        
        if let p = cachedProducts, let o = cachedOrders, let v = cachedVouchers {
            processData(products: p, orders: o, vouchers: v)
            if !p.isEmpty {
                self.viewState = .loaded
            }
        }
    }
    
    func fetchData() async {
        // Only show full loading state if we have no data
        if highlights.isEmpty && trendingProducts.isEmpty && activeOrder == nil {
            self.viewState = .loading
        }
        
        do {
            // 1. Parallel Fetching
            async let fetchedProducts = try productService.getProducts()
            async let fetchedOrders = try orderService.getActiveOrders() 
            async let fetchedVouchers = try voucherService.getVouchers()
            
            let (products, orders, vouchers) = try await (fetchedProducts, fetchedOrders, fetchedVouchers)
            
            // Save to Cache
            await CacheManager.shared.save(products, for: productsCacheKey)
            await CacheManager.shared.save(orders, for: ordersCacheKey)
            await CacheManager.shared.save(vouchers, for: vouchersCacheKey)
            
            processData(products: products, orders: orders, vouchers: vouchers)
            
            // Generate AI prediction in background
            Task {
                await PredictionEngine.shared.generatePrediction()
            }
            
            // Record orders for prediction learning
            for order in orders {
                let context = PredictionContext()
                let cartItems = order.items.compactMap { item -> CartItem? in
                    guard let product = products.first(where: { $0.id == item.productId }) else { return nil }
                    return CartItem(
                        id: UUID(),
                        product: product,
                        quantity: item.quantity,
                        finalPrice: item.finalPrice ?? 0,
                        customization: item.optionsSnapshotJson ?? OrderCustomization(size: "M", ice: nil, sugar: nil, toppings: nil)
                    )
                }
                if !cartItems.isEmpty {
                    FavoritesService.shared.recordOrder(items: cartItems)
                    PredictionEngine.shared.recordOrder(items: cartItems, context: context)
                }
            }
            
            self.viewState = .loaded
            
        } catch {
            print("Home Data Fetch Error: \(error)")
            if highlights.isEmpty {
                self.viewState = .error(error.localizedDescription)
            }
        }
    }
    
    private func processData(products: [Product], orders: [Order], vouchers: [Voucher]) {
        // Store all products for context-aware filtering
        self.allProducts = products
        
        // 2. Process Highlights (Vouchers Only)
        let availableVouchers = vouchers.prefix(5)
        
        var voucherHighlights: [HighlightItem] = []
        
        for voucher in availableVouchers {
            voucherHighlights.append(.voucher(voucher))
        }
        
        self.highlights = voucherHighlights
        
        // 3. Process Trending (with order counts for anti-herd display)
        self.trendingProducts = products.filter { $0.isPopular ?? false }
        
        // Simulate order counts (in production, this comes from server)
        var counts: [String: Int] = [:]
        for product in trendingProducts {
            counts[product.id] = Int.random(in: 3...25)
        }
        self.orderCounts = counts
        
        // 4. Process Recent Ordered Products
        var recentProductIds: Set<String> = []
        var recentProds: [Product] = []
        
        for order in orders {
            if let items = order.orderItems {
                for item in items {
                    if let productId = item.productId, !recentProductIds.contains(productId) {
                        if let product = products.first(where: { $0.id == productId }) {
                            recentProds.append(product)
                            recentProductIds.insert(productId)
                        }
                    }
                    if recentProds.count >= 5 { break }
                }
            }
            if recentProds.count >= 5 { break }
        }
        self.recentProducts = recentProds
        
        // 5. Active Order
        self.activeOrder = orders.first(where: {
            let s = $0.status ?? ""
            return s == "received" || s == "preparing" || s == "ready"
        })
        
        // 6. Mock social signals (in production from server)
        self.regularsAtStore = Int.random(in: 0...8)
        self.connectedUsersAtStore = ["Minh", "Lan"].filter { _ in Bool.random() }
    }
}

// Wrapper for Heterogeneous List
enum HighlightItem: Identifiable {
    case voucher(Voucher)
    case event(Event)
    
    var id: String {
        switch self {
        case .voucher(let v): return "voucher-\(v.id)"
        case .event(let e): return "event-\(e.id)"
        }
    }
}
