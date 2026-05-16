import XCTest

final class TheCoffeeLinksUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing-reset-state"]
        app.launchEnvironment = ["THECOFFEELINKS_UI_TESTING": "1"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testLaunchReachesGuestTabShell() throws {
        app.launch()

        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 12), "Guest users should reach the browseable tab shell without auth or live credentials.")
        XCTAssertGreaterThanOrEqual(app.tabBars.buttons.count, 5)
    }

    @MainActor
    func testPrimaryTabsCanBeSelectedWithoutCrash() throws {
        app.launch()
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 12))

        let buttons = tabBar.buttons
        XCTAssertGreaterThanOrEqual(buttons.count, 5)

        for index in 0..<min(buttons.count, 5) {
            buttons.element(boundBy: index).tap()
            XCTAssertTrue(tabBar.exists)
        }
    }

    @MainActor
    func testLaunchScreenshotForVisualRegressionAnchor() throws {
        app.launch()
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 12))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Guest Shell"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
