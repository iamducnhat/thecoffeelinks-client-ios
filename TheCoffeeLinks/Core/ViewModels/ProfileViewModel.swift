import Foundation
import Combine

class ProfileViewModel: BaseViewModel {
    private let userRepository: UserRepository
    private let voucherRepository: VoucherRepository
    private let socialRepository: SocialRepository
    private let authRepository: AuthRepository
    private let orderRepository: OrderRepositoryProtocol
    private let profileStorage: ProfileStorageProtocol
    private let keychainManager: KeychainManager
    
    // REMOVED: Duplicate userProfile - use AuthViewModel.currentUser as single source of truth
    // Reference to AuthViewModel for reading user data
    weak var authViewModel: AuthViewModel?
    
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
    
    // Computed property for user profile (reads from AuthViewModel)
    var userProfile: User? {
        authViewModel?.currentUser
    }
    
    init(userRepository: UserRepository, 
         voucherRepository: VoucherRepository, 
         socialRepository: SocialRepository, 
         authRepository: AuthRepository, 
         orderRepository: OrderRepositoryProtocol,
         profileStorage: ProfileStorageProtocol,
         keychainManager: KeychainManager,
         storage: GenericStorageProtocol = GenericStorage()) {
        self.userRepository = userRepository
        self.voucherRepository = voucherRepository
        self.socialRepository = socialRepository
        self.authRepository = authRepository
        self.orderRepository = orderRepository
        self.profileStorage = profileStorage
        self.keychainManager = keychainManager
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
        // User profile is loaded from AuthViewModel.currentUser (single source of truth)
        // Just update editName if user exists
        if let user = authViewModel?.currentUser {
            await MainActor.run {
                self.editName = user.fullName
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
        // Auth guard - skip refresh if not authenticated
        guard keychainManager.getAccessToken() != nil else {
            debugLog("⏭️ [ProfileViewModel] No access token, skipping profile refresh")
            isRefreshingProfile = false
            return
        }
        
        isRefreshingProfile = true
        do {
            async let userTask = userRepository.refreshUser()
            async let vouchersTask = voucherRepository.refreshVouchers()
            async let connectionsTask = socialRepository.getConnections()
            async let ordersTask = orderRepository.getOrders(status: nil, limit: 100, offset: 0)
            
            let (updatedUser, updatedVouchers, updatedConnections, updatedOrders) = try await (userTask, vouchersTask, connectionsTask, ordersTask)
            
            await MainActor.run {
                // Update AuthViewModel's user (single source of truth)
                // Fix for ID 000000: Preserve valid shortId if server returns empty
                if let existingUser = self.authViewModel?.currentUser,
                   let validShortId = existingUser.shortId,
                   validShortId != "000000",
                   (updatedUser.shortId == nil || updatedUser.shortId == "000000") {
                    
                    debugLog("DEBUG: Preserving valid shortId: \(validShortId) over nil/empty one from refresh.")
                    var finalUser = updatedUser
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
                    self.authViewModel?.currentUser = finalUser
                    self.editName = finalUser.fullName
                } else {
                    self.authViewModel?.currentUser = updatedUser
                    self.editName = updatedUser.fullName
                }
                
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
            debugLog("Profile refresh failed: \(error)")
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
                // Update AuthViewModel (single source of truth)
                self.authViewModel?.currentUser = updatedUser
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

    /// Distribute available vouchers to the current user then refresh the voucher list.
    func distributeAndRefreshVouchers() async {
        guard let userId = authViewModel?.currentUser?.id else { return }
        do {
            let _ = try await voucherRepository.fetchAndDistributeVouchers(userId: userId)
            // Removed intermediate UI update with distributed vouchers to prevent sorting flicker
        } catch {
            // Silently ignore — user may simply have no eligible vouchers
        }
        // Always follow up with a normal refresh to get the latest state
        do {
            let fresh = try await voucherRepository.refreshVouchers()
            await MainActor.run { self.vouchers = fresh }
        } catch {}
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
