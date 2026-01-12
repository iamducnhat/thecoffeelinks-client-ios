
import XCTest
@testable import thecoffeelinks_native_swift

final class ModelDecodingVerificationTests: XCTestCase {

    var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // EXACT LOGIC FROM APIClient
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try standard ISO8601
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
    }

    func testEventDecodingWithFractionalSeconds() {
        let json = """
        {
            "id": "event-123",
            "title": "Coffee Masterclass",
            "date": "2023-10-27T10:00:00.123Z",
            "description": "Learn to brew.",
            "type": "workshop",
            "host_name": "John Doe", 
            "location": "Cafe A",
            "image_url": "http://example.com/img.jpg"
        }
        """
        
        guard let data = json.data(using: .utf8) else {
            XCTFail("Failed to create data")
            return
        }
        
        do {
            let event = try decoder.decode(Event.self, from: data)
            XCTAssertEqual(event.title, "Coffee Masterclass")
            XCTAssertNotNil(event.date)
        } catch {
            XCTFail("Event decoding failed: \(error)")
        }
    }
    
    func testEventDecodingWithIntId() {
        let json = """
        {
            "id": 12345,
            "title": "Numeric ID Event",
            "date": "2023-10-27T10:00:00Z"
        }
        """
        
        guard let data = json.data(using: .utf8) else {
            XCTFail("Failed to create data")
            return
        }
        
        do {
            let event = try decoder.decode(Event.self, from: data)
            XCTAssertEqual(event.id, "12345")
            XCTAssertEqual(event.title, "Numeric ID Event")
        } catch {
            XCTFail("Event decoding with Int ID failed: \(error)")
        }
    }

    func testOrderDecodingWithOptionalItems() {
        // Order with an item MISSING productId (simulating the crash scenario)
        let json = """
        {
            "id": "order-1",
            "total_amount": 50.0,
            "order_items": [
                {
                    "id": "item-1",
                    "quantity": 1,
                    "price": 5.0
                },
                {
                    "id": "item-2",
                    "product_id": "prod-2",
                    "quantity": 2,
                    "price": 10.0
                }
            ]
        }
        """
        
        guard let data = json.data(using: .utf8) else {
            XCTFail("Failed to create data")
            return
        }
        
        do {
            let order = try decoder.decode(Order.self, from: data)
            XCTAssertEqual(order.totalAmount, 50.0)
            XCTAssertEqual(order.orderItems?.count, 2)
            
            // Verify optional productId
            XCTAssertNil(order.orderItems?[0].productId, "First item should have nil productId")
            XCTAssertEqual(order.orderItems?[1].productId, "prod-2")
        } catch {
             XCTFail("Order decoding failed: \(error)")
        }
    }
    
    func testVoucherDecodingWithMissingFields() {
        let json = """
        {
            "code": "WELCOME50",
            "description": "50% off",
            "min_spend": 0
        }
        """
        // Note: 'id', 'type', 'value' are missing
        
        guard let data = json.data(using: .utf8) else {
            XCTFail("Failed to create data")
            return
        }
        
        do {
            let voucher = try decoder.decode(Voucher.self, from: data)
            XCTAssertEqual(voucher.code, "WELCOME50")
            XCTAssertEqual(voucher.id, "WELCOME50", "Should fallback to code for ID")
            XCTAssertNil(voucher.type, "Type should be optional nil")
            XCTAssertNil(voucher.value, "Value should be optional nil")
        } catch {
             XCTFail("Voucher decoding failed: \(error)")
        }
    }
}
