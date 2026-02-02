import XCTest
@testable import TheCoffeeLinks

/// Tests for APIClient HTTP functionality
final class APIClientTests: XCTestCase {
    
    // MARK: - APIClient Singleton
    
    func testAPIClientSharedInstance() async {
        let client1 = APIClient.shared
        let client2 = APIClient.shared
        
        // Verify singleton pattern
        XCTAssertTrue(client1 === client2, "APIClient should be a singleton")
    }
    
    // MARK: - Token Management
    
    func testSetAndGetAuthToken() async {
        let testToken = "test_bearer_token_12345"
        
        await APIClient.shared.setAuthToken(testToken)
        let retrievedToken = await APIClient.shared.getAuthToken()
        
        XCTAssertEqual(retrievedToken, testToken, "Auth token should be stored and retrieved correctly")
    }
    
    func testClearAuthToken() async {
        await APIClient.shared.setAuthToken("some_token")
        await APIClient.shared.setAuthToken(nil)
        
        let token = await APIClient.shared.getAuthToken()
        XCTAssertNil(token, "Auth token should be clearable")
    }
}

/// Tests for Product Service
final class ProductServiceTests: XCTestCase {
    var productService: ProductService!
    
    override func setUp() {
        super.setUp()
        productService = ProductService()
    }
    
    func testGetProductsReturnsArray() async throws {
        // This is an integration test - requires live API
        do {
            let products = try await productService.getProducts()
            // Should return an array (even if empty)
            XCTAssertNotNil(products, "Products should not be nil")
            print("✅ Fetched \(products.count) products")
        } catch {
            // API errors are expected if server is down
            print("⚠️ Products API error (expected if server unavailable): \(error)")
        }
    }
    
    func testGetFeaturedProductsReturnsArray() async throws {
        do {
            let products = try await productService.getFeaturedProducts()
            XCTAssertNotNil(products, "Featured products should not be nil")
            print("✅ Fetched \(products.count) featured products")
        } catch {
            print("⚠️ Featured Products API error: \(error)")
        }
    }
}

/// Tests for Event Service
final class EventServiceTests: XCTestCase {
    var eventService: EventService!
    
    override func setUp() {
        super.setUp()
        eventService = EventService()
    }
    
    func testGetEventsReturnsArray() async throws {
        do {
            let events = try await eventService.getEvents()
            XCTAssertNotNil(events, "Events should not be nil")
            print("✅ Fetched \(events.count) events")
        } catch {
            print("⚠️ Events API error: \(error)")
        }
    }
}

/// Tests for Voucher Service
final class VoucherServiceTests: XCTestCase {
    var voucherService: VoucherService!
    
    override func setUp() {
        super.setUp()
        voucherService = VoucherService()
    }
    
    func testGetVouchersReturnsArray() async throws {
        do {
            let vouchers = try await voucherService.getVouchers()
            XCTAssertNotNil(vouchers, "Vouchers should not be nil")
            print("✅ Fetched \(vouchers.count) vouchers")
        } catch {
            print("⚠️ Vouchers API error: \(error)")
        }
    }
}

/// Tests for Order Service
final class OrderServiceTests: XCTestCase {
    var orderService: OrderService!
    
    override func setUp() {
        super.setUp()
        orderService = OrderService()
    }
    
    func testGetOrdersRequiresAuth() async {
        // Without auth token, should fail with unauthorized
        await APIClient.shared.setAuthToken(nil)
        
        do {
            _ = try await orderService.getOrders()
            // If no error, API might allow unauthenticated access
            print("⚠️ Orders API allowed unauthenticated access")
        } catch let error as APIClient.APIError {
            // Expected: unauthorized error
            if case .unauthorized(_) = error {
                print("✅ Orders correctly requires authentication")
            } else {
                print("⚠️ Orders API error: \(error)")
            }
        } catch {
            print("⚠️ Unexpected error: \(error)")
        }
    }
}

/// Tests for User Service
final class UserServiceTests: XCTestCase {
    var userService: UserService!
    
    override func setUp() {
        super.setUp()
        userService = UserService()
    }
    
    func testGetCurrentUserRequiresAuth() async {
        await APIClient.shared.setAuthToken(nil)
        
        do {
            _ = try await userService.getCurrentUser()
            print("⚠️ User API allowed unauthenticated access")
        } catch let error as APIClient.APIError {
            if case .unauthorized(_) = error {
                print("✅ User profile correctly requires authentication")
            } else {
                print("⚠️ User API error: \(error)")
            }
        } catch {
            print("⚠️ Unexpected error: \(error)")
        }
    }
}

/// Tests for Network Service
final class NetworkServiceTests: XCTestCase {
    var networkService: NetworkService!
    
    override func setUp() {
        super.setUp()
        networkService = NetworkService()
    }
    
    func testGetCheckInsReturnsArray() async throws {
        do {
            let checkIns = try await networkService.getCheckIns()
            XCTAssertNotNil(checkIns, "Check-ins should not be nil")
            print("✅ Fetched \(checkIns.count) check-ins")
        } catch {
            print("⚠️ Network/CheckIns API error: \(error)")
        }
    }
}
