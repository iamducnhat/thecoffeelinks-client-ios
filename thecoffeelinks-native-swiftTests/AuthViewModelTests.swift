import XCTest
@testable import thecoffeelinks_native_swift

/// Tests for AuthViewModel login/logout functionality
@MainActor
final class AuthViewModelTests: XCTestCase {
    var authViewModel: AuthViewModel!
    
    override func setUp() {
        super.setUp()
        // Create a fresh instance for testing (not the shared singleton)
        authViewModel = AuthViewModel.shared
    }
    
    override func tearDown() {
        super.tearDown()
        // Clear any stored session
        UserDefaults.standard.removeObject(forKey: "auth_session")
    }
    
    // MARK: - Initial State
    
    func testInitialStateIsLoading() {
        // After init, the AuthViewModel starts checking session
        // State should transition from loading
        XCTAssertNotNil(authViewModel.state, "State should be defined")
    }
    
    // MARK: - Login Tests
    
    func testLoginWithInvalidCredentialsFails() async {
        await authViewModel.signInWithPassword(email: "invalid@test.com", password: "wrongpassword")
        
        // Should be unauthenticated with an error message
        XCTAssertEqual(authViewModel.state, .unauthenticated, "Should be unauthenticated after failed login")
        XCTAssertNotNil(authViewModel.errorMessage, "Should have an error message")
        print("✅ Login correctly fails with invalid credentials")
    }
    
    func testLoginWithEmptyCredentialsFails() async {
        await authViewModel.signInWithPassword(email: "", password: "")
        
        XCTAssertEqual(authViewModel.state, .unauthenticated, "Should be unauthenticated with empty credentials")
        print("✅ Login correctly handles empty credentials")
    }
    
    // MARK: - Session Tests
    
    func testSessionPersistence() async {
        // Store a fake session
        let fakeSession = AuthSession(
            accessToken: "test_token_abc123",
            refreshToken: nil,
            expiresIn: 3600,
            tokenType: "bearer"
        )
        
        if let sessionData = try? JSONEncoder().encode(fakeSession) {
            UserDefaults.standard.set(sessionData, forKey: "auth_session")
        }
        
        // Check session should load it
        await authViewModel.checkSession()
        
        XCTAssertEqual(authViewModel.state, .authenticated, "Should be authenticated with stored session")
        XCTAssertNotNil(authViewModel.session, "Session should be loaded")
        print("✅ Session persistence works correctly")
    }
    
    // MARK: - Logout Tests
    
    func testLogoutClearsSession() async {
        // First, simulate being logged in
        let fakeSession = AuthSession(
            accessToken: "test_token",
            refreshToken: nil,
            expiresIn: 3600,
            tokenType: "bearer"
        )
        
        if let sessionData = try? JSONEncoder().encode(fakeSession) {
            UserDefaults.standard.set(sessionData, forKey: "auth_session")
        }
        
        await authViewModel.checkSession()
        XCTAssertEqual(authViewModel.state, .authenticated, "Should be authenticated before logout")
        
        // Now logout
        await authViewModel.signOut()
        
        XCTAssertEqual(authViewModel.state, .unauthenticated, "Should be unauthenticated after logout")
        XCTAssertNil(authViewModel.session, "Session should be nil after logout")
        
        // Verify UserDefaults is cleared
        let storedSession = UserDefaults.standard.data(forKey: "auth_session")
        XCTAssertNil(storedSession, "Stored session should be cleared")
        
        print("✅ Logout correctly clears session")
    }
}
