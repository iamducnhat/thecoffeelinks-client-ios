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
    
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isRegistered: Bool = false
    
    nonisolated init() {
        // Empty initializer for ObservableObject
    }
    
    // MARK: - Availability Check
    
    private func checkAvailability() {
        if #available(iOS 14.0, *) {
            attestService = DCAppAttestService.shared
            isAvailable = true
            
            // Check for existing key
            if let key = loadKeyFromKeychain() {
                currentKey = key
                isRegistered = true
            }
        } else {
            isAvailable = false
        }
    }
    
    // MARK: - Key Registration
    
    func generateKey() async throws -> AppAttestKey {
        guard let service = attestService else {
            throw AppAttestError.unavailable
        }
        
        // Generate a challenge hash
        let challenge = generateChallenge()
        
        // 1. Get Key ID
        let keyId: String = try await withCheckedThrowingContinuation { continuation in
            service.generateKey { keyId, error in
                if let error = error {
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
        
        // 2. Attest Key
        let attestation = try await attestKey(keyId: keyId, challenge: challenge)
        
        let key = AppAttestKey(
            keyId: keyId,
            challenge: challenge,
            attestation: attestation,
            createdAt: Date()
        )
        
        // 3. Save to keychain (MainActor isolated)
        self.saveKeyToKeychain(key)
        self.currentKey = key
        self.isRegistered = true
        
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
    
    private func saveKeyToKeychain(_ key: AppAttestKey) {
        let keychain = DependencyContainer.shared.keychainManager
        if let encoded = try? JSONEncoder().encode(key) {
            keychain.set("appAttestKey", value: encoded.base64EncodedString())
        }
    }
    
    private func loadKeyFromKeychain() -> AppAttestKey? {
        let keychain = DependencyContainer.shared.keychainManager
        guard let encodedString = keychain.get("appAttestKey"),
              let data = Data(base64Encoded: encodedString),
              let key = try? JSONDecoder().decode(AppAttestKey.self, from: data) else {
            return nil
        }
        return key
    }
    
    func clearKey() {
        let keychain = DependencyContainer.shared.keychainManager
        keychain.remove("appAttestKey")
        currentKey = nil
        isRegistered = false
    }
    
    // MARK: - Registration State
    
    func ensureRegistered() async throws {
        if !isAvailable {
            return
        }
        
        if !isRegistered || currentKey == nil {
            _ = try await generateKey()
        }
    }
}

// MARK: - Helpers

// Using CryptoKit.SHA256 directly for hashing
