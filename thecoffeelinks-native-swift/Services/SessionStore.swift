import Foundation
import Security

// MARK: - Session Structure

struct UserSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let userId: String
    
    // Check if token will expire within a threshold (e.g., 5 minutes)
    func willExpire(within seconds: TimeInterval = 300) -> Bool {
        return Date().addingTimeInterval(seconds) >= expiresAt
    }
}

// MARK: - Session Store (Keychain)

class SessionStore {
    private let service = "com.thecoffeelinks.auth"
    private let account = "user_session"
    
    func save(_ session: UserSession) {
        do {
            let data = try JSONEncoder().encode(session)
            
            // Define query for item search
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            
            // attributes to update
            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            // Try to update existing item
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            
            // If item doesn't exist, add it
            if status == errSecItemNotFound {
                var newItem = query
                newItem[kSecValueData as String] = data
                SecItemAdd(newItem as CFDictionary, nil)
            }
        } catch {
            print("Failed to save session to Keychain: \(error)")
        }
    }
    
    func load() -> UserSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return try? JSONDecoder().decode(UserSession.self, from: data)
    }
    
    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
