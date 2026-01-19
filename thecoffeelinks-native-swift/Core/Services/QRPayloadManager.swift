//
//  QRPayloadManager.swift
//  thecoffeelinks-native-swift
//
//  Manages the lifecycle of the Secure QR Code.
//

import Foundation
import Combine
import Supabase

@MainActor
class QRPayloadManager: ObservableObject {
    // MARK: - Published State
    @Published var currentPayload: String?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // MARK: - Properties
    private var timer: Timer?
    private var currentVoucherId: String?
    private let supabase: SupabaseClient
    private let keychainManager: KeychainManager
    
    // MARK: - Initialization
    init(supabase: SupabaseClient = DependencyContainer.shared.supabase,
         keychainManager: KeychainManager = DependencyContainer.shared.keychainManager) {
        self.supabase = supabase
        self.keychainManager = keychainManager
    }
    
    // MARK: - Public API
    
    func startRotation() {
        refreshQR()
        stopRotation()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshQR()
            }
        }
    }
    
    func stopRotation() {
        timer?.invalidate()
        timer = nil
    }
    
    func selectVoucher(_ voucherId: String?) {
        guard self.currentVoucherId != voucherId else { return }
        self.currentVoucherId = voucherId
        refreshQR()
    }
    
    func refreshQR() {
        Task {
            isLoading = true
            do {
                let payload = try await generateQR(voucherId: currentVoucherId)
                self.currentPayload = payload
                self.error = nil
            } catch {
                print("❌ QR Generation Failed: \(error.localizedDescription)")
                self.error = "Failed to update QR"
            }
            isLoading = false
        }
    }
    
    // MARK: - Private Network Call
    
    private struct GenerateQRRequest: Encodable {
        let voucherId: String?
        
        enum CodingKeys: String, CodingKey {
            case voucherId = "voucher_id"
        }
    }
    
    // Define Response structure matching Edge Function output
    private struct GenerateQRResponse: Decodable {
        let qrCode: String
        
        enum CodingKeys: String, CodingKey {
            case qrCode = "qr_code"
        }
    }
    
    private func generateQR(voucherId: String?) async throws -> String {
        guard let token = keychainManager.getAccessToken() else {
            throw NSError(domain: "QRPayloadManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let body = GenerateQRRequest(voucherId: voucherId)
        
        // Invoke Edge Function directly via Supabase Client
        // We manually construct the Authorization header with the user's token
        let response: GenerateQRResponse = try await supabase.functions.invoke(
            "generate-qr",
            options: FunctionInvokeOptions(
                headers: ["Authorization": "Bearer \(token)"],
                body: body
            )
        )
        
        return response.qrCode
    }
}
