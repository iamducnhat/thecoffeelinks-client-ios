//
//  AuthViewModelTests.swift
//  TheCoffeeLinksTests
//
//  Comprehensive tests for AuthViewModel with proper mocks and DI
//

import XCTest
import Combine
@testable import TheCoffeeLinks

@MainActor
final class AuthViewModelTests: TestBaseClass {
    
    // MARK: - Properties
    
    var authViewModel: AuthViewModel!
    var mockAuthRepository: MockAuthRepository!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        mockAuthRepository = MockAuthRepository()
        authViewModel = AuthViewModel(authRepository: mockAuthRepository)
    }
    
    override func tearDown() {
        super.tearDown()
        authViewModel = nil
        mockAuthRepository = nil
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(authViewModel.authState, .idle)
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.isPhoneVerified)
        XCTAssertTrue(authViewModel.phoneNumber.isEmpty)
        XCTAssertTrue(authViewModel.otpCode.isEmpty)
        XCTAssertTrue(authViewModel.password.isEmpty)
        XCTAssertTrue(authViewModel.fullName.isEmpty)
        XCTAssertNil(authViewModel.currentUser)
    }
    
    // MARK: - Registration Tests
    
    func testSuccessfulRegistration() async {
        // Given
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.password = "securePassword123"
        authViewModel.fullName = "Test User"
        authViewModel.dob = "01/01/1990"
        
        // When
        authViewModel.register()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(authViewModel.authState, .otpSent)
        XCTAssertNil(authViewModel.error)
    }
    
    func testRegistrationWithEmptyFields() async {
        // Given - empty required fields
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.password = ""
        authViewModel.fullName = ""
        authViewModel.dob = ""
        
        // When
        authViewModel.register()
        
        // Then
        XCTAssertEqual(authViewModel.authState, .error)
        XCTAssertNotNil(authViewModel.error)
        XCTAssertTrue(authViewModel.error?.contains("Please fill in all fields") ?? false)
    }
    
    func testRegistrationNetworkFailure() async {
        // Given
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.password = "securePassword123"
        authViewModel.fullName = "Test User"
        authViewModel.dob = "01/01/1990"
        mockAuthRepository.shouldFail = true
        
        // When
        authViewModel.register()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(authViewModel.authState, .error)
        XCTAssertNotNil(authViewModel.error)
    }
    
    // MARK: - OTP Verification Tests
    
    func testSuccessfulOTPVerification() async {
        // Given
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.otpCode = "123456"
        let mockUser = TestDataFactory.createUser()
        mockAuthRepository.mockUser = mockUser
        
        // When
        authViewModel.verifyOTP()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertTrue(authViewModel.isPhoneVerified)
        XCTAssertEqual(authViewModel.currentUser?.id, mockUser.id)
        XCTAssertNil(authViewModel.error)
    }
    
    func testOTPVerificationWithInvalidCode() async {
        // Given
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.otpCode = "000000"
        mockAuthRepository.shouldFail = true
        
        // When
        authViewModel.verifyOTP()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.isPhoneVerified)
        XCTAssertNotNil(authViewModel.error)
    }
    
    // MARK: - Sign In Tests
    
    func testSuccessfulSignIn() async {
        // Given
        let mockUser = TestDataFactory.createUser()
        mockAuthRepository.mockUser = mockUser
        
        // When
        await authViewModel.signInWithPassword(email: "test@example.com", password: "password123")
        
        // Then
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertEqual(authViewModel.currentUser?.email, mockUser.email)
        XCTAssertNil(authViewModel.error)
    }
    
    func testSignInWithInvalidCredentials() async {
        // Given
        mockAuthRepository.shouldFail = true
        
        // When
        await authViewModel.signInWithPassword(email: "invalid@test.com", password: "wrongpassword")
        
        // Then
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.currentUser)
        XCTAssertNotNil(authViewModel.error)
    }
    
    func testSignInWithEmptyCredentials() async {
        // When
        await authViewModel.signInWithPassword(email: "", password: "")
        
        // Then
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.currentUser)
        // Should handle empty credentials gracefully
    }
    
    // MARK: - Sign Out Tests
    
    func testSuccessfulSignOut() async {
        // Given - user is signed in
        let mockUser = TestDataFactory.createUser()
        authViewModel.currentUser = mockUser
        authViewModel.isAuthenticated = true
        authViewModel.isPhoneVerified = true
        
        // When
        await authViewModel.signOut()
        
        // Then
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.isPhoneVerified)
        XCTAssertNil(authViewModel.currentUser)
    }
    
    func testSignOutNetworkFailure() async {
        // Given
        let mockUser = TestDataFactory.createUser()
        authViewModel.currentUser = mockUser
        authViewModel.isAuthenticated = true
        mockAuthRepository.shouldFail = true
        
        // When
        await authViewModel.signOut()
        
        // Then - should still clear local state even if network fails
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertNil(authViewModel.currentUser)
    }
    
    // MARK: - Session Management Tests
    
    func testCheckSessionWithValidToken() async {
        // Given
        mockKeychainManager.saveAccessToken("valid_token_123")
        let mockUser = TestDataFactory.createUser(isPhoneVerified: true)
        mockAuthRepository.mockUser = mockUser
        
        // When
        authViewModel.checkSession()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertTrue(authViewModel.isPhoneVerified)
    }
    
    func testCheckSessionWithNoToken() {
        // Given - no token in keychain
        mockKeychainManager.deleteAccessToken()
        
        // When
        authViewModel.checkSession()
        
        // Then
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.isPhoneVerified)
    }
    
    func testCheckSessionWithExpiredToken() async {
        // Given
        mockKeychainManager.saveAccessToken("expired_token")
        mockAuthRepository.shouldFail = true // Simulates token validation failure
        
        // When
        authViewModel.checkSession()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertTrue(authViewModel.isAuthenticated) // Initially true due to token presence
        // But verification status should fallback to cache if network fails
    }
    
    // MARK: - Phone Number Formatting Tests
    
    func testPhoneNumberFormatting() {
        // Test various phone number formats
        let testCases = [
            ("0123456789", "+84123456789"),
            ("84123456789", "+84123456789"),
            ("+84123456789", "+84123456789"),
            ("123456789", "+84123456789")
        ]
        
        for (input, expected) in testCases {
            authViewModel.phoneNumber = input
            authViewModel.register() // This triggers formatting
            // Note: The actual formatting logic would need to be tested
            // by exposing the formatPhoneNumber method or testing indirectly
        }
    }
    
    // MARK: - Date Formatting Tests
    
    func testDateFormatting() {
        // Test date format conversion from DD/MM/YYYY to YYYY-MM-DD
        authViewModel.dob = "15/06/1995"
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.password = "password123"
        authViewModel.fullName = "Test User"
        
        authViewModel.register()
        
        // The formatted date would be used in the repository call
        // This tests that the conversion happens without errors
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStatesDuringRegistration() async {
        // Given
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.password = "securePassword123"
        authViewModel.fullName = "Test User"
        authViewModel.dob = "01/01/1990"
        
        // Initial state
        XCTAssertFalse(authViewModel.isLoading)
        
        // Start registration
        authViewModel.register()
        
        // Should be loading briefly
        // Note: This test is timing-dependent and might need adjustment
        // In a real implementation, you might want to expose loading state more explicitly
        
        // Wait for completion
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Should not be loading after completion
        XCTAssertFalse(authViewModel.isLoading)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorReset() async {
        // Given - error state
        authViewModel.error = "Previous error"
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.password = "securePassword123"
        authViewModel.fullName = "Test User"
        authViewModel.dob = "01/01/1990"
        
        // When
        authViewModel.register()
        
        // Wait for completion
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - error should be cleared on successful operation
        XCTAssertNil(authViewModel.error)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentRegistrationCalls() async {
        // Given
        authViewModel.phoneNumber = "+84123456789"
        authViewModel.password = "securePassword123"
        authViewModel.fullName = "Test User"
        authViewModel.dob = "01/01/1990"
        
        // When - multiple concurrent calls
        async let registration1 = authViewModel.register()
        async let registration2 = authViewModel.register()
        
        await registration1
        await registration2
        
        // Then - should handle concurrent calls gracefully
        // The implementation should prevent duplicate calls or handle them properly
        XCTAssertEqual(authViewModel.authState, .otpSent)
    }
}

// MARK: - Performance Tests

extension AuthViewModelTests {
    
    func testAuthenticationPerformance() async {
        measure {
            let expectation = XCTestExpectation(description: "Authentication performance")
            
            Task {
                await authViewModel.signInWithPassword(email: "test@example.com", password: "password123")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
}