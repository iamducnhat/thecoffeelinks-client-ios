import SwiftUI
import Combine

@MainActor
class OrdersViewModel: ObservableObject {
    @Published var activeOrders: [Order] = []
    @Published var historyOrders: [Order] = []
    @Published var isLoading = false
    
    private let repository: OrderRepositoryProtocol
    
    init(repository: OrderRepositoryProtocol) {
        self.repository = repository
    }
    
    func fetchOrders() {
        isLoading = true
        Task {
            do {
                let response = try await repository.getOrders(status: nil, limit: 100, offset: 0)
                let allOrders = response.orders
                self.activeOrders = allOrders.filter { $0.status.isActive }
                self.historyOrders = allOrders.filter { !$0.status.isActive }
                self.isLoading = false
            } catch {
                print("Error fetching orders: \(error)")
                self.isLoading = false
            }
        }
    }
    
    func reorder(_ order: Order) {
        // Validation logic -> Add items to cart
        print("Reordering order \(order.id)")
    }
}
