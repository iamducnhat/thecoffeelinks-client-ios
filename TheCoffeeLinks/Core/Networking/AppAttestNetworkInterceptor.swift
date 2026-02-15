//
//  AppAttestNetworkInterceptor.swift
//  thecoffeelinks-client-ios
//
//  Interceptor that adds App Attest assertions to protected requests
//

import Foundation
import CryptoKit

// MARK: - Protected Endpoints

enum ProtectedEndpoint: String, CaseIterable {
    case phoneVerification = "/api/auth/otp/verify"
    case staffDeviceAuth = "/api/staff/device-attest"
    case createOrder = "/api/orders"
    case redemption = "/api/vouchers/redeem"
    case pointsRedemption = "/api/user/points/redeem"

    var requiresAppAttest: Bool {
        return true
    }
}

// MARK: - App Attest Network Interceptor

@MainActor
final class AppAttestNetworkInterceptor {
    static let shared = AppAttestNetworkInterceptor()
    private let attestService = AppAttestService.shared
    private let networkService = DependencyContainer.shared.networkService

    private init() {}

    // MARK: - Prepare Request with App Attest

    func prepareRequest(
        endpoint: String,
        body: Data? = nil
    ) async throws -> (keyId: String, assertion: String, challenge: String)? {
        // Check if endpoint requires App Attest
        guard ProtectedEndpoint.allCases.contains(where: {
            endpoint.hasPrefix($0.rawValue)
        }) else {
            return nil
        }

        // Check if App Attest is registered (registration happens in AuthRepository after OTP verification)
        guard attestService.isRegistered else {
            debugLog("[AppAttestInterceptor] App Attest not registered, skipping protected request")
            return nil
        }

        // Get challenge from server
        let serverChallenge = try? await fetchChallenge()

        // Generate challenge for payload integrity
        let payloadChallenge = generateChallengeForEndpoint(endpoint, body: body)

        // Combine server challenge with payload challenge for security
        let combinedChallenge = "\(serverChallenge ?? ""):\(payloadChallenge)"

        // Generate assertion
        let assertion = try await attestService.generateAssertion(for: combinedChallenge)

        debugLog("[AppAttestInterceptor] Added assertion for \(endpoint)")
        return (assertion.keyId, assertion.assertion, combinedChallenge)
    }

    // MARK: - Fetch Challenge from Server

    private func fetchChallenge() async throws -> String {
        struct ChallengeResponse: Decodable {
            let success: Bool
            let challenge: String
            let timestamp: Int64
        }

        let response: ChallengeResponse = try await networkService.request(
            "/api/auth/app-attest/challenge",
            method: "GET"
        )

        if response.success {
            return response.challenge
        }

        // Fallback to local challenge generation
        return attestService.generateChallenge()
    }

    // MARK: - Challenge Generation for Endpoints

    private func generateChallengeForEndpoint(_ endpoint: String, body: Data?) -> String {
        var hashComponents = [endpoint]

        // Add body hash for request-level integrity
        if let body = body {
            let bodyHash = SHA256.hash(data: body)
            hashComponents.append(bodyHash.withUnsafeBytes { Data($0).base64EncodedString() })
        }

        // Add timestamp for replay protection
        let timestamp = Int64(Date().timeIntervalSince1970)
        hashComponents.append(String(timestamp))

        // Combine and hash
        let combined = hashComponents.joined(separator: "|")
        let hash = SHA256.hash(data: combined.data(using: .utf8)!)

        return Data(hash).base64EncodedString()
    }
}

// MARK: - SHA256 Helper

// Using CryptoKit.SHA256 directly
