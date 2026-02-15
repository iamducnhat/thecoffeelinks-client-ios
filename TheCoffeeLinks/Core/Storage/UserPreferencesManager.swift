import Foundation
import SwiftUI
import Combine

final class UserPreferencesManager: ObservableObject, SyncableDomain, @unchecked Sendable {
    @AppStorage("selectedStoreId") private var _selectedStoreId: String?
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("userBio") var userBio: String = ""
    @AppStorage("userInterests") var userInterestsData: Data = Data()
    
    var domainKey: String { "user_preferences" }
    
    private var userRepository: UserRepositoryProtocol?
    private var syncManager: SyncManagerProtocol?
    
    // Dependencies injected via method or property to avoidinit cycle if strict, or Lazy in DI
    // We'll use configuration method or optional properties
    func configure(userRepository: UserRepositoryProtocol, syncManager: SyncManagerProtocol) {
        self.userRepository = userRepository
        self.syncManager = syncManager
        self.syncManager?.register(domain: self)
    }
    
    var selectedStoreId: String? {
        get { _selectedStoreId }
        set {
            _selectedStoreId = newValue
            updateRemotePreferences()
        }
    }
    
    var userInterests: [String] {
        get {
            guard let decoded = try? JSONDecoder().decode([String].self, from: userInterestsData) else {
                return []
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userInterestsData = encoded
            }
            // Sync if supported
        }
    }
    
    func sync(reason: SyncReason) async {
        guard let userRepository = userRepository else { return }
        do {
            let user = try await userRepository.refreshUser()
            await MainActor.run {
                if let storeId = user.preferences.defaultStoreId {
                    if self._selectedStoreId != storeId {
                        self._selectedStoreId = storeId
                    }
                }
            }
        } catch {
            debugLog("Failed to sync preferences: \(error)")
        }
    }
    
    private func updateRemotePreferences() {
        guard let userRepository = userRepository else { return }
        Task {
            do {
                // Fetch current or build new
                 // We need full UserPreferences struct.
                 // This is tricky if we don't have the full object locally.
                 // But UserRepository.updatePreferences takes full struct.
                 // Ideally we fetch cached user, modify ref, and send.
                 if let user = await userRepository.getCachedUser() {
                     var prefs = user.preferences
                     prefs.defaultStoreId = self._selectedStoreId
                     _ = try await userRepository.updatePreferences(prefs)
                 }
            } catch {
                debugLog("Failed to push preference update: \(error)")
            }
        }
    }
}
