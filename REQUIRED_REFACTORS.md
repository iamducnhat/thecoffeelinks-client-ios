# Required Refactors for Better Testability

## Overview
To implement the comprehensive test suite provided, several refactors are needed in the main codebase to improve testability through proper dependency injection, protocol abstraction, and better separation of concerns.

## Critical Refactors Required

### 1. Protocol-Based Dependency Injection

**Current Issue:** Hard dependencies on concrete classes make testing impossible
**Required Changes:**

#### NetworkService Protocol
```swift
// Create protocol for NetworkService
protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: String, method: String, body: Encodable?, queryItems: [URLQueryItem]?) async throws -> T
    func setAuthSession(accessToken: String, refreshToken: String?)
    func clearAuthToken()
    var authToken: String? { get }
}

// Make NetworkService conform to protocol
extension NetworkService: NetworkServiceProtocol {}
```

#### Repository Protocols
```swift
// AuthRepository Protocol
protocol AuthRepositoryProtocol {
    func signIn(email: String, password: String) async throws -> User
    func register(phone: String, password: String, name: String, dob: String) async throws -> Bool
    func verifyOTP(phone: String, otp: String) async throws -> User
    func signOut() async throws
    func getCurrentUser() async throws -> User
}

// ProductRepository Protocol
protocol ProductRepositoryProtocol {
    func fetchProducts() async throws -> [Product]
    func fetchCategories() async throws -> [ProductCategory]
    func searchProducts(query: String) async throws -> [Product]
}

// CartService Protocol
protocol CartServiceProtocol: ObservableObject {
    var items: [CartItem] { get }
    var total: Double { get }
    func addItem(product: Product, quantity: Int, sizeOption: SizeOption?, toppings: [Topping])
    func removeItem(itemId: String)
    func updateQuantity(itemId: String, quantity: Int)
    func clearCart()
}
```

### 2. ViewModel Dependency Injection Refactor

**Current Issue:** ViewModels use singleton pattern and hardcoded dependencies
**Required Changes:**

#### AuthViewModel Refactor
```swift
class AuthViewModel: BaseViewModel {
    private let authRepository: AuthRepositoryProtocol
    private let keychainManager: KeychainManagerProtocol
    
    // Remove static shared instance
    init(authRepository: AuthRepositoryProtocol, keychainManager: KeychainManagerProtocol) {
        self.authRepository = authRepository
        self.keychainManager = keychainManager
        super.init()
        checkSession()
    }
    
    // Make methods testable by removing side effects
    private func formatPhoneNumber(_ phone: String) -> String {
        // Extract phone formatting logic for testing
    }
    
    private func formatDateForAPI(_ date: String) -> String {
        // Extract date formatting logic for testing
    }
}
```

#### HomeViewModel Refactor
```swift
class HomeViewModel: BaseViewModel {
    private let productRepository: ProductRepositoryProtocol
    private let voucherRepository: VoucherRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    init(
        productRepository: ProductRepositoryProtocol,
        voucherRepository: VoucherRepositoryProtocol,
        favoritesRepository: FavoritesRepositoryProtocol,
        analyticsService: AnalyticsServiceProtocol
    ) {
        self.productRepository = productRepository
        self.voucherRepository = voucherRepository
        self.favoritesRepository = favoritesRepository
        self.analyticsService = analyticsService
        super.init()
    }
    
    // Add exposed methods for testing state changes
    var filteredProducts: [Product] {
        // Make filtering logic testable
    }
    
    var searchResults: [Product] {
        // Make search results accessible for testing
    }
}
```

#### CartViewModel Refactor
```swift
class CartViewModel: BaseViewModel {
    private let cartService: CartServiceProtocol
    private let deliveryService: DeliveryServiceProtocol
    private let voucherRepository: VoucherRepositoryProtocol
    
    init(
        cartService: CartServiceProtocol,
        deliveryService: DeliveryServiceProtocol,
        voucherRepository: VoucherRepositoryProtocol
    ) {
        self.cartService = cartService
        self.deliveryService = deliveryService
        self.voucherRepository = voucherRepository
        super.init()
    }
    
    // Expose computed properties for testing
    var canProceedToCheckout: Bool {
        !cartService.items.isEmpty
    }
    
    var canProceedToCheckoutForDelivery: Bool {
        !cartService.items.isEmpty && cartService.items.allSatisfy { $0.product.isDeliverable }
    }
}
```

### 3. DependencyContainer Refactor

**Current Issue:** Singleton pattern makes testing difficult
**Required Changes:**

```swift
protocol DependencyContainerProtocol {
    // Services
    var networkService: NetworkServiceProtocol { get }
    var keychainManager: KeychainManagerProtocol { get }
    var locationManager: LocationManagerProtocol { get }
    var analyticsService: AnalyticsServiceProtocol { get }
    
    // Repositories
    var authRepository: AuthRepositoryProtocol { get }
    var productRepository: ProductRepositoryProtocol { get }
    var cartService: CartServiceProtocol { get }
    
    // ViewModels
    func makeAuthViewModel() -> AuthViewModel
    func makeHomeViewModel() -> HomeViewModel
    func makeCartViewModel() -> CartViewModel
}

class DependencyContainer: DependencyContainerProtocol {
    // Remove static shared - inject container instead
    
    // Implement factory methods that accept protocols
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(
            authRepository: authRepository,
            keychainManager: keychainManager
        )
    }
    
    // Add configuration for test vs production
    init(isTestEnvironment: Bool = false) {
        if isTestEnvironment {
            // Use mock implementations
        } else {
            // Use production implementations
        }
    }
}
```

### 4. Model Improvements

**Current Issue:** Some models lack proper Codable implementation or testing support
**Required Changes:**

#### Add Missing Model Properties
```swift
// Ensure all models have proper CodingKeys
struct Product: Codable, Identifiable, Hashable, Sendable {
    // Add missing properties that tests expect
    let canBeDelivered: Bool {
        return isDeliverable && isActive
    }
    
    // Ensure all CodingKeys are properly mapped
    enum CodingKeys: String, CodingKey {
        // Complete mapping for all properties
    }
}

// Add missing models referenced in tests
struct Voucher: Codable, Identifiable {
    let id: String
    let code: String
    let title: String
    let description: String
    let discountType: VoucherDiscountType
    let discountValue: Double
    let minimumOrderAmount: Double
    let maximumDiscountAmount: Double
    let expiryDate: Date
    let isActive: Bool
    let usageLimit: Int
    let usageCount: Int
}

enum VoucherDiscountType: String, Codable {
    case percentage = "percentage"
    case fixed = "fixed"
}
```

### 5. App Architecture for Testing

**Current Issue:** App setup doesn't support test configuration
**Required Changes:**

#### App Entry Point Refactor
```swift
@main
struct TheCoffeeLinksApp: App {
    let dependencyContainer: DependencyContainerProtocol
    
    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        let isMockNetwork = ProcessInfo.processInfo.environment["MOCK_NETWORK"] == "true"
        
        self.dependencyContainer = DependencyContainer(isTestEnvironment: isUITesting)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencyContainer)
        }
    }
}
```

#### ContentView Refactor
```swift
struct ContentView: View {
    @EnvironmentObject var dependencyContainer: DependencyContainerProtocol
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var appState = AppState()
    
    init() {
        // Initialize with injected dependencies
    }
    
    var body: some View {
        // Use dependency-injected ViewModels
    }
}
```

### 6. UI Testing Infrastructure

**Required Changes:**

#### Add Accessibility Identifiers
```swift
// Add to all major UI components
Button("Add to Cart") {
    // action
}
.accessibilityIdentifier("AddToCartButton")

// Add to collection view cells
ProductCell()
    .accessibilityIdentifier("ProductCell")

// Add to tab bar items
TabView {
    HomeView()
        .tabItem {
            Label("Home", systemImage: "house")
        }
        .accessibilityIdentifier("HomeTab")
}
```

#### Add Test Configuration Support
```swift
// Add to ViewModels for test state injection
#if DEBUG
extension HomeViewModel {
    func setTestState(products: [Product], categories: [ProductCategory]) {
        self.products = products
        self.categories = categories
    }
}
#endif

// Add to Services for mock behavior
#if DEBUG
extension NetworkService {
    func enableMockMode() {
        // Switch to mock responses for UI testing
    }
}
#endif
```

### 7. Memory Management Improvements

**Required Changes:**

#### Proper Cleanup in ViewModels
```swift
class BaseViewModel: ObservableObject {
    private(set) var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
    
    // Add proper cleanup methods
    func cleanup() {
        cancellables.removeAll()
    }
}
```

### 8. Error Handling Standardization

**Required Changes:**

#### Consistent Error Types
```swift
// Create app-specific error types
enum AppError: Error, LocalizedError {
    case authentication(AuthError)
    case network(NetworkError)
    case validation(ValidationError)
    case business(BusinessError)
    
    var errorDescription: String? {
        // Provide user-friendly error messages
    }
}
```

## Implementation Priority

1. **High Priority** (Required for basic testing):
   - Protocol abstraction for NetworkService
   - DependencyContainer refactor
   - AuthViewModel dependency injection

2. **Medium Priority** (Required for comprehensive testing):
   - HomeViewModel and CartViewModel refactor
   - Repository protocol implementation
   - Model improvements

3. **Low Priority** (Nice to have):
   - UI testing infrastructure
   - Performance monitoring
   - Memory management improvements

## Testing Benefits After Refactor

1. **Unit Tests**: Complete isolation of components
2. **Integration Tests**: Controlled environment without side effects
3. **UI Tests**: Predictable behavior with mock data
4. **Performance Tests**: Repeatable benchmarks
5. **Memory Tests**: Leak detection and optimization

## Breaking Changes

These refactors will require updates to:
- All ViewModels instantiation
- Dependency injection throughout the app
- Test setup and teardown
- UI layer that uses ViewModels

The changes are significant but necessary for a robust, testable architecture that meets enterprise-level quality standards.