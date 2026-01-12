import Foundation
import Combine

@MainActor
class VouchersViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var vouchers: [Voucher] = []
    
    private let voucherService = VoucherService()
    
    func fetchVouchers() async {
        self.viewState = .loading
        do {
            let fetchedVouchers = try await voucherService.getVouchers()
            self.vouchers = fetchedVouchers
            
            if vouchers.isEmpty {
                self.viewState = .empty
            } else {
                self.viewState = .loaded
            }
        } catch {
            self.viewState = .error(error.localizedDescription)
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
