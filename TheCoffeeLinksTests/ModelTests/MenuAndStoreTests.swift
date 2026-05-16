import XCTest
@testable import TheCoffeeLinks

@MainActor
final class MenuAndStoreTests: XCTestCase {
    func testMenuFiltersActiveCategoryProductsAndPopularItems() {
        let activePopular = TestFactory.product(id: "popular", name: "Popular", categoryId: "coffee", isActive: true)
        let inactive = TestFactory.product(id: "inactive", name: "Inactive", categoryId: "coffee", isActive: false)
        let food = TestFactory.product(id: "food", name: "Food", categoryId: "food", isActive: true)
        let menu = Menu(categories: [], products: [activePopular, inactive, food], toppings: [], lastUpdated: Date())

        XCTAssertEqual(menu.products(for: "coffee").map(\.id), ["popular"])
        XCTAssertEqual(menu.popularProducts().map(\.id), ["popular", "food"])
    }

    func testStoreOpenStateUsesOpeningHoursForToday() {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let store = Store(
            id: "store-d1",
            name: "District 1",
            address: "123 Nguyen Hue",
            latitude: 10.77,
            longitude: 106.70,
            phone: nil,
            imageUrl: nil,
            layoutMapUrl: nil,
            openingHours: [OpeningHour(dayOfWeek: weekday, openMinutes: 0, closeMinutes: 23 * 60 + 59)],
            amenities: [.wifi],
            isOpen: nil,
            isBusy: nil,
            currentWaitMinutes: nil,
            deliveryAvailable: true,
            pickupAvailable: true,
            dineInAvailable: true
        )

        XCTAssertTrue(store.isCurrentlyOpen)
    }
}
