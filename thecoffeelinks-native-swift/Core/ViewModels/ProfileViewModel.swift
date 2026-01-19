import Foundation
import Combine

class ProfileViewModel: BaseViewModel {
    private let userRepository: UserRepository
    private let voucherRepository: VoucherRepository
    private let socialRepository: SocialRepository
    private let authRepository: AuthRepository
    
    @Published var userProfile: User?
    @Published var vouchers: [Voucher] = []
    @Published var connections: [User] = []
    @Published var editMode: Bool = false
    @Published var editName: String = ""
    
    init(userRepository: UserRepository, voucherRepository: VoucherRepository, socialRepository: SocialRepository, authRepository: AuthRepository) {
        self.userRepository = userRepository
        self.voucherRepository = voucherRepository
        self.socialRepository = socialRepository
        self.authRepository = authRepository
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
            async let connectionsTask = socialRepository.getConnections()
            
            let (updatedUser, updatedVouchers, updatedConnections) = try await (userTask, vouchersTask, connectionsTask)
            
            await MainActor.run {
                self.userProfile = updatedUser
                self.vouchers = updatedVouchers
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
                self.editName = updatedUser.fullName
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
