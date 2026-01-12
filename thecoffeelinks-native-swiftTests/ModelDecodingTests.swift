import XCTest
@testable import thecoffeelinks_native_swift

/// Tests for Model decoding from API responses
final class ModelDecodingTests: XCTestCase {
    
    // MARK: - Product Model
    
    func testProductDecodingFromJSON() throws {
        let json = """
        {
            "id": "test-product-1",
            "name": "Cappuccino",
            "description": "Rich espresso with steamed milk",
            "base_price": 45000,
            "category": "coffee",
            "image_url": "/images/cappuccino.jpg",
            "is_popular": true,
            "is_new": false,
            "is_active": true,
            "is_available": true
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let product = try decoder.decode(Product.self, from: json)
        
        XCTAssertEqual(product.id, "test-product-1")
        XCTAssertEqual(product.name, "Cappuccino")
        XCTAssertEqual(product.basePrice, 45000)
        XCTAssertEqual(product.category, .coffee)
        XCTAssertEqual(product.isPopular, true)
        XCTAssertEqual(product.isNew, false)
        
        print("✅ Product model decodes correctly from JSON")
    }
    
    func testProductDecodingWithNullFields() throws {
        let json = """
        {
            "id": "test-product-2",
            "name": "Mystery Drink",
            "base_price": 30000
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let product = try decoder.decode(Product.self, from: json)
        
        XCTAssertEqual(product.id, "test-product-2")
        XCTAssertNil(product.description)
        XCTAssertNil(product.category)
        XCTAssertNil(product.imageUrl)
        
        print("✅ Product model handles null/missing fields")
    }
    
    // MARK: - Order Model
    
    func testOrderDecodingFromJSON() throws {
        let json = """
        {
            "id": "order-123",
            "user_id": "user-456",
            "status": "placed",
            "total_amount": 95000,
            "discount_amount": 5000,
            "payment_method": "cash",
            "type": "take_away",
            "created_at": "2026-01-12T10:30:00Z",
            "store_id": "store-1",
            "delivery_address": "123 Coffee Street"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let order = try decoder.decode(Order.self, from: json)
        
        XCTAssertEqual(order.id, "order-123")
        XCTAssertEqual(order.status, .placed)
        XCTAssertEqual(order.totalAmount, 95000)
        XCTAssertEqual(order.discountAmount, 5000)
        XCTAssertEqual(order.paymentMethod, .cash)
        XCTAssertEqual(order.type, .takeAway)
        XCTAssertEqual(order.deliveryAddress, "123 Coffee Street")
        
        print("✅ Order model decodes correctly from JSON")
    }
    
    // MARK: - Event Model
    
    func testEventDecodingFromJSON() throws {
        let json = """
        {
            "id": "event-1",
            "title": "Coffee Tasting",
            "description": "Join us for a special coffee tasting event",
            "type": "tasting",
            "date": "2026-01-20T14:00:00Z",
            "location": "Main Lounge"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let event = try decoder.decode(Event.self, from: json)
        
        XCTAssertEqual(event.id, "event-1")
        XCTAssertEqual(event.title, "Coffee Tasting")
        XCTAssertEqual(event.type, "tasting")
        
        print("✅ Event model decodes correctly from JSON")
    }
    
    // MARK: - Voucher Model
    
    func testVoucherDecodingFromJSON() throws {
        let json = """
        {
            "id": "voucher-1",
            "code": "SAVE20",
            "type": "discount",
            "value": 20,
            "description": "Save 20% on your order",
            "min_spend": 50000,
            "is_used": false,
            "expires_at": "2026-02-01T23:59:59Z"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let voucher = try decoder.decode(Voucher.self, from: json)
        
        XCTAssertEqual(voucher.id, "voucher-1")
        XCTAssertEqual(voucher.code, "SAVE20")
        XCTAssertEqual(voucher.value, 20)
        XCTAssertFalse(voucher.isUsed)
        
        print("✅ Voucher model decodes correctly from JSON")
    }
    
    // MARK: - User Model
    
    func testUserDecodingFromJSON() throws {
        let json = """
        {
            "id": "user-123",
            "email": "test@example.com",
            "full_name": "John Doe",
            "avatar_url": "/avatars/john.jpg",
            "points": 150,
            "job_title": "Software Engineer",
            "industry": "Technology",
            "bio": "Coffee lover and code writer",
            "is_open_to_networking": true
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: json)
        
        XCTAssertEqual(user.id, "user-123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.fullName, "John Doe")
        XCTAssertEqual(user.points, 150)
        XCTAssertEqual(user.jobTitle, "Software Engineer")
        XCTAssertEqual(user.isOpenToNetworking, true)
        
        print("✅ User model decodes correctly from JSON")
    }
    
    // MARK: - Auth Response Model
    
    func testAuthResponseDecodingFromJSON() throws {
        let json = """
        {
            "success": true,
            "session": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "refresh_token": "refresh_token_xyz",
                "expires_in": 3600,
                "token_type": "bearer"
            },
            "user": {
                "id": "user-123",
                "email": "test@example.com"
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(AuthResponse.self, from: json)
        
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.session)
        XCTAssertEqual(response.session?.accessToken, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
        XCTAssertNotNil(response.user)
        XCTAssertEqual(response.user?.id, "user-123")
        
        print("✅ AuthResponse model decodes correctly from JSON")
    }
}
