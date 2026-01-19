import Foundation
import Combine

class ProfileViewModel: BaseViewModel {
    private let userRepository: UserRepository
    private let voucherRepository: VoucherRepository
    private let socialRepository: SocialRepository
    private let authRepository: AuthRepository
    private let orderRepository: OrderRepositoryProtocol
    
    @Published var userProfile: User?
    @Published var vouchers: [Voucher] = []
    @Published var userVouchers: [UserVoucher] = []
    @Published var connections: [User] = []
    @Published var orderCount: Int = 0
    @Published var editMode: Bool = false
    @Published var editName: String = ""
    
    init(userRepository: UserRepository, voucherRepository: VoucherRepository, socialRepository: SocialRepository, authRepository: AuthRepository, orderRepository: OrderRepositoryProtocol) {
        self.userRepository = userRepository
        self.voucherRepository = voucherRepository
        self.socialRepository = socialRepository
        self.authRepository = authRepository
        self.orderRepository = orderRepository
        super.init()
    }
    
    func loadProfile() {
        // Fire and forget task to keep signature but run async logic
        Task {
            await loadCachedProfile()
            await performProfileRefresh()
        }
    }
    
    private func loadCachedProfile() async {
        // Load cached user
        if let cachedUser = await userRepository.getCachedUser() {
            await MainActor.run { self.userProfile = cachedUser; self.editName = cachedUser.fullName }
        }
        
        // Load cached vouchers
        if let cachedVouchers = await voucherRepository.getCachedVouchers() {
            await MainActor.run { self.vouchers = cachedVouchers }
        }
    }
    
    private func performProfileRefresh() async {
        do {
            async let userTask = userRepository.refreshUser()
            async let vouchersTask = voucherRepository.refreshVouchers()
            async let myVouchersTask = voucherRepository.getUserVouchers()
            async let connectionsTask = socialRepository.getConnections()
            async let ordersTask = orderRepository.getOrders(status: nil, limit: 100, offset: 0)
            
            let (updatedUser, updatedVouchers, updatedMyVouchers, updatedConnections, updatedOrders) = try await (userTask, vouchersTask, myVouchersTask, connectionsTask, ordersTask)
            
            await MainActor.run {
                // Fix for ID 000000:
                // If the refreshed user has no shortId (or it's effectively empty),
                // but we already have a valid one in memory (from cache or login), preserve it.
                var finalUser = updatedUser
                if (finalUser.shortId == nil || finalUser.shortId == "000000"),
                   let existingUser = self.userProfile,
                   let validShortId = existingUser.shortId,
                   validShortId != "000000" {
                    
                    print("DEBUG: Preserving valid shortId: \(validShortId) over nil/empty one from refresh.")
                    finalUser = User(
                        id: finalUser.id,
                        shortId: validShortId,
                        shortIdVersion: finalUser.shortIdVersion,
                        email: finalUser.email,
                        phone: finalUser.phone,
                        displayName: finalUser.displayName,
                        avatarUrl: finalUser.avatarUrl,
                        membershipTier: finalUser.membershipTier,
                        points: finalUser.points,
                        createdAt: finalUser.createdAt,
                        preferences: finalUser.preferences
                    )
                }
                
                self.userProfile = finalUser
                self.vouchers = updatedVouchers
                self.userVouchers = updatedMyVouchers
                self.connections = updatedConnections.map { conn in
                     User(id: conn.friendId,
                          email: nil,
                          phone: nil,
                          displayName: conn.friendName,
                          avatarUrl: conn.friendAvatar,
                          membershipTier: .bronze,
                          points: 0,
                          createdAt: conn.connectedAt,
                          preferences: .default)
                }
                self.orderCount = updatedOrders.totalCount
                self.editName = finalUser.fullName
            }
        } catch {
            print("Profile refresh failed: \(error)")
        }
    }
    
    func saveProfile() {
        guard let id = self.userProfile?.id else { return }
        withLoading {
            let updatedUser = try await self.userRepository.updateUser(
                User(id: id,
                     email: self.userProfile?.email,
                     phone: self.userProfile?.phone,
                     displayName: self.editName,
                     avatarUrl: self.userProfile?.avatarUrl,
                     membershipTier: self.userProfile?.membershipTier ?? .bronze,
                     points: self.userProfile?.points ?? 0,
                     createdAt: self.userProfile?.createdAt ?? Date(),
                     preferences: self.userProfile?.preferences ?? .default)
            )
            
            await MainActor.run {
                self.userProfile = updatedUser
                self.editMode = false
                DependencyContainer.shared.hapticManager.playSuccess()
            }
        }
    }
}
