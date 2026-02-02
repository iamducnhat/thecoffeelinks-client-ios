import XCTest
@testable import TheCoffeeLinks

/// Integration test for actual login with real credentials
final class LoginIntegrationTests: XCTestCase {
    
    /// Test live login with real credentials
    func testRealLoginWithCredentials() async throws {
        let email = "iamducnhat@gmail.com"
        let password = "nnhhaatt"
        
        print("🔐 Testing login with: \(email)")
        
        // Step 1: Call login API
        let loginRequest = LoginRequest(email: email, password: password)
        
        do {
            let response: LoginAPIResponse = try await APIClient.shared.post("/api/auth/login", body: loginRequest)
            
            print("✅ Login API Response received")
            print("   success: \(String(describing: response.success))")
            print("   session exists: \(response.session != nil)")
            print("   token exists: \(response.token != nil)")
            print("   error: \(response.error ?? "none")")
            
            // Get access token
            let token = response.session?.accessToken ?? response.token
            XCTAssertNotNil(token, "Should receive access token")
            print("   access_token: \(token?.prefix(50) ?? "nil")...")
            
            guard let accessToken = token else {
                XCTFail("No access token received")
                return
            }
            
            // Step 2: Set token and fetch profile
            await APIClient.shared.setAuthToken(accessToken)
            
            print("\n📋 Fetching profile...")
            let profileResponse: ProfileAPIResponse = try await APIClient.shared.get("/api/user/profile")
            
            print("✅ Profile API Response received")
            print("   success: \(String(describing: profileResponse.success))")
            print("   user exists: \(profileResponse.user != nil)")
            print("   error: \(profileResponse.error ?? "none")")
            
            if let user = profileResponse.user {
                print("   user.id: \(user.id)")
                print("   user.email: \(user.email ?? "nil")")
                print("   user.name: \(user.name ?? "nil")")
                print("   user.points: \(user.points ?? 0)")
            }
            
            XCTAssertNotNil(profileResponse.user, "Should receive user profile")
            XCTAssertEqual(profileResponse.user?.email, email, "Email should match")
            
            print("\n🎉 LOGIN TEST PASSED!")
            
        } catch let error as APIClient.APIError {
            print("❌ API Error: \(error.localizedDescription)")
            XCTFail("API Error: \(error.localizedDescription)")
        } catch let decodingError as DecodingError {
            print("❌ Decoding Error: \(decodingError)")
            
            // Print detailed decoding error info
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Key not found: '\(key.stringValue)'")
                print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Description: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("   Type mismatch: expected \(type)")
                print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Description: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value not found: expected \(type)")
                print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Description: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("   Data corrupted")
                print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Description: \(context.debugDescription)")
            @unknown default:
                print("   Unknown decoding error")
            }
            
            XCTFail("Decoding Error: \(decodingError)")
        } catch {
            print("❌ Unknown Error: \(error)")
            XCTFail("Unknown Error: \(error)")
        }
    }
    
    /// Test raw JSON decoding to see exact response
    func testRawLoginResponse() async throws {
        let email = "iamducnhat@gmail.com"
        let password = "nnhhaatt"
        
        print("🔍 Testing raw login response...")
        
        let url = URL(string: "https://server-nu-three-90.vercel.app/api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Invalid response")
            return
        }
        
        print("   HTTP Status: \(httpResponse.statusCode)")
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("   Response (first 500 chars):")
            print("   \(String(jsonString.prefix(500)))")
        }
        
        // Try to decode with our model
        let decoder = JSONDecoder()
        do {
            let loginResponse = try decoder.decode(LoginAPIResponse.self, from: data)
            print("\n✅ Successfully decoded LoginAPIResponse")
            print("   success: \(String(describing: loginResponse.success))")
            print("   has session: \(loginResponse.session != nil)")
        } catch {
            print("\n❌ Failed to decode LoginAPIResponse: \(error)")
        }
    }
}
