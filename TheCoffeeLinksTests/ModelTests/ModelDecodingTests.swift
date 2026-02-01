//
//  ModelDecodingTests.swift
//  TheCoffeeLinksTests
//
//  Comprehensive tests for model decoding with proper error handling
//

import XCTest
@testable import TheCoffeeLinks

final class ModelDecodingTests: TestBaseClass {
    
    var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    override func tearDown() {
        super.tearDown()
        decoder = nil
    }
    
    // MARK: - Product Model Tests
    
    func testProductDecodingSuccess() throws {
        // Given
        let jsonData = TestDataFactory.validProductJSON.data(using: .utf8)!
        
        // When
        let product = try decoder.decode(Product.self, from: jsonData)
        
        // Then
        XCTAssertEqual(product.id, "prod_123")
        XCTAssertEqual(product.name, "Test Product")
        XCTAssertEqual(product.description, "Test description")
        XCTAssertEqual(product.categoryId, "cat_123")
        XCTAssertEqual(product.categoryName, "Test Category")
        XCTAssertEqual(product.basePrice, 45000)
        XCTAssertTrue(product.isPopular)
        XCTAssertFalse(product.isNew)
        XCTAssertTrue(product.isActive)
        XCTAssertTrue(product.isDeliverable)
        XCTAssertEqual(product.deliveryPrepMinutes, 15)
        XCTAssertEqual(product.sizeOptions.count, 1)
        XCTAssertEqual(product.availableToppings.count, 1)
    }
    
    func testProductDecodingWithMissingOptionalFields() throws {
        // Given
        let json = """
        {
            "id": "prod_123",
            "name": "Minimal Product",
            "category_id": "cat_123",
            "base_price": 30000,
            "size_options": [],
            "available_toppings": [],
            "is_popular": false,
            "is_new": false,
            "is_active": true,
            "is_hot_supported": true,
            "is_deliverable": true,
            "tags": [],
            "allergens": []
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let product = try decoder.decode(Product.self, from: jsonData)
        
        // Then
        XCTAssertEqual(product.id, "prod_123")
        XCTAssertEqual(product.name, "Minimal Product")
        XCTAssertNil(product.description)
        XCTAssertNil(product.categoryName)
        XCTAssertNil(product.imageUrl)
        XCTAssertNil(product.deliveryPrepMinutes)
        XCTAssertNil(product.nutritionInfo)
    }
    
    func testProductDecodingWithInvalidData() {
        // Given
        let invalidJSON = """
        {
            "id": "prod_123"
            // Missing required fields
        }
        """
        let jsonData = invalidJSON.data(using: .utf8)!
        
        // When/Then
        XCTAssertThrowsError(try decoder.decode(Product.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - SizeOption Tests
    
    func testSizeOptionDecoding() throws {
        // Given
        let json = """
        {
            "id": "size_m",
            "name": "Medium",
            "price_adjustment": 5000,
            "abbreviation": "M"
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let sizeOption = try decoder.decode(SizeOption.self, from: jsonData)
        
        // Then
        XCTAssertEqual(sizeOption.id, "size_m")
        XCTAssertEqual(sizeOption.name, "Medium")
        XCTAssertEqual(sizeOption.priceAdjustment, 5000)
        XCTAssertEqual(sizeOption.abbreviation, "M")
    }
    
    // MARK: - User Model Tests
    
    func testUserDecodingSuccess() throws {
        // Given
        let jsonData = TestDataFactory.validUserJSON.data(using: .utf8)!
        
        // When
        let user = try decoder.decode(User.self, from: jsonData)
        
        // Then
        XCTAssertEqual(user.id, "user_123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.phone, "+84123456789")
        XCTAssertEqual(user.fullName, "Test User")
        XCTAssertEqual(user.dateOfBirth, "1990-01-01")
        XCTAssertTrue(user.isActive)
        XCTAssertEqual(user.phoneVerificationStatus, .verified)
    }
    
    func testUserDecodingWithUnverifiedPhone() throws {
        // Given
        let json = """
        {
            "id": "user_123",
            "email": "test@example.com",
            "phone": "+84123456789",
            "full_name": "Test User",
            "date_of_birth": "1990-01-01",
            "is_active": true,
            "created_at": "2026-01-01T00:00:00Z",
            "phone_verification_status": "pending"
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let user = try decoder.decode(User.self, from: jsonData)
        
        // Then
        XCTAssertEqual(user.phoneVerificationStatus, .pending)
    }
    
    // MARK: - Order Model Tests
    
    func testOrderDecoding() throws {
        // Given
        let json = """
        {
            "id": "order_123",
            "user_id": "user_123",
            "store_id": "store_123",
            "status": "placed",
            "type": "take_away",
            "items": [
                {
                    "id": "item_1",
                    "product_id": "prod_1",
                    "product_name": "Cappuccino",
                    "quantity": 2,
                    "unit_price": 45000,
                    "total_price": 90000,
                    "size_option": {
                        "id": "size_m",
                        "name": "Medium",
                        "price_adjustment": 0,
                        "abbreviation": "M"
                    },
                    "selected_toppings": [],
                    "notes": null
                }
            ],
            "subtotal_amount": 90000,
            "discount_amount": 0,
            "total_amount": 90000,
            "payment_method": "cash",
            "payment_status": "pending",
            "notes": null,
            "created_at": "2026-01-01T10:00:00Z",
            "updated_at": "2026-01-01T10:00:00Z",
            "estimated_completion_time": null,
            "delivery_address": null,
            "delivery_fee": null
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let order = try decoder.decode(Order.self, from: jsonData)
        
        // Then
        XCTAssertEqual(order.id, "order_123")
        XCTAssertEqual(order.userId, "user_123")
        XCTAssertEqual(order.storeId, "store_123")
        XCTAssertEqual(order.status, .placed)
        XCTAssertEqual(order.type, .takeAway)
        XCTAssertEqual(order.items.count, 1)
        XCTAssertEqual(order.subtotalAmount, 90000)
        XCTAssertEqual(order.totalAmount, 90000)
        XCTAssertEqual(order.paymentMethod, .cash)
        XCTAssertEqual(order.paymentStatus, .pending)
    }
    
    func testOrderWithDeliveryDecoding() throws {
        // Given
        let json = """
        {
            "id": "order_123",
            "user_id": "user_123",
            "store_id": "store_123",
            "status": "placed",
            "type": "delivery",
            "items": [],
            "subtotal_amount": 75000,
            "discount_amount": 5000,
            "total_amount": 95000,
            "payment_method": "card",
            "payment_status": "completed",
            "notes": "Please ring the bell",
            "created_at": "2026-01-01T10:00:00Z",
            "updated_at": "2026-01-01T10:00:00Z",
            "estimated_completion_time": "2026-01-01T10:30:00Z",
            "delivery_address": {
                "id": "addr_1",
                "label": "Home",
                "full_address": "123 Test Street",
                "is_default": true,
                "coordinates": {
                    "latitude": 10.762622,
                    "longitude": 106.660172
                }
            },
            "delivery_fee": 25000
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let order = try decoder.decode(Order.self, from: jsonData)
        
        // Then
        XCTAssertEqual(order.type, .delivery)
        XCTAssertEqual(order.paymentMethod, .card)
        XCTAssertEqual(order.paymentStatus, .completed)
        XCTAssertEqual(order.notes, "Please ring the bell")
        XCTAssertNotNil(order.deliveryAddress)
        XCTAssertEqual(order.deliveryFee, 25000)
        XCTAssertNotNil(order.estimatedCompletionTime)
    }
    
    // MARK: - DeliveryAddress Model Tests
    
    func testDeliveryAddressDecoding() throws {
        // Given
        let json = """
        {
            "id": "addr_123",
            "label": "Office",
            "full_address": "456 Business Street, District 1, Ho Chi Minh City",
            "is_default": false,
            "coordinates": {
                "latitude": 10.762622,
                "longitude": 106.660172
            }
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let address = try decoder.decode(DeliveryAddress.self, from: jsonData)
        
        // Then
        XCTAssertEqual(address.id, "addr_123")
        XCTAssertEqual(address.label, "Office")
        XCTAssertEqual(address.fullAddress, "456 Business Street, District 1, Ho Chi Minh City")
        XCTAssertFalse(address.isDefault)
        XCTAssertEqual(address.coordinates?.latitude, 10.762622)
        XCTAssertEqual(address.coordinates?.longitude, 106.660172)
    }
    
    func testDeliveryAddressWithoutCoordinates() throws {
        // Given
        let json = """
        {
            "id": "addr_123",
            "label": "Home",
            "full_address": "123 Test Street",
            "is_default": true
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let address = try decoder.decode(DeliveryAddress.self, from: jsonData)
        
        // Then
        XCTAssertNil(address.coordinates)
    }
    
    // MARK: - Voucher Model Tests
    
    func testVoucherDecoding() throws {
        // Given
        let json = """
        {
            "id": "voucher_123",
            "code": "WELCOME20",
            "title": "Welcome Discount",
            "description": "Get 20% off your first order",
            "discount_type": "percentage",
            "discount_value": 20.0,
            "minimum_order_amount": 50000,
            "maximum_discount_amount": 100000,
            "expiry_date": "2026-12-31T23:59:59Z",
            "is_active": true,
            "usage_limit": 100,
            "usage_count": 25
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let voucher = try decoder.decode(Voucher.self, from: jsonData)
        
        // Then
        XCTAssertEqual(voucher.id, "voucher_123")
        XCTAssertEqual(voucher.code, "WELCOME20")
        XCTAssertEqual(voucher.title, "Welcome Discount")
        XCTAssertEqual(voucher.discountType, .percentage)
        XCTAssertEqual(voucher.discountValue, 20.0)
        XCTAssertEqual(voucher.minimumOrderAmount, 50000)
        XCTAssertEqual(voucher.maximumDiscountAmount, 100000)
        XCTAssertTrue(voucher.isActive)
        XCTAssertEqual(voucher.usageLimit, 100)
        XCTAssertEqual(voucher.usageCount, 25)
    }
    
    // MARK: - API Response Model Tests
    
    func testAPIResponseDecoding() throws {
        // Given
        let json = """
        {
            "success": true,
            "message": "Operation completed successfully",
            "data": {
                "id": "test_123",
                "value": "test_value"
            },
            "errors": []
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        struct TestData: Codable {
            let id: String
            let value: String
        }
        
        let response = try decoder.decode(APIResponse<TestData>.self, from: jsonData)
        
        // Then
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Operation completed successfully")
        XCTAssertEqual(response.data.id, "test_123")
        XCTAssertEqual(response.data.value, "test_value")
        XCTAssertTrue(response.errors.isEmpty)
    }
    
    func testAPIResponseErrorDecoding() throws {
        // Given
        let json = """
        {
            "success": false,
            "message": "Validation failed",
            "data": null,
            "errors": ["Field is required", "Invalid format"]
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let response = try decoder.decode(APIResponse<String?>.self, from: jsonData)
        
        // Then
        XCTAssertFalse(response.success)
        XCTAssertEqual(response.message, "Validation failed")
        XCTAssertNil(response.data)
        XCTAssertEqual(response.errors.count, 2)
        XCTAssertEqual(response.errors[0], "Field is required")
        XCTAssertEqual(response.errors[1], "Invalid format")
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testDecodingWithExtraFields() throws {
        // Given - JSON with extra fields that shouldn't break decoding
        let json = """
        {
            "id": "prod_123",
            "name": "Test Product",
            "category_id": "cat_123",
            "base_price": 45000,
            "size_options": [],
            "available_toppings": [],
            "is_popular": false,
            "is_new": false,
            "is_active": true,
            "is_hot_supported": true,
            "is_deliverable": true,
            "tags": [],
            "allergens": [],
            "extra_field_1": "should_be_ignored",
            "extra_field_2": 12345
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When/Then - should not throw
        XCTAssertNoThrow(try decoder.decode(Product.self, from: jsonData))
    }
    
    func testDecodingWithNullValues() throws {
        // Given
        let json = """
        {
            "id": "prod_123",
            "name": "Test Product",
            "description": null,
            "category_id": "cat_123",
            "category_name": null,
            "image_url": null,
            "base_price": 45000,
            "size_options": [],
            "available_toppings": [],
            "is_popular": false,
            "is_new": false,
            "is_active": true,
            "is_hot_supported": true,
            "is_deliverable": true,
            "delivery_prep_minutes": null,
            "tags": [],
            "nutrition_info": null,
            "allergens": []
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let product = try decoder.decode(Product.self, from: jsonData)
        
        // Then
        XCTAssertNil(product.description)
        XCTAssertNil(product.categoryName)
        XCTAssertNil(product.imageUrl)
        XCTAssertNil(product.deliveryPrepMinutes)
        XCTAssertNil(product.nutritionInfo)
    }
    
    func testDecodingWithWrongTypeValues() {
        // Given
        let json = """
        {
            "id": 12345,
            "name": "Test Product",
            "category_id": "cat_123",
            "base_price": "not_a_number",
            "size_options": [],
            "available_toppings": [],
            "is_popular": false,
            "is_new": false,
            "is_active": true,
            "is_hot_supported": true,
            "is_deliverable": true,
            "tags": [],
            "allergens": []
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When/Then
        XCTAssertThrowsError(try decoder.decode(Product.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Date Decoding Tests
    
    func testDateDecoding() throws {
        // Given
        let json = """
        {
            "id": "user_123",
            "email": "test@example.com",
            "phone": "+84123456789",
            "full_name": "Test User",
            "date_of_birth": "1990-01-01",
            "is_active": true,
            "created_at": "2026-01-01T10:30:45Z",
            "phone_verification_status": "verified"
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When
        let user = try decoder.decode(User.self, from: jsonData)
        
        // Then
        XCTAssertNotNil(user.createdAt)
        
        // Verify the date was parsed correctly
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: user.createdAt)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 1)
        XCTAssertEqual(components.hour, 10)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 45)
    }
    
    func testInvalidDateFormat() {
        // Given
        let json = """
        {
            "id": "user_123",
            "email": "test@example.com",
            "phone": "+84123456789",
            "full_name": "Test User",
            "date_of_birth": "1990-01-01",
            "is_active": true,
            "created_at": "invalid-date-format",
            "phone_verification_status": "verified"
        }
        """
        let jsonData = json.data(using: .utf8)!
        
        // When/Then
        XCTAssertThrowsError(try decoder.decode(User.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
}

// MARK: - Test Data Extensions

extension TestDataFactory {
    static func createVoucher(
        id: String = "voucher_123",
        code: String = "TEST20",
        discountType: VoucherDiscountType = .percentage,
        discountValue: Double = 20.0,
        minimumOrderAmount: Double = 0,
        discountAmount: Double? = nil
    ) -> Voucher {
        return Voucher(
            id: id,
            code: code,
            title: "Test Voucher",
            description: "Test discount voucher",
            discountType: discountType,
            discountValue: discountValue,
            minimumOrderAmount: minimumOrderAmount,
            maximumDiscountAmount: discountAmount ?? (discountType == .percentage ? 50000 : discountValue),
            expiryDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days from now
            isActive: true,
            usageLimit: 100,
            usageCount: 0
        )
    }
}