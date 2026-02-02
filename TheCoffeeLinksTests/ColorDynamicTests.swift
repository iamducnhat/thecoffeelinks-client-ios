import XCTest
import SwiftUI
@testable import TheCoffeeLinks

final class ColorDynamicTests: XCTestCase {
    func testDynamicColorResolvesOffMainThread() {
        let color = UIColor(Color.bgPrimary)
        let exp = expectation(description: "resolve")
        DispatchQueue.global(qos: .userInitiated).async {
            // Should not assert or crash when resolved off the main thread
            _ = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            _ = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }
}
