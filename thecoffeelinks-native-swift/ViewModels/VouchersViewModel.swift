import Foundation
import Combine

@MainActor
class VouchersViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var vouchers: [Voucher] = []
    
    private let voucherService = VoucherService()
    private let cacheKey = "vouchers_cache"
    
    init() {
        if let cachedVouchers = CacheManager.shared.load([Voucher].self, for: cacheKey) {
            self.vouchers = cachedVouchers
            self.viewState = .loaded
        }
    }
    
    func fetchVouchers() async {
        if vouchers.isEmpty {
            self.viewState = .loading
        }
        
        do {
            let fetchedVouchers = try await voucherService.getVouchers()
            self.vouchers = fetchedVouchers
            await CacheManager.shared.save(fetchedVouchers, for: cacheKey)
            
            if vouchers.isEmpty {
                self.viewState = .empty
            } else {
                self.viewState = .loaded
            }
        } catch {
            if vouchers.isEmpty {
                self.viewState = .error(error.localizedDescription)
            }
        }
    }
    
    func redeemVoucher(code: String) async {
        do {
            let _ = try await voucherService.redeemVoucher(code: code)
            await fetchVouchers() // Refresh list
        } catch {
            print("Redeem failed: \(error.localizedDescription)")
        }
    }
}
