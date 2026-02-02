import XCTest
import SwiftUI
@testable import TheCoffeeLinks

final class ColorDynamicTests: XCTestCase {
    func testDynamicColorResolvesOffMainThread() {
        let exp = expectation(description: "resolve")
        DispatchQueue.global(qos: .userInitiated).async {
            // Should not assert or crash when initialized and resolved off the main thread
            let color = UIColor(Color.bgPrimary)
            _ = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            _ = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }
}
