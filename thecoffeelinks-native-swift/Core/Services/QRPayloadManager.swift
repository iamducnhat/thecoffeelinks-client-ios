//
//  QRPayloadManager.swift
//  thecoffeelinks-native-swift
//
//  Manages the lifecycle of the Secure QR Code.
//

import Foundation
import Combine

@MainActor
class QRPayloadManager: ObservableObject {
    // MARK: - Published State
    @Published var currentPayload: String?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // MARK: - Properties
    private var timer: Timer?
    private var currentVoucherId: String?
    private let networkService: NetworkServiceProtocol
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = DependencyContainer.shared.networkService) {
        self.networkService = networkService
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
    
    private struct GenerateQRResponse: Decodable {
        let qrCode: String
        
        enum CodingKeys: String, CodingKey {
            case qrCode = "qr_code"
        }
    }
    
    private func generateQR(voucherId: String?) async throws -> String {
        let body = GenerateQRRequest(voucherId: voucherId)
        // Calling Edge Function via NetworkService
        // Assumes API_BASE_URL points to Supabase or proxy that routes /functions/v1/...
        let response: GenerateQRResponse = try await networkService.post("/functions/v1/generate-qr", body: body)
        return response.qrCode
    }
}
