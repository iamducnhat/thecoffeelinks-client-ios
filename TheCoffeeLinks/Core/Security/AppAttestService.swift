//
//  AppAttestService.swift
//  thecoffeelinks-client-ios
//
//  Apple App Attest Integration
//  Protects sensitive operations with device attestation
//

import Foundation
import DeviceCheck
import CryptoKit
import Combine
import os.log
import UIKit

// MARK: - App Attest Errors

enum AppAttestError: Error, LocalizedError {
    case unavailable
    case attestationFailed(Error)
    case assertionFailed(Error)
    case keyNotFound
    case invalidResponse
    case notSupported

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "App Attest is not available on this device"
        case .attestationFailed(let error):
            return "Attestation failed: \(error.localizedDescription)"
        case .assertionFailed(let error):
            return "Assertion failed: \(error.localizedDescription)"
        case .keyNotFound:
            return "App Attest key not found"
        case .invalidResponse:
            return "Invalid attestation response"
        case .notSupported:
            return "App Attest not supported"
        }
    }
}

// MARK: - App Attest Models

struct AppAttestKey: Codable, Sendable {
    let keyId: String
    let challenge: String
    let attestation: String
    let createdAt: Date
}

struct AppAttestAssertion: Codable, Sendable {
    let keyId: String
    let assertion: String
    let challenge: String
    let timestamp: Int64
}

// MARK: - App Attest Service

@MainActor
final class AppAttestService: ObservableObject {
    static let shared: AppAttestService = {
        let instance = AppAttestService()
        // Initialize availability state
        DispatchQueue.main.async {
            instance.checkAvailability()
        }
        return instance
    }()
    
    private var attestService: DCAppAttestService?
    private var currentKey: AppAttestKey?
    private var currentUserId: String? // Track which user this key belongs to
    
    // Deduplicate concurrent generateKey() calls — prevents race where
    // 3 callers each create a separate Apple key and only 1 gets registered.
    private var keyGenerationTask: Task<AppAttestKey, Error>?
    
    // Registration retry state for exponential backoff
    private var registrationRetryCount: Int = 0
    private var lastRegistrationAttempt: Date?
    
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isRegistered: Bool = false {
        didSet {
            if let userId = currentUserId {
                UserDefaults.standard.set(isRegistered, forKey: "appAttestKeyRegistered_\(userId)")
            }
            if isRegistered {
                // Reset retry count on successful registration
                registrationRetryCount = 0
                lastRegistrationAttempt = nil
            }
        }
    }
    
    nonisolated init() {
        // Empty initializer for ObservableObject
    }
    
    // MARK: - Availability Check
    
    private func checkAvailability() {
        if #available(iOS 14.0, *) {
            attestService = DCAppAttestService.shared
            isAvailable = true
            
            // Note: Key will be loaded when user authenticates (loadKeyForUser)
            debugLog("[AppAttestService] Service available, waiting for user authentication to load key")
        } else {
            isAvailable = false
        }
    }
    
    // MARK: - Key Registration
    
    func generateKey() async throws -> AppAttestKey {
        // Return existing key if already generated
        if let existingKey = currentKey {
            return existingKey
        }
        
        // Deduplicate concurrent calls: if another task is already generating,
        // await its result instead of creating a second Apple key.
        if let existingTask = keyGenerationTask {
            return try await existingTask.value
        }
        
        let task = Task<AppAttestKey, Error> { [weak self] in
            guard let self else { throw AppAttestError.unavailable }
            return try await self._generateKeyImpl()
        }
        keyGenerationTask = task
        
        do {
            let key = try await task.value
            keyGenerationTask = nil
            return key
        } catch {
            keyGenerationTask = nil
            throw error
        }
    }
    
    /// Internal implementation — only called once even under concurrent pressure.
    private func _generateKeyImpl() async throws -> AppAttestKey {
        guard let service = attestService else {
            throw AppAttestError.unavailable
        }

        // Try to fetch a server-provided challenge for key attestation. Fallback to local if unavailable.
        var challenge = generateChallenge()
        do {
            let network = DependencyContainer.shared.networkService
            struct ChallengeResponse: Decodable {
                let success: Bool
                let challenge: String
                let timestamp: Int64
            }
            let resp: ChallengeResponse = try await network.request(
                "/api/auth/app-attest/challenge",
                method: "GET"
            )
            if resp.success {
                challenge = resp.challenge
            }
        } catch {
            debugLog("[AppAttestService] Failed to fetch server challenge: \(error.localizedDescription). Using local challenge.")
        }

        // 1. Get Key ID
        let keyId: String = try await withCheckedThrowingContinuation { continuation in
            service.generateKey { keyId, error in
                if let error = error {
                    let nsErr = error as NSError
                    debugLog("[AppAttestService] generateKey error: domain=\(nsErr.domain) code=\(nsErr.code) userInfo=\(nsErr.userInfo)")
                    if nsErr.domain == "com.apple.devicecheck.error" && nsErr.code == 1 {
                        debugLog("[AppAttestService] App Attest generation failed (code 1). Common causes: running on Simulator, missing App Attest entitlement in the provisioning profile, incorrect bundle ID, or Apple services unreachable.")
                    }
                    continuation.resume(throwing: AppAttestError.attestationFailed(error))
                    return
                }
                guard let keyId = keyId else {
                    continuation.resume(throwing: AppAttestError.invalidResponse)
                    return
                }
                continuation.resume(returning: keyId)
            }
        }

        // 2. Attest Key using the challenge
        let attestation = try await attestKey(keyId: keyId, challenge: challenge)

        let key = AppAttestKey(
            keyId: keyId,
            challenge: challenge,
            attestation: attestation,
            createdAt: Date()
        )

        // 3. Save to keychain (MainActor isolated)
        self.currentKey = key
        
        // Save to keychain with user ID
        if let userId = self.currentUserId {
            self.saveKeyToKeychain(key, forUser: userId)
        } else {
            debugLog("[AppAttestService] ⚠️ No currentUserId set, key not persisted to keychain")
        }
        
        // NOTE: We do NOT mark the key as server-registered here. Registration requires an authenticated request.
        self.isRegistered = false

        debugLog("[AppAttestService] Generated local key (\(keyId)). Server registration is pending.")

        return key
    }
    
    // MARK: - Attestation
    
    private func attestKey(keyId: String, challenge: String) async throws -> String {
        guard let service = attestService else {
            throw AppAttestError.unavailable
        }
        
        guard let challengeData = challenge.data(using: .utf8) else {
            throw AppAttestError.invalidResponse
        }
        
        let clientDataHash = Data(CryptoKit.SHA256.hash(data: challengeData))
        
        return try await withCheckedThrowingContinuation { continuation in
            service.attestKey(keyId, clientDataHash: clientDataHash) { attestation, error in
                if let error = error {
                    let nsErr = error as NSError
                    debugLog("[AppAttestService] attestKey error: domain=\(nsErr.domain) code=\(nsErr.code) userInfo=\(nsErr.userInfo)")
                    if nsErr.domain == "com.apple.devicecheck.error" && nsErr.code == 1 {
                        debugLog("[AppAttestService] App Attest attestation failed (code 1). Verify entitlements/provisioning and that this is running on a physical device.")
                    }
                    continuation.resume(throwing: AppAttestError.attestationFailed(error))
                    return
                }
                guard let attestation = attestation else {
                    continuation.resume(throwing: AppAttestError.invalidResponse)
                    return
                }
                continuation.resume(returning: attestation.base64EncodedString())
            }
        }
    }
    
    // MARK: - Assertion Generation
    
    func generateAssertion(for challenge: String) async throws -> AppAttestAssertion {
        guard let key = currentKey, let service = attestService else {
            throw AppAttestError.keyNotFound
        }
        
        
        return try await withCheckedThrowingContinuation { continuation in
            guard let challengeData = challenge.data(using: .utf8) else {
                continuation.resume(throwing: AppAttestError.invalidResponse)
                return
            }
            
            service.generateAssertion(
                key.keyId,
                clientDataHash: Data(CryptoKit.SHA256.hash(data: challengeData))
            ) { assertion, error in
                if let error = error {
                    let nsErr = error as NSError
                    debugLog("[AppAttestService] generateAssertion error: domain=\(nsErr.domain) code=\(nsErr.code) userInfo=\(nsErr.userInfo)")
                    continuation.resume(throwing: AppAttestError.assertionFailed(error))
                    return
                }
                
                guard let assertion = assertion else {
                    continuation.resume(throwing: AppAttestError.invalidResponse)
                    return
                }
                
                let base64String = assertion.base64EncodedString()
                let timestamp = Int64(Date().timeIntervalSince1970)
                
                let assertionObj = AppAttestAssertion(
                    keyId: key.keyId,
                    assertion: base64String,
                    challenge: challenge,
                    timestamp: timestamp
                )
                
                continuation.resume(returning: assertionObj)
            }
        }
    }
    
    // MARK: - Challenge Generation
    
    func generateChallenge() -> String {
        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return data.base64EncodedString(options: .lineLength64Characters)
    }
    
    // MARK: - Key Persistence
    
    private func saveKeyToKeychain(_ key: AppAttestKey, forUser userId: String) {
        let keychain = DependencyContainer.shared.keychainManager
        if let encoded = try? JSONEncoder().encode(key) {
            // Store with user-specific key: appAttestKey_{userId}
            keychain.set("appAttestKey_\(userId)", value: encoded.base64EncodedString())
            debugLog("[AppAttestService] Saved key to keychain for user: \(userId)")
        }
    }
    
    private func loadKeyFromKeychain(forUser userId: String) -> AppAttestKey? {
        let keychain = DependencyContainer.shared.keychainManager
        guard let encodedString = keychain.get("appAttestKey_\(userId)"),
              let data = Data(base64Encoded: encodedString),
              let key = try? JSONDecoder().decode(AppAttestKey.self, from: data) else {
            return nil
        }
        return key
    }
    
    /// Load the App Attest key for a specific user. Call this after authentication.
    func loadKeyForUser(_ userId: String) {
        currentUserId = userId
        if let key = loadKeyFromKeychain(forUser: userId) {
            currentKey = key
            isRegistered = UserDefaults.standard.bool(forKey: "appAttestKeyRegistered_\(userId)")
            debugLog("[AppAttestService] Loaded key for user \(userId): \(key.keyId), isRegistered=\(isRegistered)")
        } else {
            currentKey = nil
            isRegistered = false
            debugLog("[AppAttestService] No key found for user \(userId), will generate new key")
        }
    }
    
    private func loadKeyFromKeychain() -> AppAttestKey? {
        // Legacy method - should not be used anymore
        let keychain = DependencyContainer.shared.keychainManager
        guard let encodedString = keychain.get("appAttestKey"),
              let data = Data(base64Encoded: encodedString),
              let key = try? JSONDecoder().decode(AppAttestKey.self, from: data) else {
            return nil
        }
        return key
    }
    
    func clearKey() {
        guard let userId = currentUserId else {
            debugLog("[AppAttestService] clearKey called but no current user")
            return
        }
        let keychain = DependencyContainer.shared.keychainManager
        keychain.remove("appAttestKey_\(userId)")
        UserDefaults.standard.removeObject(forKey: "appAttestKeyRegistered_\(userId)")
        currentKey = nil
        isRegistered = false
        debugLog("[AppAttestService] Cleared key for user: \(userId)")
    }
    
    /// Clear key for a specific user (e.g., on logout)
    func clearKeyForUser(_ userId: String) {
        let keychain = DependencyContainer.shared.keychainManager
        keychain.remove("appAttestKey_\(userId)")
        UserDefaults.standard.removeObject(forKey: "appAttestKeyRegistered_\(userId)")
        if currentUserId == userId {
            currentKey = nil
            isRegistered = false
        }
        debugLog("[AppAttestService] Cleared key for user: \(userId)")
    }
    
    // MARK: - Registration State
    
    // Public helper to check for a local key
    var hasLocalKey: Bool {
        return currentKey != nil
    }

    func ensureRegistered() async throws {
        if !isAvailable {
            debugLog("[AppAttestService] App Attest not available on this device")
            throw AppAttestError.unavailable
        }

        // Create a local key if missing (does NOT register with server)
        if currentKey == nil {
            do {
                _ = try await generateKey()
            } catch {
                debugLog("[AppAttestService] generateKey failed: \(error.localizedDescription)")
                throw error
            }
        }
    }

    // Register the current local key with the server. Requires an authenticated session.
    func registerKeyWithServer() async throws -> Bool {
        // Idempotency: Skip if already registered
        guard !isRegistered else {
            debugLog("[AppAttestService] Already registered with server, skipping")
            return true
        }
        
        // Exponential backoff: Check if we should wait before retrying
        if let lastAttempt = lastRegistrationAttempt {
            let backoffSeconds = min(pow(2.0, Double(registrationRetryCount)), 300.0) // Max 5 minutes
            let nextAttemptTime = lastAttempt.addingTimeInterval(backoffSeconds)
            if Date() < nextAttemptTime {
                let waitTime = nextAttemptTime.timeIntervalSince(Date())
                debugLog("[AppAttestService] Backoff active, retry in \(Int(waitTime))s (attempt #\(registrationRetryCount))")
                throw AppAttestError.invalidResponse
            }
        }
        
        lastRegistrationAttempt = Date()
        
        // Ensure we have a local key (try to create one if missing)
        if currentKey == nil {
            do {
                _ = try await generateKey()
                debugLog("[AppAttestService] Created local key during register: \(currentKey?.keyId ?? "<nil>")")
            } catch {
                debugLog("[AppAttestService] Failed to create local key during register: \(error.localizedDescription)")
                registrationRetryCount += 1
                throw AppAttestError.keyNotFound
            }
        }

        guard let key = currentKey else {
            registrationRetryCount += 1
            throw AppAttestError.keyNotFound
        }

        // Build request
        struct RegisterRequest: Encodable {
            let keyId: String
            let attestKey: String
            let challenge: String
            let deviceId: String
        }

        struct RegisterResponse: Decodable {
            let success: Bool
            let keyId: String?
        }

        let deviceId = (UIDevice.current.identifierForVendor?.uuidString) ?? "unknown"

        let network = DependencyContainer.shared.networkService

        do {
            let resp: RegisterResponse = try await network.request(
                "/api/auth/app-attest/register",
                method: "POST",
                body: RegisterRequest(keyId: key.keyId, attestKey: key.attestation, challenge: key.challenge, deviceId: deviceId)
            )

            if resp.success {
                self.isRegistered = true
                debugLog("[AppAttestService] Key (\(key.keyId)) registered with server")
                return true
            }

            debugLog("[AppAttestService] Server registration returned success=false")
            registrationRetryCount += 1
            return false
        } catch let error as NetworkError {
            debugLog("[AppAttestService] registerKeyWithServer failed: \(error.localizedDescription)")
            registrationRetryCount += 1
            throw error
        } catch {
            debugLog("[AppAttestService] registerKeyWithServer failed: \(error.localizedDescription)")
            registrationRetryCount += 1
            throw error
        }
    }
}

// MARK: - Helpers

// Using CryptoKit.SHA256 directly for hashing
