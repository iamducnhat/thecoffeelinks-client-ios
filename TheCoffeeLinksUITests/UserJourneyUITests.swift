//
//  UserJourneyUITests.swift
//  TheCoffeeLinksUITests
//
//  Critical user journey tests using XCUITest
//

import XCTest

final class UserJourneyUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // Set up test environment
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = [
            "MOCK_NETWORK": "true",
            "SKIP_ONBOARDING": "false"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testAppLaunchShowsOnboarding() throws {
        // Given - First time user
        
        // Then - Should show onboarding
        XCTAssertTrue(app.staticTexts["Welcome to TheCoffeeLinks"].exists)
        XCTAssertTrue(app.buttons["Get Started"].exists)
    }
    
    // MARK: - Onboarding Flow Tests
    
    func testCompleteOnboardingFlow() throws {
        // Given - App is launched for first time
        
        // When - User taps through onboarding
        if app.staticTexts["Welcome to TheCoffeeLinks"].waitForExistence(timeout: 5) {
            app.buttons["Get Started"].tap()
        }
        
        // Navigate through onboarding screens
        if app.buttons["Next"].waitForExistence(timeout: 3) {
            app.buttons["Next"].tap()
        }
        
        if app.buttons["Next"].exists {
            app.buttons["Next"].tap()
        }
        
        if app.buttons["Complete Onboarding"].exists {
            app.buttons["Complete Onboarding"].tap()
        }
        
        // Then - Should reach main app
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5))
    }
    
    // MARK: - Authentication Flow Tests
    
    func testUserRegistrationFlow() throws {
        skipOnboardingIfNeeded()
        
        // Given - User needs to register
        navigateToAuth()
        
        // When - User fills registration form
        let phoneField = app.textFields["Phone Number"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 5))
        phoneField.tap()
        phoneField.typeText("987654321")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("SecurePassword123!")
        
        let nameField = app.textFields["Full Name"]
        nameField.tap()
        nameField.typeText("Test User")
        
        let dobField = app.textFields["Date of Birth"]
        dobField.tap()
        dobField.typeText("15/06/1995")
        
        app.buttons["Register"].tap()
        
        // Then - Should show OTP verification screen
        XCTAssertTrue(app.staticTexts["Enter Verification Code"].waitForExistence(timeout: 5))
        
        // When - User enters OTP (in mock mode, any 6 digits work)
        let otpField = app.textFields["OTP Code"]
        otpField.tap()
        otpField.typeText("123456")
        
        app.buttons["Verify"].tap()
        
        // Then - Should be authenticated and show main app
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5))
    }
    
    func testUserLoginFlow() throws {
        skipOnboardingIfNeeded()
        
        // Given - User has existing account
        navigateToAuth()
        
        // Switch to login mode
        app.buttons["Already have an account?"].tap()
        
        // When - User enters credentials
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        app.buttons["Sign In"].tap()
        
        // Then - Should be authenticated
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5))
    }
    
    func testLoginWithInvalidCredentials() throws {
        skipOnboardingIfNeeded()
        navigateToAuth()
        
        // Switch to login mode
        app.buttons["Already have an account?"].tap()
        
        // When - User enters invalid credentials
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("invalid@email.com")
        
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("wrongpassword")
        
        app.buttons["Sign In"].tap()
        
        // Then - Should show error message
        XCTAssertTrue(app.staticTexts["Invalid credentials"].waitForExistence(timeout: 3))
    }
    
    // MARK: - Home Screen Tests
    
    func testHomeScreenLoadsProducts() throws {
        authenticateUser()
        
        // Given - User is on home screen
        ensureOnHomeTab()
        
        // Then - Should show products
        XCTAssertTrue(app.scrollViews.element.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Popular"].exists)
        XCTAssertTrue(app.staticTexts["Categories"].exists)
        
        // Should show at least one product
        let productCells = app.cells.matching(identifier: "ProductCell")
        XCTAssertGreaterThan(productCells.count, 0)
    }
    
    func testProductCategoryFiltering() throws {
        authenticateUser()
        ensureOnHomeTab()
        
        // Given - Products are loaded
        XCTAssertTrue(app.scrollViews.element.waitForExistence(timeout: 5))
        
        // When - User selects a category
        let coffeeCategory = app.buttons["Coffee Category"]
        if coffeeCategory.waitForExistence(timeout: 3) {
            coffeeCategory.tap()
        }
        
        // Then - Should filter products
        let productCells = app.cells.matching(identifier: "ProductCell")
        XCTAssertGreaterThan(productCells.count, 0)
        
        // Verify category filter is active
        XCTAssertTrue(app.buttons["Clear Filter"].exists)
    }
    
    func testProductSearch() throws {
        authenticateUser()
        ensureOnHomeTab()
        
        // Given - User wants to search
        let searchField = app.searchFields["Search products..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        
        // When - User searches for product
        searchField.tap()
        searchField.typeText("Cappuccino")
        
        app.keyboards.buttons["Search"].tap()
        
        // Then - Should show search results
        XCTAssertTrue(app.staticTexts["Search Results"].waitForExistence(timeout: 3))
        
        let productCells = app.cells.matching(identifier: "ProductCell")
        XCTAssertGreaterThan(productCells.count, 0)
    }
    
    // MARK: - Product Detail Tests
    
    func testProductDetailFlow() throws {
        authenticateUser()
        ensureOnHomeTab()
        
        // Given - Products are displayed
        XCTAssertTrue(app.scrollViews.element.waitForExistence(timeout: 5))
        
        // When - User taps on first product
        let firstProduct = app.cells.matching(identifier: "ProductCell").element(boundBy: 0)
        XCTAssertTrue(firstProduct.waitForExistence(timeout: 3))
        firstProduct.tap()
        
        // Then - Should show product detail
        XCTAssertTrue(app.staticTexts["Product Details"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Add to Cart"].exists)
        XCTAssertTrue(app.staticTexts["Size"].exists)
    }
    
    func testAddProductToCart() throws {
        authenticateUser()
        ensureOnHomeTab()
        
        // Navigate to product detail
        let firstProduct = app.cells.matching(identifier: "ProductCell").element(boundBy: 0)
        firstProduct.tap()
        
        XCTAssertTrue(app.staticTexts["Product Details"].waitForExistence(timeout: 3))
        
        // When - User customizes and adds to cart
        // Select size
        let mediumSize = app.buttons["Medium"]
        if mediumSize.waitForExistence(timeout: 3) {
            mediumSize.tap()
        }
        
        // Add toppings
        let extraShot = app.buttons["Extra Shot"]
        if extraShot.exists {
            extraShot.tap()
        }
        
        // Add to cart
        app.buttons["Add to Cart"].tap()
        
        // Then - Should show success feedback
        XCTAssertTrue(app.staticTexts["Added to cart"].waitForExistence(timeout: 2))
        
        // Cart icon should show item count
        let cartBadge = app.otherElements["Cart Badge"]
        XCTAssertTrue(cartBadge.waitForExistence(timeout: 2))
    }
    
    // MARK: - Cart Flow Tests
    
    func testCartManagement() throws {
        authenticateUser()
        addItemToCart()
        
        // When - User opens cart
        app.tabBars.buttons["Cart"].tap()
        
        // Then - Should show cart items
        XCTAssertTrue(app.staticTexts["Your Cart"].waitForExistence(timeout: 3))
        
        let cartItems = app.cells.matching(identifier: "CartItem")
        XCTAssertGreaterThan(cartItems.count, 0)
        
        // Test quantity adjustment
        let increaseButton = app.buttons["Increase Quantity"].firstMatch
        if increaseButton.exists {
            increaseButton.tap()
        }
        
        // Test item removal
        let removeButton = app.buttons["Remove Item"].firstMatch
        if removeButton.exists {
            removeButton.tap()
            
            // Confirm removal
            if app.buttons["Confirm"].waitForExistence(timeout: 2) {
                app.buttons["Confirm"].tap()
            }
        }
    }
    
    func testCheckoutFlow() throws {
        authenticateUser()
        addItemToCart()
        
        // Go to cart
        app.tabBars.buttons["Cart"].tap()
        
        // When - User proceeds to checkout
        let checkoutButton = app.buttons["Proceed to Checkout"]
        XCTAssertTrue(checkoutButton.waitForExistence(timeout: 3))
        XCTAssertTrue(checkoutButton.isEnabled)
        
        checkoutButton.tap()
        
        // Then - Should show checkout screen
        XCTAssertTrue(app.staticTexts["Checkout"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Order Summary"].exists)
        XCTAssertTrue(app.staticTexts["Payment Method"].exists)
    }
    
    func testDeliveryModeToggle() throws {
        authenticateUser()
        addItemToCart()
        
        app.tabBars.buttons["Cart"].tap()
        
        // When - User toggles delivery mode
        let deliveryToggle = app.switches["Delivery Mode"]
        if deliveryToggle.waitForExistence(timeout: 3) {
            deliveryToggle.tap()
        }
        
        // Then - Should show delivery options
        XCTAssertTrue(app.staticTexts["Delivery Address"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Add Address"].exists)
    }
    
    // MARK: - Profile Tests
    
    func testProfileScreen() throws {
        authenticateUser()
        
        // When - User goes to profile
        app.tabBars.buttons["Profile"].tap()
        
        // Then - Should show profile information
        XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Test User"].exists) // Mocked user name
        XCTAssertTrue(app.staticTexts["test@example.com"].exists) // Mocked email
    }
    
    func testLogoutFlow() throws {
        authenticateUser()
        
        app.tabBars.buttons["Profile"].tap()
        
        // When - User logs out
        app.buttons["Sign Out"].tap()
        
        // Confirm logout
        if app.buttons["Confirm"].waitForExistence(timeout: 2) {
            app.buttons["Confirm"].tap()
        }
        
        // Then - Should return to authentication screen
        XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 5))
    }
    
    // MARK: - Connectivity Tests
    
    func testOfflineMode() throws {
        authenticateUser()
        
        // Simulate network disconnection
        app.launchEnvironment["SIMULATE_OFFLINE"] = "true"
        
        // When - User tries to load products
        ensureOnHomeTab()
        app.buttons["Refresh"].tap()
        
        // Then - Should show offline message
        XCTAssertTrue(app.staticTexts["No internet connection"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Try Again"].exists)
    }
    
    // MARK: - Helper Methods
    
    private func skipOnboardingIfNeeded() {
        if app.staticTexts["Welcome to TheCoffeeLinks"].waitForExistence(timeout: 2) {
            // Skip onboarding for faster tests
            app.buttons["Skip"].tap()
        }
    }
    
    private func navigateToAuth() {
        if app.buttons["Sign In"].waitForExistence(timeout: 3) {
            // Already on auth screen
            return
        }
        
        // Look for auth entry points
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
    }
    
    private func authenticateUser() {
        skipOnboardingIfNeeded()
        
        // Quick authentication for testing
        if !app.tabBars.element.exists {
            navigateToAuth()
            
            if app.textFields["Email"].waitForExistence(timeout: 3) {
                // Already on login screen
            } else {
                // Navigate to login from registration
                app.buttons["Already have an account?"].tap()
            }
            
            app.textFields["Email"].tap()
            app.textFields["Email"].typeText("test@example.com")
            
            app.secureTextFields["Password"].tap()
            app.secureTextFields["Password"].typeText("password123")
            
            app.buttons["Sign In"].tap()
            
            XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5))
        }
    }
    
    private func ensureOnHomeTab() {
        if !app.tabBars.buttons["Home"].isSelected {
            app.tabBars.buttons["Home"].tap()
        }
    }
    
    private func addItemToCart() {
        ensureOnHomeTab()
        
        // Add a product to cart quickly
        if app.scrollViews.element.waitForExistence(timeout: 5) {
            let firstProduct = app.cells.matching(identifier: "ProductCell").element(boundBy: 0)
            if firstProduct.waitForExistence(timeout: 3) {
                firstProduct.tap()
                
                if app.buttons["Add to Cart"].waitForExistence(timeout: 3) {
                    app.buttons["Add to Cart"].tap()
                    
                    // Wait for addition to complete
                    _ = app.staticTexts["Added to cart"].waitForExistence(timeout: 2)
                }
            }
        }
    }
}

// MARK: - Accessibility Tests

extension UserJourneyUITests {
    
    func testAccessibilityLabels() throws {
        authenticateUser()
        
        // Test that key UI elements have accessibility labels
        ensureOnHomeTab()
        
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Cart"].exists)
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists)
        
        // Test product cells have proper accessibility
        if app.scrollViews.element.waitForExistence(timeout: 5) {
            let productCells = app.cells.matching(identifier: "ProductCell")
            if productCells.count > 0 {
                let firstProduct = productCells.element(boundBy: 0)
                XCTAssertNotEqual(firstProduct.label, "")
            }
        }
    }
    
    func testVoiceOverNavigation() throws {
        // Enable VoiceOver for testing
        app.launchEnvironment["ENABLE_VOICEOVER_TESTING"] = "true"
        
        authenticateUser()
        
        // Test VoiceOver navigation through main screens
        ensureOnHomeTab()
        
        // Navigate using accessibility
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists)
        
        let cartTab = app.tabBars.buttons["Cart"]
        cartTab.tap()
        XCTAssertTrue(cartTab.isSelected)
        
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        XCTAssertTrue(profileTab.isSelected)
    }
    
    func testToggleAndPickerStressTest() throws {
        // Stress test toggles and segmented pickers to reproduce render-thread crashes
        skipOnboardingIfNeeded()
        
        // Ensure tab bar exists and open Profile tab (works even without login for basic settings)
        guard app.tabBars.element.waitForExistence(timeout: 3) else {
            throw XCTSkip("Tab bar not present - skipping stress test")
        }
        app.tabBars.buttons["Profile"].tap()
        guard app.staticTexts["Profile"].waitForExistence(timeout: 5) else {
            throw XCTSkip("Profile screen not available")
        }
        
        let toggles = app.switches.allElementsBoundByIndex
        let segments = app.segmentedControls.allElementsBoundByIndex
        guard toggles.count + segments.count > 0 else {
            throw XCTSkip("No toggles or segmented controls found on Profile")
        }
        
        for _ in 0..<25 {
            for toggle in toggles {
                if toggle.exists {
                    toggle.tap()
                    // Small wait to exercise render paths
                    _ = toggle.waitForExistence(timeout: 0.05)
                }
            }
            for segment in segments {
                let buttons = segment.buttons
                if buttons.count > 1 {
                    if buttons.element(boundBy: 0).exists { buttons.element(boundBy: 0).tap() }
                    if buttons.element(boundBy: min(1, buttons.count - 1)).exists { buttons.element(boundBy: min(1, buttons.count - 1)).tap() }
                }
            }
        }
        
        // App should remain responsive
        XCTAssertTrue(app.tabBars.element.exists)
    }
}

// MARK: - Performance Tests

extension UserJourneyUITests {
    
    func testHomeScreenLoadPerformance() throws {
        authenticateUser()
        
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            ensureOnHomeTab()
            
            let scrollView = app.scrollViews.element
            scrollView.swipeUp()
            scrollView.swipeDown()
        }
    }
    
    func testSearchPerformance() throws {
        authenticateUser()
        ensureOnHomeTab()
        
        measure {
            let searchField = app.searchFields["Search products..."]
            searchField.tap()
            searchField.typeText("Coffee")
            app.keyboards.buttons["Search"].tap()
            
            // Wait for results
            _ = app.staticTexts["Search Results"].waitForExistence(timeout: 2)
        }
    }
}

// MARK: - Edge Case Tests

extension UserJourneyUITests {
    
    func testAppBackgroundingAndForegrounding() throws {
        authenticateUser()
        
        // Test app handles backgrounding correctly
        XCUIDevice.shared.press(.home)
        
        // Wait a moment
        sleep(1)
        
        // Bring app back to foreground
        app.activate()
        
        // Should maintain state
        XCTAssertTrue(app.tabBars.element.exists)
    }
    
    func testRotationHandling() throws {
        authenticateUser()
        
        // Test portrait orientation
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.tabBars.element.exists)
        
        // Test landscape orientation
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.tabBars.element.exists)
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
    }
}
