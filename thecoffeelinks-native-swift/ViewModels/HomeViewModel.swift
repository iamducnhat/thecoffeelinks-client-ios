import Foundation
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var featuredProducts: [Product] = []
    @Published var activeOrder: Order?
    @Published var nearbyCheckIns: [User] = []
    
    private let productService = ProductService()
    private let orderService = OrderService()
    private let networkService = NetworkService()
    
    func fetchData() async {
        self.viewState = .loading
        
        // Fetch Featured Products
        do {
            self.featuredProducts = try await productService.getFeaturedProducts()
        } catch let decodingError as DecodingError {
            print("Product Decoding Error: \(decodingError)")
        } catch {
            print("Product Fetch Error: \(error)")
        }
        
        // Fetch Active Orders
        do {
            let orders = try await orderService.getActiveOrders()
            self.activeOrder = orders.first
        } catch let decodingError as DecodingError {
            print("Order Decoding Error: \(decodingError)")
        } catch {
            print("Order Fetch Error: \(error)")
        }
        
        // Check Network (Optimistic/Silently)
        // ...
        
        self.viewState = .loaded
        // Note: verify if we should set .error state if BOTH fail, or just show partial data.
        // For debugging, we just want to see the logs.
    }
}
