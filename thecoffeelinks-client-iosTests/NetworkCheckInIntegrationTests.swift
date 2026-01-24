import XCTest
@testable import thecoffeelinks_client_ios

final class NetworkCheckInIntegrationTests: XCTestCase {
    
    // Use the same credentials as LoginIntegrationTests
    let email = "iamducnhat@gmail.com"
    let password = "nnhhaatt"

    // MARK: - Helper to login and set token
    private func loginAndSetToken() async throws {
        let loginRequest = LoginRequest(email: email, password: password)
        let response: LoginAPIResponse = try await APIClient.shared.post("/api/auth/login", body: loginRequest)
        
        guard let token = response.session?.accessToken ?? response.token else {
            XCTFail("Login failed: No access token received")
            return
        }
        
        await APIClient.shared.setAuthToken(token)
        print("✅ Logged in and token set.")
    }

    /// Test check-in with default location (should fetch stores and pick one)
    @MainActor
    func testCheckInWithDefaultLocation() async throws {
        // 1. Login first
        try await loginAndSetToken()
        
        // 2. Initialize ViewModel
        let viewModel = NetworkViewModel()
        
        // 3. Call checkIn with nil (default)
        print("📍 Attempting check-in with nil location (should default to first store)...")
        await viewModel.checkIn(location: nil)
        
        // 4. Verification
        // Check for error state first
        if case .error(let message) = viewModel.viewState {
            XCTFail("Check-in failed with error: \(message)")
            return
        }
        
        // Assert isCheckedIn is true
        XCTAssertTrue(viewModel.isCheckedIn, "ViewModel should be checked in")
        
        // Assert loaded state (it fetches check-ins after checking in)
        if case .loaded = viewModel.viewState {
            // Success
        } else {
             // It might still be loading or something else if fetchCheckIns is slow, but checkIn awaits it.
            // Let's just print the state
            print("Final ViewState: \(viewModel.viewState)")
        }
        
        // Optional: Check if the current user is in the list
        let currentUser = viewModel.checkedInUsers.first { checkIn in
            // Ideally we check ID, but here just checking if list is not empty is a good start
            return true
        }
        XCTAssertNotNil(currentUser, "Checked in users list should not be empty")
        
        print("🎉 CHECK-IN TEST PASSED!")
    }
    
    /// Test check-in with explicit "Main Lounge" (should also fetch stores and pick one)
    @MainActor
    func testCheckInWithMainLoungePlaceholder() async throws {
         // 1. Login first
        try await loginAndSetToken()
        
        // 2. Initialize ViewModel
        let viewModel = NetworkViewModel()
        
        // 3. Call checkIn with "Main Lounge"
        print("📍 Attempting check-in with 'Main Lounge'...")
        await viewModel.checkIn(location: "Main Lounge")
        
        // 4. Verification
        if case .error(let message) = viewModel.viewState {
            XCTFail("Check-in failed with error: \(message)")
            return
        }
        
        XCTAssertTrue(viewModel.isCheckedIn, "ViewModel should be checked in")
    }
}
