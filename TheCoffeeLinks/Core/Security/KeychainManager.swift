import Foundation
import Security

final class KeychainManager: SecureStorage, @unchecked Sendable {
    
    private let service = "com.thecoffeelinks.app"
    
    // MARK: - Legacy / Specific
    func saveAccessToken(_ token: String) {
        set("accessToken", value: token)
    }
    
    func getAccessToken() -> String? {
        get("accessToken")
    }
    
    func deleteAccessToken() {
        remove("accessToken")
    }
    
    // MARK: - Refresh Token
    func saveRefreshToken(_ token: String) {
        set("refreshToken", value: token)
    }
    
    func getRefreshToken() -> String? {
        get("refreshToken")
    }
    
    func deleteRefreshToken() {
        remove("refreshToken")
    }
    
    // MARK: - Phone Number
    func savePhoneNumber(_ phoneNumber: String) {
        set("phoneNumber", value: phoneNumber)
    }
    
    func getPhoneNumber() -> String? {
        get("phoneNumber")
    }
    
    func deletePhoneNumber() {
        remove("phoneNumber")
    }
    
    // MARK: - SecureStorage Protocol
    
    func set(_ key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item if any
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving to keychain: \(status)")
        }
    }
    
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func remove(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
