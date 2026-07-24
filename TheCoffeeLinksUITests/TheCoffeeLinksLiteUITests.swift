import XCTest

final class TheCoffeeLinksLiteUITests: XCTestCase {
    private func app(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + arguments
        app.launch()
        return app
    }

    func testExistingMemberDashboardAndQR() {
        let app = app()
        XCTAssertTrue(app.staticTexts["1,280"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.images["member.qr"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["member.code"].label, "TCL-240102")
    }

    func testNewMemberOTPAndNameFlow() {
        let app = app(["-ui-new-member"])
        let phone = app.textFields["090 123 4567"]
        XCTAssertTrue(phone.waitForExistence(timeout: 3))
        phone.tap()
        phone.typeText("0901234567")
        app.buttons["auth.send_otp"].tap()
        let otp = app.textFields["Six-digit verification code"]
        XCTAssertTrue(otp.waitForExistence(timeout: 2))
        otp.tap()
        otp.typeText("123456")
        app.buttons["auth.verify"].tap()
        let name = app.textFields["Nguyen Van An"]
        XCTAssertTrue(name.waitForExistence(timeout: 2))
        name.tap()
        name.typeText("Nguyen An")
        app.buttons["profile.continue"].tap()
        XCTAssertTrue(app.staticTexts["1,280"].waitForExistence(timeout: 3))
    }

    func testExpiredQRFallsBackToManualMemberCode() {
        let app = app(["-ui-qr-expired"])
        XCTAssertTrue(app.staticTexts["The QR is unavailable. Ask staff to enter your member code."].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["member.code"].label, "TCL-240102")
    }

    func testHistoryShowsStoreAndInvoice() {
        let app = app()
        app.buttons["history.view_all"].tap()
        XCTAssertTrue(app.staticTexts["The Coffee Links · Quận 1"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["TCL-INV-0102"].exists)
    }
}
