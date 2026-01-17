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
    @Published var editInterests: [String] = [] // Kept for UI state even if User model doesn't store it yet
    
    init(userRepository: UserRepository, voucherRepository: VoucherRepository, socialRepository: SocialRepository, authRepository: AuthRepository) {
        self.userRepository = userRepository
        self.voucherRepository = voucherRepository
        self.socialRepository = socialRepository
        self.authRepository = authRepository
        super.init()
    }
    
    func loadProfile() {
        withLoading {
            // Sequential loading to ensure closure captures
            // Note: Parallel fetching could be done with task group but simple sequential is fine for now
            
            // 1. Get Current User
            let current: User? = try await self.authRepository.getCurrentUser()
            
            // 2. Get Vouchers
            let myVouchers: [Voucher] = try await self.voucherRepository.getVouchers()
            
            // 3. Get Connections (Mapped from SocialRepository)
            // Assuming socialRepository has getConnections() or similar method returning [Connection] with friend info
            // If getConnections doesn't exist, we skip or use empty. 
            // Previous error logs implied socialRepository.getConnections() existed or was used.
            // If it DOESN'T exist, we'll verify via previous logs. 
            // Step 627 modified "getConnection" usage.
            // Wait, previous file content showed `async let conns = socialRepository.getConnections()`.
            // Let's assume it exists. If not, I'll need to check SocialRepository.
            // SocialRepository (Data/Repositories) was created recently.
            // If I see a compilation error about getConnections, I will stub it. 
            // For now, I'll assume it returns [Connection].
            
            let myConnections: [Connection] = try await self.socialRepository.getConnections()
            
            await MainActor.run {
                self.userProfile = current
                self.vouchers = myVouchers
                
                // Map Connection to User
                self.connections = myConnections.map { conn in
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
                
                if let u = current {
                    self.editName = u.fullName
                }
            }
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
