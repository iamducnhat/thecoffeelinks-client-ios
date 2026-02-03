import XCTest
@testable import TheCoffeeLinks

final class ProductPriceTests: TestBaseClass {

    func test_priceFor_returnsSizePrice_whenSizeExists() {
        let product = Product(
            id: "p1",
            name: "Test",
            description: nil,
            categoryId: "c",
            categoryName: nil,
            imageUrl: nil,
            basePrice: 30000,
            sizeOptions: [
                SizeOption(size: .small, price: 25000, isEnabled: true),
                SizeOption(size: .medium, price: 30000, isEnabled: true),
                SizeOption(size: .large, price: 35000, isEnabled: true),
            ],
            availableToppings: [],
            isPopular: false,
            isNew: false,
            isActive: true,
            isHotSupported: true,
            isDeliverable: true,
            deliveryPrepMinutes: nil,
            tags: [],
            nutritionInfo: nil,
            allergens: []
        )

        XCTAssertEqual(product.price(for: .medium), 30000)
    }

    func test_priceFor_returnsBasePrice_whenSizeMissing() {
        let product = Product(
            id: "p2",
            name: "Test 2",
            description: nil,
            categoryId: "c",
            categoryName: nil,
            imageUrl: nil,
            basePrice: 50000,
            sizeOptions: [],
            availableToppings: [],
            isPopular: false,
            isNew: false,
            isActive: true,
            isHotSupported: true,
            isDeliverable: true,
            deliveryPrepMinutes: nil,
            tags: [],
            nutritionInfo: nil,
            allergens: []
        )

        XCTAssertEqual(product.price(for: .large), 50000)
    }

    func test_priceFor_concurrentAccess_isStable() {
        let product = Product(
            id: "p3",
            name: "Test 3",
            description: nil,
            categoryId: "c",
            categoryName: nil,
            imageUrl: nil,
            basePrice: 20000,
            sizeOptions: [SizeOption(size: .small, price: 18000, isEnabled: true)],
            availableToppings: [],
            isPopular: false,
            isNew: false,
            isActive: true,
            isHotSupported: true,
            isDeliverable: true,
            deliveryPrepMinutes: nil,
            tags: [],
            nutritionInfo: nil,
            allergens: []
        )

        let iterations = 2_000
        var results = [Double]()
        let lock = NSLock()

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            let price = product.price(for: .small)
            lock.lock()
            results.append(price)
            lock.unlock()
        }

        XCTAssertEqual(results.count, iterations)
        XCTAssertTrue(results.allSatisfy { $0 == 18000 })
    }
}
