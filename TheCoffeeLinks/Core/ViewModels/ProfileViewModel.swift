import Foundation
import Combine

class ProfileViewModel: BaseViewModel {
    private let userRepository: UserRepository
    private let voucherRepository: VoucherRepository
    private let socialRepository: SocialRepository
    private let authRepository: AuthRepository
    private let orderRepository: OrderRepositoryProtocol
    private let profileStorage: ProfileStorageProtocol
    
    @Published var userProfile: User?
    @Published var vouchers: [Voucher] = []
    @Published var connections: [User] = []
    @Published var orderCount: Int = 0
    @Published var editMode: Bool = false
    @Published var editName: String = ""
    
    // MARK: - Data Freshness & UI States
    @Published var isProfileStale: Bool = true
    @Published var isOrderCountStale: Bool = true
    @Published var lastProfileSync: Date?
    @Published var lastOrderCountSync: Date?
    @Published var isRefreshingProfile: Bool = false
    @Published var refreshError: AppError?
    @Published var showErrorAlert: Bool = false
    
    private let storage: GenericStorageProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(userRepository: UserRepository, 
         voucherRepository: VoucherRepository, 
         socialRepository: SocialRepository, 
         authRepository: AuthRepository, 
         orderRepository: OrderRepositoryProtocol,
         profileStorage: ProfileStorageProtocol,
         storage: GenericStorageProtocol = GenericStorage()) {
        self.userRepository = userRepository
        self.voucherRepository = voucherRepository
        self.socialRepository = socialRepository
        self.authRepository = authRepository
        self.orderRepository = orderRepository
        self.profileStorage = profileStorage
        self.storage = storage
        super.init()
        
        loadDraft()
        setupAutoSave()
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
            await MainActor.run { 
                self.userProfile = cachedUser
                self.editName = cachedUser.fullName
                self.lastProfileSync = profileStorage.getLastSyncTimestamp(key: "user_profile")
                self.isProfileStale = profileStorage.isDataStale(key: "user_profile", maxAge: 300)
            }
        }
        
        // Load cached vouchers
        if let cachedVouchers = await voucherRepository.getCachedVouchers() {
            await MainActor.run { self.vouchers = cachedVouchers }
        }
        
        // Load cached order count - CRITICAL for offline-first UX
        if let cachedCount = await MainActor.run(body: { profileStorage.loadOrderCount() }) {
            await MainActor.run { 
                self.orderCount = cachedCount
                self.lastOrderCountSync = profileStorage.getLastSyncTimestamp(key: "order_count")
                self.isOrderCountStale = profileStorage.isDataStale(key: "order_count", maxAge: 300)
            }
        }
    }
    
    private func performProfileRefresh() async {
        isRefreshingProfile = true
        do {
            async let userTask = userRepository.refreshUser()
            async let vouchersTask = voucherRepository.refreshVouchers()
            async let connectionsTask = socialRepository.getConnections()
            async let ordersTask = orderRepository.getOrders(status: nil, limit: 100, offset: 0)
            
            let (updatedUser, updatedVouchers, updatedConnections, updatedOrders) = try await (userTask, vouchersTask, connectionsTask, ordersTask)
            
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
                
                // CRITICAL: Cache order count and timestamps for offline-first experience
                self.profileStorage.saveOrderCount(updatedOrders.totalCount)
                self.profileStorage.saveLastSyncTimestamp(key: "user_profile")
                self.profileStorage.saveLastSyncTimestamp(key: "order_count")
                
                // Update freshness indicators
                self.lastProfileSync = Date()
                self.lastOrderCountSync = Date()
                self.isProfileStale = false
                self.isOrderCountStale = false
                self.isRefreshingProfile = false
            }
        } catch {
            print("Profile refresh failed: \(error)")
            await MainActor.run {
                self.isRefreshingProfile = false
                // Keep stale flags as they were - data is still old
                
                // Set user-friendly error
                if let urlError = error as? URLError {
                    if urlError.code == .notConnectedToInternet {
                        self.refreshError = .networkError("No internet connection")
                    } else {
                        self.refreshError = .networkError(urlError.localizedDescription)
                    }
                } else {
                    self.refreshError = .serverError(error.localizedDescription)
                }
                self.showErrorAlert = true
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
                self.storage.remove(key: "profile_name_draft")
                // Update sync timestamp after successful save
                self.profileStorage.saveLastSyncTimestamp(key: "user_profile")
                self.lastProfileSync = Date()
                self.isProfileStale = false
                DependencyContainer.shared.hapticManager.playSuccess()
            }
        }
    }
    
    /// Manual refresh with proper loading states for pull-to-refresh
    func manualRefresh() async {
        guard !isRefreshingProfile else { return } // Prevent duplicate refreshes
        await performProfileRefresh()
    }
    
    private func loadDraft() {
        if let draftName: String = storage.load(String.self, key: "profile_name_draft"), !draftName.isEmpty {
            self.editName = draftName
            self.editMode = true 
        }
    }
    
    private func setupAutoSave() {
        $editName
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .dropFirst()
            .sink { [weak self] name in
                guard let self = self else { return }
                // Only save if different from current profile name
                if let current = self.userProfile?.displayName, name != current {
                    try? self.storage.save(name, key: "profile_name_draft")
                } else if name.isEmpty {
                    self.storage.remove(key: "profile_name_draft")
                }
            }
            .store(in: &cancellables)
    }
}
