import Foundation
import Combine
import Supabase

@MainActor
class OrdersViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var activeOrders: [Order] = []
    @Published var pastOrders: [Order] = []
    
    private let orderService = OrderService()
    private var realtimeChannel: RealtimeChannelV2?
    
    func fetchOrders() async {
        self.viewState = .loading
        do {
            async let activeTask = orderService.getActiveOrders()
            async let allTask = orderService.getOrders()
            
            let (active, all) = try await (activeTask, allTask)
            
            self.activeOrders = active
            
            // Filter 'all' for past orders (completed or cancelled)
            self.pastOrders = all.filter { $0.status == "completed" || $0.status == "cancelled" }
            
            self.viewState = .loaded
            
            // Setup realtime if not already connected
            if realtimeChannel == nil {
                await setupRealtime()
            }
        } catch {
            self.viewState = .error(error.localizedDescription)
        }
    }
    
    private func setupRealtime() async {
        guard let userId = AuthManager.shared.session?.userId else { return }
        
        self.realtimeChannel = await orderService.subscribeToOrders(userId: userId) { [weak self] in
            Task { @MainActor [weak self] in
                // re-fetch silently without full loading state if desired,
                // but for now reusing fetchOrders which sets loading is okay,
                // or ideally we split fetch logic from loading state.
                // For simplicity, we just call fetchOrders for now.
                // To avoid flickering, we could manually just fetch and assign.
                await self?.refreshOrders()
            }
        }
    }
    
    private func refreshOrders() async {
        // Silent refresh
        do {
            async let activeTask = orderService.getActiveOrders()
            async let allTask = orderService.getOrders()
            
            let (active, all) = try await (activeTask, allTask)
            
            self.activeOrders = active
            self.pastOrders = all.filter { $0.status == "completed" || $0.status == "cancelled" }
        } catch {
            print("Error refreshing orders: \(error)")
        }
    }
    deinit {
        let channel = realtimeChannel
        Task {
            await channel?.unsubscribe()
        }
    }
}
