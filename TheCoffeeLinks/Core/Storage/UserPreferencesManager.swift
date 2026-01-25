import Foundation
import SwiftUI
import Combine

class UserPreferencesManager: ObservableObject {
    @AppStorage("selectedStoreId") var selectedStoreId: String?
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("userBio") var userBio: String = ""
    @AppStorage("userInterests") var userInterestsData: Data = Data()
    
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
        }
    }
}
