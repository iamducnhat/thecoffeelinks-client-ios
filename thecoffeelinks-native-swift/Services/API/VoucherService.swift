import Foundation

// MARK: - API Response Wrappers

struct VouchersResponse: Decodable {
    let vouchers: [Voucher]?
    let data: [Voucher]?
    let error: String?
    
    var items: [Voucher] {
        vouchers ?? data ?? []
    }
}

struct RedeemResponse: Decodable {
    let success: Bool?
    let voucher: Voucher?
    let error: String?
}

// MARK: - VoucherService

class VoucherService: VoucherServiceProtocol {
    private let apiClient = APIClient.shared
    
    func getVouchers() async throws -> [Voucher] {
        let response: VouchersResponse = try await apiClient.get("/api/vouchers")
        return response.items
    }
    
    func getVouchersForUser(userId: UUID) async throws -> [Voucher] {
        return try await getVouchers()
    }
    
    func redeemVoucher(code: String) async throws -> Voucher {
        struct RedeemRequest: Encodable {
            let code: String
        }
        
        let response: RedeemResponse = try await apiClient.patch("/api/vouchers/\(code)", body: RedeemRequest(code: code))
        guard let voucher = response.voucher else {
            throw APIClient.APIError.notFound
        }
        return voucher
    }
}
