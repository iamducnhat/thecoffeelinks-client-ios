//
//  CartViewModel.swift
//  thecoffeelinks-client-ios
//
//  Cart management with delivery fee calculations
//

import Foundation
import Combine
import CoreLocation

@MainActor
final class CartViewModel: ObservableObject {
    @Published var cart: Cart = .empty
    @Published var deliveryFee: Double = 0
    @Published var discount: Double = 0

    @Published var voucherValidation: VoucherValidation?
    @Published var deliveryAvailability: DeliveryAvailability?
    @Published var isValidatingVoucher = false
    @Published var isLoadingDelivery = false
    @Published var error: Error?
    @Published var selectedAddress: DeliveryAddress?
    
    // MARK: - Multi-Store Selection
    @Published var showStoreConflictAlert = false
    @Published var conflictingProduct: Product?
    @Published var conflictingStore: Store?
    @Published var recommendedStore: StoreScore?
    @Published var showStoreRecommendationToast = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private let deliveryRepository: DeliveryRepositoryProtocol
    private let voucherRepository: VoucherRepositoryProtocol
    private let hapticService: HapticServiceProtocol
    private let cartService: CartServiceProtocol
    private weak var storeViewModel: StoreViewModel?
    private weak var deliveryViewModel: DeliveryViewModel?
    
    init(deliveryRepository: DeliveryRepositoryProtocol, voucherRepository: VoucherRepositoryProtocol, hapticService: HapticServiceProtocol, cartService: CartServiceProtocol, storeViewModel: StoreViewModel? = nil, deliveryViewModel: DeliveryViewModel? = nil) {
        self.deliveryRepository = deliveryRepository
        self.voucherRepository = voucherRepository
        self.hapticService = hapticService
        self.cartService = cartService
        self.storeViewModel = storeViewModel
        self.deliveryViewModel = deliveryViewModel
        
        // 1. Load Local Immediately
        if let localCart = cartService.loadLocalCart() {
            self.cart = localCart
        }
        
        // 2. Background Fetch & Reconcile
        Task(priority: .userInitiated) { await bootstrapCart() }
        
        // 3. Sync with StoreViewModel
        setupStoreSync()
    }
    
    // ... Computed variable omitted (isEmpty, itemCount, subtotal, total, summary, canCheckout) - unchanged
    // Re-declare them if replace_file_content requires context or I'm replacing init block only. 
    // I need to use StartLine/EndLine carefully.
    // I'll replace init + fetchCart + addItem to ensure full context switch.
    
    var isEmpty: Bool { cart.isEmpty }
    var itemCount: Int { cart.itemCount }
    var subtotal: Double { cart.subtotal }
    
    var total: Double {
        var amount = subtotal
        if cart.mode == .delivery { amount += deliveryFee }
        amount -= bestDiscount
        amount -= pointsDiscount
        return max(0, amount)
    }
    
    var tierDiscount: Double {
        let pct = DependencyContainer.shared.profileStorage.loadUser()?.membershipStatus.discountPercent ?? 0
        return subtotal * (Double(pct) / 100.0)
    }
    
    var bestDiscount: Double {
        max(discount, tierDiscount)
    }
    
    var currentDiscountSource: DiscountSource {
        if discount >= tierDiscount && discount > 0 {
            return .voucher
        } else if tierDiscount > 0 {
            return .tier
        }
        return .none
    }

    var summary: CartSummary {
        let minAmount = deliveryAvailability?.minOrderAmount ?? 0
        let remaining = max(0, minAmount - subtotal)
        let totalDiscount = bestDiscount + pointsDiscount
        return CartSummary(subtotal: subtotal, deliveryFee: cart.mode == .delivery ? deliveryFee : 0, discount: totalDiscount,
                          total: total, itemCount: itemCount, meetsMinimum: subtotal >= minAmount,
                          minimumOrderAmount: minAmount, remainingForMinimum: remaining)
    }

    var canCheckout: Bool {
        guard !isEmpty else { return false }
        if cart.mode == .delivery {
            guard cart.deliveryAddressId != nil else { return false }
            guard deliveryAvailability?.available ?? false else { return false }
            guard summary.meetsMinimum else { return false }
        }
        guard cart.storeId != nil else { return false }
        return true
    }
    
    func bootstrapCart() async {
        do {
            let remoteCart = try await cartService.fetchRemoteCart()
            await MainActor.run {
                // Determine conflict resolution (Server Wins usually, or based on lastUpdated)
                // For now, simple replacement as server is authoritative for pricing
                self.cart = remoteCart
            }
        } catch {
            debugLog("Background fetch failed: \(error) - keeping local")
        }
    }
    
    func fetchCart() async {
       await bootstrapCart()
    }
    
    // Legacy support via Product
    func addItem(_ item: CartItem) {
        // Wrapper to call product version
        addItem(product: item.product, quantity: item.quantity, customization: item.customization)
    }
    
    func addItem(product: Product, quantity: Int, customization: OrderCustomization) {
        // MARK: - Store Validation
        // Check if product belongs to a different store than current cart
        if let currentStoreId = cart.storeId,
           !cart.items.isEmpty,
           let productStoreId = storeViewModel?.selectedStore?.id,
           currentStoreId != productStoreId {
            
            // Show conflict alert
            conflictingProduct = product
            conflictingStore = storeViewModel?.selectedStore
            showStoreConflictAlert = true
            Task { await hapticService.notification(.warning) }
            return
        }
        
        // If cart is empty and no store selected, auto-set to current selected store
        if cart.storeId == nil, let selectedStoreId = storeViewModel?.selectedStore?.id {
            cart.storeId = selectedStoreId
        }
        
        Task {
            do {
                // Optimistic Update: Service updates local storage and returns immediately
                // UI updates instantly < 16ms because disk I/O is fast enough on modern iOS
                let updatedCart = try await cartService.addToCart(product: product, quantity: quantity, modifiers: customization)
                await MainActor.run {
                    self.cart = updatedCart
                }
                await hapticService.impact(.medium)
            } catch {
                await MainActor.run { self.error = error }
            }
        }
    }
    
    func updateItem(id: String, quantity: Int, customization: OrderCustomization) {
        // Local update for responsive UI, ideally sync
        if let index = cart.items.firstIndex(where: { $0.id == id }) {
            var item = cart.items[index]
            item.quantity = quantity
            item.customization = customization
            cart.items[index] = item
            Task { await hapticService.selection() }
        }
    }
    
    func updateQuantity(for itemId: String, delta: Int) {
        cart.updateQuantity(for: itemId, delta: delta)
        Task { await hapticService.selection() }
    }
    
    func removeItem(_ itemId: String) {
        cart.removeItem(itemId)
        Task { await hapticService.notification(.warning) }
    }
    
    func clearCart() { 
        cart.clear(); discount = 0; pointsDiscount = 0; voucherValidation = nil; selectedAddress = nil 
        Task { 
            do {
                try await cartService.clearCart()
            } catch {
                debugLog("⚠️ [CartViewModel] Failed to clear cart on server: \(error)")
            }
        }
    }
    // H8 FIX: Clear tableId when switching away from dine-in, clear delivery fields when not delivery
    func setMode(_ mode: OrderingMode) { 
        cart.mode = mode
        if mode != .delivery { 
            deliveryFee = 0; deliveryAvailability = nil; selectedAddress = nil; cart.deliveryAddressId = nil 
        }
        if mode != .dineIn {
            cart.tableId = nil
        }
    }
    func setStore(_ storeId: String) { cart.storeId = storeId }
    func setDeliveryAddress(_ addressId: String, address: DeliveryAddress?) { 
        cart.deliveryAddressId = addressId
        selectedAddress = address
        if address != nil { Task { await checkDeliveryAvailability() } }
    }
    func setStaffNotes(_ notes: String) { cart.staffNotes = notes.isEmpty ? nil : notes }
    func setDeliveryNotes(_ notes: String) { cart.deliveryNotes = notes.isEmpty ? nil : notes }
    
    func checkDeliveryAvailability() async {
        guard let storeId = cart.storeId else { return }
        isLoadingDelivery = true; error = nil
        do {
            let availability = try await deliveryRepository.checkAvailability(addressId: cart.deliveryAddressId, latitude: nil, longitude: nil, storeId: storeId)
            deliveryAvailability = availability
            deliveryFee = availability.fee?.amount ?? 0
            if !availability.available { error = DeliveryError.unavailable(availability.unavailableReason?.message ?? "Delivery unavailable") }
        } catch { self.error = error }
        isLoadingDelivery = false
    }
    
    // Voucher rate limiting: max 3 attempts per 60 seconds
    private var voucherAttemptTimestamps: [Date] = []
    private let maxVoucherAttempts = 3
    private let voucherRateLimitWindow: TimeInterval = 60
    
    func applyVoucher(code: String) async {
        guard !code.isEmpty else { return }
        
        // Rate limit: reject if too many attempts in the time window
        let now = Date()
        voucherAttemptTimestamps = voucherAttemptTimestamps.filter { now.timeIntervalSince($0) < voucherRateLimitWindow }
        guard voucherAttemptTimestamps.count < maxVoucherAttempts else {
            let cooldown = Int(voucherRateLimitWindow - now.timeIntervalSince(voucherAttemptTimestamps.first!))
            error = VoucherError.invalid("Too many attempts. Try again in \(cooldown)s")
            await hapticService.notification(.error)
            return
        }
        voucherAttemptTimestamps.append(now)
        
        isValidatingVoucher = true; error = nil
        do {
            let validation = try await voucherRepository.validateVoucher(code: code, subtotal: subtotal, mode: cart.mode)
            voucherValidation = validation
            if validation.valid { cart.voucherCode = code; discount = validation.discountAmount; await hapticService.notification(.success) }
            else { error = VoucherError.invalid(validation.message ?? "Invalid voucher"); await hapticService.notification(.error) }
        } catch { self.error = error; await hapticService.notification(.error) }
        isValidatingVoucher = false
    }
    
    func removeVoucher() { cart.voucherCode = nil; voucherValidation = nil; discount = 0 }
    
    // MARK: - Points Support
    @Published var pointsDiscount: Double = 0
    
    func applyPointsDiscount(_ amount: Double) {
        // Ensure we don't discount more than the subtotal (minus other discounts)
        // For now, allow valid amount passed from caller
        pointsDiscount = amount
    }
    
    func removePointsDiscount() {
        pointsDiscount = 0
    }
    
    // MARK: - Multi-Store Management
    
    /// Setup Combine subscriptions to sync cart with StoreViewModel
    private func setupStoreSync() {
        // Sync cart.storeId with StoreViewModel.selectedStore
        storeViewModel?.$selectedStore
            .dropFirst() // Ignore initial value
            .sink { [weak self] selectedStore in
                guard let self = self else { return }
                
                // If cart is empty, auto-sync
                if self.cart.items.isEmpty {
                    self.cart.storeId = selectedStore?.id
                } else if let storeId = selectedStore?.id, self.cart.storeId != storeId {
                    // Cart has items but user switched stores - this is handled by UI alert
                    debugLog("⚠️ Store changed but cart has items. Waiting for user decision.")
                }
            }
            .store(in: &cancellables)
        
        // Monitor cart changes for store recommendations
        $cart
            .map { $0.items }
            .removeDuplicates()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                
                // Only recompute if in delivery mode and cart has items
                guard !items.isEmpty,
                      self.cart.mode == .delivery,
                      let address = self.selectedAddress else {
                    return
                }
                
                Task {
                    await self.recomputeRecommendedStore(for: address)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Switch to a different store and clear the cart
    func switchStore(to store: Store) {
        // Clear cart first
        clearCart()
        
        // Update cart and view model
        cart.storeId = store.id
        storeViewModel?.selectStore(store)
        
        // Reset conflict state
        showStoreConflictAlert = false
        conflictingProduct = nil
        conflictingStore = nil
        
        Task { await hapticService.impact(.medium) }
    }
    
    /// Confirm adding item after store switch
    func confirmStoreSwitch(product: Product, quantity: Int, customization: OrderCustomization) {
        guard let store = conflictingStore else { return }
        
        // Clear cart and switch
        switchStore(to: store)
        
        // Add the new item
        addItem(product: product, quantity: quantity, customization: customization)
    }
    
    /// Cancel store conflict - keep current cart
    func cancelStoreSwitch() {
        showStoreConflictAlert = false
        conflictingProduct = nil
        conflictingStore = nil
        Task { await hapticService.selection() }
    }
    
    /// Recompute recommended store based on current cart and delivery address
    private func recomputeRecommendedStore(for address: DeliveryAddress) async {
        guard let storeVM = storeViewModel,
              let deliveryVM = deliveryViewModel else {
            return
        }
        
        // Get delivery-capable stores
        let deliveryStores = storeVM.stores.filter { $0.deliveryAvailable == true }
        guard !deliveryStores.isEmpty else { return }
        
        // Fetch availability for stores near the address (limit to 5 closest)
        var availabilities: [String: DeliveryAvailability] = [:]
        
        let userLocation = address.coordinates.map { coord in
            CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        }
        
        // Sort by distance and take top 5
        let nearestStores: [Store]
        if let userLoc = userLocation {
            nearestStores = Array(deliveryStores.sorted { store1, store2 in
                let loc1 = CLLocation(latitude: store1.latitude, longitude: store1.longitude)
                let loc2 = CLLocation(latitude: store2.latitude, longitude: store2.longitude)
                let userCLLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
                return userCLLocation.distance(from: loc1) < userCLLocation.distance(from: loc2)
            }.prefix(5))
        } else {
            nearestStores = Array(deliveryStores.prefix(5))
        }
        
        // Check availability in parallel
        await withTaskGroup(of: (String, DeliveryAvailability?).self) { group in
            for store in nearestStores {
                group.addTask {
                    do {
                        let availability = try await deliveryVM.checkDeliveryAvailability(
                            for: store.id,
                            addressId: address.id
                        )
                        return (store.id, availability)
                    } catch {
                        return (store.id, nil)
                    }
                }
            }
            
            for await (storeId, availability) in group {
                if let availability = availability, availability.available {
                    availabilities[storeId] = availability
                }
            }
        }
        
        // Calculate scores
        let availableStores = nearestStores.filter { availabilities[$0.id]?.available == true }
        guard !availableStores.isEmpty else { return }
        
        let calculator = StoreScoreCalculator()
        let scores = calculator.calculateScores(
            stores: availableStores,
            availabilities: availabilities,
            cartItems: cart.items,
            userLocation: userLocation
        )
        
        guard let bestStore = scores.first else { return }
        
        await MainActor.run {
            self.recommendedStore = bestStore
            
            // If recommended store differs from current and cart has items, show toast
            if let currentStoreId = self.cart.storeId,
               currentStoreId != bestStore.store.id,
               !self.cart.items.isEmpty {
                self.showStoreRecommendationToast = true
                
                // Auto-hide toast after 5 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    await MainActor.run {
                        self.showStoreRecommendationToast = false
                    }
                }
            }
        }
    }
}

enum VoucherError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { switch self { case .invalid(let msg): return msg } }
}

enum DiscountSource: String, Codable, Sendable {
    case none, tier, voucher
}
