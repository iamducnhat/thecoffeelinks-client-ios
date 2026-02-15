import Foundation
import Combine
import SwiftUI

class NetworkViewModel: BaseViewModel {
    private let socialRepository: SocialRepository
    private let locationManager: LocationManager
    
    // Define NetworkIntent locally for UI compatibility (Legacy/Phase 3 concept)
    enum NetworkIntent: String, CaseIterable {
        case hiring
        case learning
        case collaboration
        case openChat = "open_chat"
        
        var title: String {
            switch self {
            case .hiring: return "Hiring"
            case .learning: return "Learning"
            case .collaboration: return "Collaboration"
            case .openChat: return "Open Chat"
            }
        }
        
        var icon: String {
            switch self {
            case .hiring: return "magnifyingglass"
            case .learning: return "book.fill"
            case .collaboration: return "person.2.fill"
            case .openChat: return "bubble.left.and.bubble.right.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .hiring: return .purple
            case .learning: return .orange
            case .collaboration: return .blue
            case .openChat: return .green
            }
        }
        
        // Map to Domain PresenceStatus
        var toStatus: PresenceStatus {
            switch self {
            case .openChat: return .available
            default: return .available // Default to available for all intents
            }
        }
    }
    
    @Published var activeCheckIn: StorePresence? // Updated type
    @Published var nearbyPeople: [User] = []
    @Published var currentIntent: NetworkIntent = .openChat
    @Published var selectedStoreDetails: Store? 
    @Published var checkInDuration: TimeInterval = 3600 // Default 1 hour
    
    init(socialRepository: SocialRepository, locationManager: LocationManager) {
        self.socialRepository = socialRepository
        self.locationManager = locationManager
        super.init()
    }
    
    func checkIn(store: Store, intent: NetworkIntent) {
        withLoading {
            // Map intent to Status. API limitation: Intent strings not currently supported by check-in endpoint.
            // We use .available as default for these active intents.
            let presence = try await self.socialRepository.checkIn(storeId: store.id, status: intent.toStatus)
            
            await MainActor.run {
                self.activeCheckIn = presence
                self.currentIntent = intent
                self.selectedStoreDetails = store
                DependencyContainer.shared.hapticManager.playSuccess()
            }
            
            // Immediately fetch people there
            self.fetchNearbyPeople(storeId: store.id)
        }
    }
    
    func checkOut() {
        guard let presence = activeCheckIn else { return }
        withLoading {
            try await self.socialRepository.checkOut(storeId: presence.storeId)
            await MainActor.run {
                self.activeCheckIn = nil
                self.nearbyPeople = []
            }
        }
    }
    
    func fetchNearbyPeople(storeId: String) {
        Task {
            do {
                let presences = try await socialRepository.getPresences(storeId: storeId)
                await MainActor.run {
                    // Map StorePresence to User for UI compatibility
                    self.nearbyPeople = presences.compactMap { p in
                        // Create partial User from Presence
                        // User struct is immutable (let properties), so we use the initializer
                        return User(
                            id: p.userId,
                            email: nil,
                            phone: nil,
                            displayName: p.displayName,
                            avatarUrl: p.avatarUrl,
                            membershipTier: .bronze,
                            points: 0,
                            createdAt: Date(),
                            preferences: .default
                        )
                    }
                }
            } catch {
                debugLog("Error fetching people: \(error)")
            }
        }
    }
    
    func sendConnectionRequest(to user: User) {
        withLoading {
            _ = try await self.socialRepository.sendConnectionRequest(toUserId: user.id, message: nil)
            DependencyContainer.shared.hapticManager.playSuccess()
        }
    }
}
