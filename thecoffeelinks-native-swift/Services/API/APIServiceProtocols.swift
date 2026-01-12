import Foundation

protocol UserServiceProtocol {
    func getCurrentUser() async throws -> User
    func updateProfile(userId: String, params: UpdateProfileParams) async throws -> User
}

protocol OrderServiceProtocol {
    func getOrders() async throws -> [Order]
    func createOrder(order: Order) async throws -> Order
    func getActiveOrders() async throws -> [Order]
}

protocol EventServiceProtocol {
    func getEvents() async throws -> [Event]
}

protocol VoucherServiceProtocol {
    func getVouchers() async throws -> [Voucher]
    func getVouchersForUser(userId: UUID) async throws -> [Voucher]
    func redeemVoucher(code: String) async throws -> Voucher
}

protocol ProductServiceProtocol {
    func getProducts() async throws -> [Product]
    func getFeaturedProducts() async throws -> [Product]
}

protocol NetworkServiceProtocol {
    func getCheckIns() async throws -> [CheckIn]
    func checkIn(locationId: String) async throws
}
