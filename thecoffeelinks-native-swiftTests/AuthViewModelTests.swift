import XCTest
@testable import thecoffeelinks_native_swift

/// Tests for AuthViewModel login/logout functionality
@MainActor
final class AuthViewModelTests: XCTestCase {
    var authViewModel: AuthViewModel!
    
    override func setUp() {
        super.setUp()
        authViewModel = AuthViewModel.shared
    }
    
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "auth_session")
    }
    
    // MARK: - Initial State
    
    func testInitialStateIsNotNil() {
        XCTAssertNotNil(authViewModel.state, "State should be defined")
    }
    
    // MARK: - Login Tests
    
    func testLoginWithInvalidCredentialsFails() async {
        await authViewModel.signInWithPassword(email: "invalid@test.com", password: "wrongpassword")
        
        XCTAssertEqual(authViewModel.state, .unauthenticated, "Should be unauthenticated after failed login")
        print("✅ Login correctly fails with invalid credentials")
    }
    
    func testLoginWithEmptyCredentialsFails() async {
        await authViewModel.signInWithPassword(email: "", password: "")
        
        XCTAssertEqual(authViewModel.state, .unauthenticated, "Should be unauthenticated with empty credentials")
        print("✅ Login correctly handles empty credentials")
    }
    
    // MARK: - Session Tests
    
    func testSessionPersistence() async {
        // Store a fake session using StoredSession
        let fakeSession = StoredSession(
            accessToken: "test_token_abc123",
            userId: "test-user-id",
            email: "test@example.com"
        )
        
        if let sessionData = try? JSONEncoder().encode(fakeSession) {
            UserDefaults.standard.set(sessionData, forKey: "auth_session")
        }
        
        // Check session should load it
        await authViewModel.checkSession()
        
        // Note: This will fail to validate because the token is fake
        // But the token should be loaded
        XCTAssertEqual(authViewModel.accessToken, "test_token_abc123", "Token should be loaded from stored session")
        print("✅ Session persistence loads stored token")
    }
    
    // MARK: - Logout Tests
    
    func testLogoutClearsSession() async {
        // First, simulate being logged in
        let fakeSession = StoredSession(
            accessToken: "test_token",
            userId: "test-user",
            email: "test@example.com"
        )
        
        if let sessionData = try? JSONEncoder().encode(fakeSession) {
            UserDefaults.standard.set(sessionData, forKey: "auth_session")
        }
        
        // Now logout
        await authViewModel.signOut()
        
        XCTAssertEqual(authViewModel.state, .unauthenticated, "Should be unauthenticated after logout")
        XCTAssertNil(authViewModel.accessToken, "Token should be nil after logout")
        
        // Verify UserDefaults is cleared
        let storedSession = UserDefaults.standard.data(forKey: "auth_session")
        XCTAssertNil(storedSession, "Stored session should be cleared")
        
        print("✅ Logout correctly clears session")
    }
}
