import XCTest
@testable import thecoffeelinks_client_ios

/// Tests for Model decoding from API responses
final class ModelDecodingTests: XCTestCase {
    
    // MARK: - Product Model (CamelCase API)
    
    func testProductDecodingFromJSON() throws {
        // API returns camelCase properties
        let json = """
        {
            "id": "test-product-1",
            "name": "Cappuccino",
            "description": "Rich espresso with steamed milk",
            "basePrice": 45000,
            "category": "coffee",
            "image": "/images/cappuccino.jpg",
            "isPopular": true,
            "isNew": false,
            "isActive": true,
            "isAvailable": true
        }
        """.data(using: .utf8)!
        
        // Use default keys for Product (camelCase)
        let decoder = JSONDecoder()
        let product = try decoder.decode(Product.self, from: json)
        
        XCTAssertEqual(product.id, "test-product-1")
        XCTAssertEqual(product.name, "Cappuccino")
        XCTAssertEqual(product.basePrice, 45000)
        XCTAssertEqual(product.category, "coffee") // Updated to String
        XCTAssertEqual(product.isPopular, true)
        
        print("✅ Product model decodes correctly from JSON")
    }
    
    // MARK: - Order Model (SnakeCase API)
    
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
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let order = try decoder.decode(Order.self, from: json)
        
        XCTAssertEqual(order.id, "order-123")
        XCTAssertEqual(order.status, "placed")
        XCTAssertEqual(order.totalAmount, 95000)
        
        print("✅ Order model decodes correctly from JSON")
    }
    
    // MARK: - Event Model (SnakeCase API)
    
    func testEventDecodingFromJSON() throws {
        let json = """
        {
            "id": "event-1",
            "title": "Coffee Tasting",
            "description": "Join us for a special coffee tasting event",
            "type": "tasting",
            "date": "2026-01-20T14:00:00Z",
            "location": "Main Lounge",
            "host_name": "Barista John"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.tryDateDecodingStrategy = .iso8601 // Custom or standard
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let event = try decoder.decode(Event.self, from: json)
        
        XCTAssertEqual(event.id, "event-1")
        XCTAssertEqual(event.title, "Coffee Tasting")
        XCTAssertEqual(event.hostName, "Barista John")
        
        print("✅ Event model decodes correctly from JSON")
    }
    
    // MARK: - Voucher Model (SnakeCase API)
    
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
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let voucher = try decoder.decode(Voucher.self, from: json)
        
        XCTAssertEqual(voucher.id, "voucher-1")
        XCTAssertEqual(voucher.code, "SAVE20")
        XCTAssertEqual(voucher.minSpend, 50000)
        
        print("✅ Voucher model decodes correctly from JSON")
    }
    
    // MARK: - Login API Response Model (SnakeCase API)
    
    func testLoginAPIResponseDecodingFromJSON() throws {
        let json = """
        {
            "success": true,
            "session": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "refresh_token": "refresh_token_xyz",
                "expires_in": 3600,
                "expires_at": 1768209701,
                "token_type": "bearer",
                "user": {
                    "id": "user-123",
                    "email": "test@example.com",
                    "aud": "authenticated",
                    "role": "authenticated"
                }
            },
            "user": {
                "id": "user-123",
                "email": "test@example.com",
                "aud": "authenticated",
                "role": "authenticated"
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(LoginAPIResponse.self, from: json)
        
        XCTAssertEqual(response.success, true)
        XCTAssertNotNil(response.session)
        XCTAssertEqual(response.session?.accessToken, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
        
        print("✅ LoginAPIResponse model decodes correctly from JSON")
    }
    
    // MARK: - Profile API Response Model (SnakeCase API)
    
    func testProfileAPIResponseDecodingFromJSON() throws {
        let json = """
        {
            "success": true,
            "user": {
                "id": "user-123",
                "email": "test@example.com",
                "name": "John Doe",
                "points": 150,
                "total_points_earned": 200,
                "member_since": "2026-01-01",
                "job_title": "Software Engineer",
                "industry": "Technology",
                "is_open_to_networking": true
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ProfileAPIResponse.self, from: json)
        
        XCTAssertEqual(response.success, true)
        XCTAssertNotNil(response.user)
        XCTAssertEqual(response.user?.id, "user-123")
        XCTAssertEqual(response.user?.points, 150)
        XCTAssertEqual(response.user?.totalPointsEarned, 200)
        
        print("✅ ProfileAPIResponse model decodes correctly from JSON")
    }
}

extension JSONDecoder {
    var tryDateDecodingStrategy: DateDecodingStrategy? {
        get { return nil }
        set { }
    }
}
