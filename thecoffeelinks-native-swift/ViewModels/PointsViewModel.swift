import Foundation
import Combine

struct RewardTier {
    let name: String
    let minPoints: Int
    let maxPoints: Int
    let color: String
    
    // Logic from types/index.ts
    static let bronze = RewardTier(name: "Bronze", minPoints: 0, maxPoints: 99, color: "#CD7F32")
    static let silver = RewardTier(name: "Silver", minPoints: 100, maxPoints: 299, color: "#C0C0C0")
    static let gold = RewardTier(name: "Gold", minPoints: 300, maxPoints: 599, color: "#FFD700")
    static let platinum = RewardTier(name: "Platinum", minPoints: 600, maxPoints: 999999, color: "#E5E4E2")
    
    static let all = [bronze, silver, gold, platinum]
    
    static func current(points: Int) -> RewardTier {
        return all.first { points >= $0.minPoints && points <= $0.maxPoints } ?? bronze
    }
    
    static func next(points: Int) -> RewardTier? {
        let current = self.current(points: points)
        guard let idx = all.firstIndex(where: { $0.name == current.name }) else { return nil }
        return idx < all.count - 1 ? all[idx + 1] : nil
    }
}

@MainActor
class PointsViewModel: ObservableObject {
    @Published var viewState: ViewState = .idle
    @Published var points: Int = 0
    @Published var currentTier: RewardTier = .bronze
    @Published var nextTier: RewardTier? = .silver
    @Published var progressToNext: Double = 0.0
    
    private let userService = UserService()
    
    func fetchPoints() async {
        self.viewState = .loading
        do {
            let user = try await userService.getCurrentUser()
            self.points = user.points ?? 0
            calculateTier()
            self.viewState = .loaded
        } catch {
            self.viewState = .error(error.localizedDescription)
        }
    }
    
    private func calculateTier() {
        self.currentTier = RewardTier.current(points: points)
        self.nextTier = RewardTier.next(points: points)
        
        if let next = nextTier {
            let needed = Double(next.minPoints - currentTier.minPoints)
            let currentProgress = Double(points - currentTier.minPoints)
            self.progressToNext = min(max(currentProgress / needed, 0.0), 1.0)
        } else {
            self.progressToNext = 1.0 // Max tier
        }
    }
}
