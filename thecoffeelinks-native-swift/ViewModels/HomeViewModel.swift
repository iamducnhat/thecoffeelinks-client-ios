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
    
    private let productService = ProductService()
    private let orderService = OrderService()
    private let voucherService = VoucherService()
    // private let eventService = EventService() // Not needed for Home anymore
    
    func fetchData() async {
        // Only show full loading state if we have no data
        if highlights.isEmpty && trendingProducts.isEmpty && activeOrder == nil {
            self.viewState = .loading
        }
        
        do {
            // 1. Parallel Fetching
            async let fetchedProducts = try productService.getProducts()
            async let fetchedOrders = try orderService.getActiveOrders() // Assumed to return all/active orders? 
            // Note: orderService.getActiveOrders() might fetch /api/user/orders which returns ALL orders usually sorted by date
            // But verify if it filters. If so, we might need getPastOrders
            
            async let fetchedVouchers = try voucherService.getVouchers()
            // Events are now handled in separate view accessed via Notification
            
            let (products, orders, vouchers) = try await (fetchedProducts, fetchedOrders, fetchedVouchers)
            
            // 2. Process Highlights (Vouchers Only)
            let availableVouchers = vouchers.prefix(5) // Show top 5 vouchers
            
            var voucherHighlights: [HighlightItem] = []
            
            for voucher in availableVouchers {
                voucherHighlights.append(.voucher(voucher))
            }
            
            self.highlights = voucherHighlights
            
            // 3. Process Trending
            self.trendingProducts = products.filter { $0.isPopular ?? false }
            
            // 4. Process Recent Ordered Products
            // Flatten order items from orders
            // Orders are usually sorted by date desc
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
            
            // 5. Active Order (First one if status is active)
            // Assuming getActiveOrders returns active ones first or we filter
            self.activeOrder = orders.first(where: {
                let s = $0.status ?? ""
                return s == "received" || s == "preparing" || s == "ready"
            })
            
            self.viewState = .loaded
            
        } catch {
            print("Home Data Fetch Error: \(error)")
            if highlights.isEmpty {
                self.viewState = .error(error.localizedDescription)
            }
        }
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
