import SwiftUI
import Combine

@MainActor
class OrdersViewModel: ObservableObject {
    @Published var activeOrders: [Order] = []
    @Published var historyOrders: [Order] = []
    @Published var isLoading = false
    @Published var cancellingOrderID: String?
    @Published var cancellationError: String?
    
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
                debugLog("Error fetching orders: \(error)")
                self.isLoading = false
            }
        }
    }
    
    func reorder(_ order: Order) {
        // Validation logic -> Add items to cart
        debugLog("Reordering order \(order.id)")
    }

    func isCancelling(_ order: Order) -> Bool {
        cancellingOrderID == order.id
    }

    func cancelOrder(_ order: Order) async -> Bool {
        guard cancellingOrderID == nil else { return false }

        cancellingOrderID = order.id
        cancellationError = nil

        do {
            let cancelledOrder = try await repository.cancelOrder(
                id: order.id,
                reason: "Customer requested cancellation from order view"
            )
            activeOrders.removeAll { $0.id == order.id }

            if cancelledOrder.status.isActive {
                activeOrders.insert(cancelledOrder, at: 0)
            } else {
                historyOrders.removeAll { $0.id == cancelledOrder.id }
                historyOrders.insert(cancelledOrder, at: 0)
            }

            cancellingOrderID = nil
            return true
        } catch {
            cancellationError = error.localizedDescription
            cancellingOrderID = nil
            return false
        }
    }
}
