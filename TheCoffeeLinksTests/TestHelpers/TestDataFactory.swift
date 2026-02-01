//
//  TestDataFactory.swift
//  TheCoffeeLinksTests
//
//  Factory methods for creating test data
//

import Foundation
@testable import TheCoffeeLinks

struct TestDataFactory {
    
    // MARK: - User Models
    
    static func createUser(
        id: String = "user_123",
        email: String = "test@example.com",
        phone: String = "+84123456789",
        fullName: String = "Test User",
        isPhoneVerified: Bool = true
    ) -> User {
        return User(
            id: id,
            email: email,
            phone: phone,
            fullName: fullName,
            dateOfBirth: "1990-01-01",
            isActive: true,
            createdAt: Date(),
            phoneVerificationStatus: isPhoneVerified ? .verified : .pending
        )
    }
    
    // MARK: - Product Models
    
    static func createProduct(
        id: String = "prod_1",
        name: String = "Cappuccino",
        basePrice: Double = 45000,
        isDeliverable: Bool = true,
        isActive: Bool = true
    ) -> Product {
        return Product(
            id: id,
            name: name,
            description: "Delicious coffee",
            categoryId: "cat_coffee",
            categoryName: "Coffee",
            imageUrl: "https://example.com/image.jpg",
            basePrice: basePrice,
            sizeOptions: createSizeOptions(),
            availableToppings: ["topping_1", "topping_2"],
            isPopular: false,
            isNew: false,
            isActive: isActive,
            isHotSupported: true,
            isDeliverable: isDeliverable,
            deliveryPrepMinutes: 15,
            tags: ["coffee", "hot"],
            nutritionInfo: nil,
            allergens: []
        )
    }
    
    static func createProducts() -> [Product] {
        return [
            createProduct(id: "prod_1", name: "Cappuccino", basePrice: 45000),
            createProduct(id: "prod_2", name: "Latte", basePrice: 50000),
            createProduct(id: "prod_3", name: "Americano", basePrice: 35000),
            createProduct(id: "prod_4", name: "Croissant", basePrice: 25000, isDeliverable: false)
        ]
    }
    
    static func createSizeOptions() -> [SizeOption] {
        return [
            SizeOption(
                id: "size_s",
                name: "Small",
                priceAdjustment: 0,
                abbreviation: "S"
            ),
            SizeOption(
                id: "size_m",
                name: "Medium",
                priceAdjustment: 5000,
                abbreviation: "M"
            ),
            SizeOption(
                id: "size_l",
                name: "Large",
                priceAdjustment: 10000,
                abbreviation: "L"
            )
        ]
    }
    
    static func createToppings() -> [Topping] {
        return [
            Topping(
                id: "topping_1",
                name: "Extra Shot",
                price: 10000,
                category: "Coffee",
                isAvailable: true
            ),
            Topping(
                id: "topping_2",
                name: "Oat Milk",
                price: 8000,
                category: "Milk",
                isAvailable: true
            )
        ]
    }
    
    static func createCategories() -> [ProductCategory] {
        return [
            ProductCategory(
                id: "cat_coffee",
                name: "Coffee",
                displayOrder: 1,
                imageUrl: nil,
                isActive: true
            ),
            ProductCategory(
                id: "cat_food",
                name: "Food",
                displayOrder: 2,
                imageUrl: nil,
                isActive: true
            )
        ]
    }
    
    // MARK: - Cart Models
    
    static func createCartItem(
        product: Product? = nil,
        quantity: Int = 1,
        sizeOption: SizeOption? = nil,
        toppings: [Topping] = []
    ) -> CartItem {
        let testProduct = product ?? createProduct()
        return CartItem(
            id: UUID().uuidString,
            product: testProduct,
            quantity: quantity,
            selectedSize: sizeOption,
            selectedToppings: toppings
        )
    }
    
    static func createCartItems() -> [CartItem] {
        let products = createProducts()
        let sizeOptions = createSizeOptions()
        
        return [
            createCartItem(product: products[0], quantity: 2, sizeOption: sizeOptions[1]),
            createCartItem(product: products[1], quantity: 1, sizeOption: sizeOptions[0]),
            createCartItem(product: products[2], quantity: 1, sizeOption: sizeOptions[2])
        ]
    }
    
    // MARK: - Order Models
    
    static func createOrder(
        id: String = "order_123",
        status: OrderStatus = .placed,
        totalAmount: Double = 120000
    ) -> Order {
        return Order(
            id: id,
            userId: "user_123",
            storeId: "store_123",
            status: status,
            type: .takeAway,
            items: createOrderItems(),
            subtotalAmount: totalAmount - 5000,
            discountAmount: 5000,
            totalAmount: totalAmount,
            paymentMethod: .cash,
            paymentStatus: .pending,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date(),
            estimatedCompletionTime: nil,
            deliveryAddress: nil,
            deliveryFee: nil
        )
    }
    
    static func createOrderItems() -> [OrderItem] {
        let products = createProducts()
        return [
            OrderItem(
                id: "item_1",
                productId: products[0].id,
                productName: products[0].name,
                quantity: 2,
                unitPrice: products[0].basePrice,
                totalPrice: products[0].basePrice * 2,
                sizeOption: createSizeOptions()[1],
                selectedToppings: [],
                notes: nil
            )
        ]
    }
    
    // MARK: - Delivery Models
    
    static func createDeliveryAddress(
        id: String = "addr_123",
        label: String = "Home",
        fullAddress: String = "123 Test Street, Ho Chi Minh City",
        isDefault: Bool = true
    ) -> DeliveryAddress {
        var address = DeliveryAddress(
            id: id,
            label: label,
            fullAddress: fullAddress,
            isDefault: isDefault
        )
        address.coordinates = DeliveryAddress.Coordinates(
            latitude: 10.762622,
            longitude: 106.660172
        )
        return address
    }
    
    // MARK: - Store Models
    
    static func createStore(
        id: String = "store_123",
        name: String = "Test Cafe",
        isOpen: Bool = true
    ) -> Store {
        return Store(
            id: id,
            name: name,
            address: "123 Coffee Street",
            latitude: 10.762622,
            longitude: 106.660172,
            phone: "+84123456789",
            openingHours: createOperatingHours(),
            isActive: true,
            features: ["wifi", "delivery"],
            averageRating: 4.5,
            totalReviews: 150
        )
    }
    
    static func createOperatingHours() -> [String: OperatingHours] {
        let hours = OperatingHours(
            open: "07:00",
            close: "22:00",
            isOpen: true
        )
        
        return [
            "monday": hours,
            "tuesday": hours,
            "wednesday": hours,
            "thursday": hours,
            "friday": hours,
            "saturday": hours,
            "sunday": hours
        ]
    }
    
    // MARK: - API Response Models
    
    static func createAPIResponse<T: Codable>(
        data: T,
        success: Bool = true,
        message: String = "Success"
    ) -> APIResponse<T> {
        return APIResponse(
            data: data,
            success: success,
            message: message,
            errors: success ? [] : ["Test error"]
        )
    }
    
    // MARK: - Error Cases
    
    static func createNetworkError() -> NetworkError {
        return .networkFailure(URLError(.notConnectedToInternet))
    }
    
    static func createAuthError() -> NetworkError {
        return .unauthorized
    }
    
    // MARK: - JSON Strings for Decoding Tests
    
    static let validProductJSON = """
    {
        "id": "prod_123",
        "name": "Test Product",
        "description": "Test description",
        "category_id": "cat_123",
        "category_name": "Test Category",
        "image_url": "https://example.com/image.jpg",
        "base_price": 45000,
        "size_options": [
            {
                "id": "size_s",
                "name": "Small",
                "price_adjustment": 0,
                "abbreviation": "S"
            }
        ],
        "available_toppings": ["topping_1"],
        "is_popular": true,
        "is_new": false,
        "is_active": true,
        "is_hot_supported": true,
        "is_deliverable": true,
        "delivery_prep_minutes": 15,
        "tags": ["coffee"],
        "allergens": []
    }
    """
    
    static let invalidProductJSON = """
    {
        "id": "prod_123",
        "name": "Test Product"
        // Missing required fields
    }
    """
    
    static let validUserJSON = """
    {
        "id": "user_123",
        "email": "test@example.com",
        "phone": "+84123456789",
        "full_name": "Test User",
        "date_of_birth": "1990-01-01",
        "is_active": true,
        "created_at": "2026-01-01T00:00:00Z",
        "phone_verification_status": "verified"
    }
    """
}