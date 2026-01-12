import Foundation
import Combine

@MainActor
class OrdersViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var activeOrders: [Order] = []
    @Published var pastOrders: [Order] = []
    
    private let orderService = OrderService()
    
    func fetchOrders() async {
        self.viewState = .loading
        do {
            async let activeTask = orderService.getActiveOrders()
            async let allTask = orderService.getOrders()
            
            let (active, all) = try await (activeTask, allTask)
            
            self.activeOrders = active
            
            // Filter 'all' for past orders (completed or cancelled)
            self.pastOrders = all.filter { $0.status == .completed || $0.status == .cancelled }
            
            self.viewState = .loaded
        } catch {
            self.viewState = .error(error.localizedDescription)
        }
    }
}
