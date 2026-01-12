import Foundation
import Combine

enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var viewState: ViewState = .idle
    
    private let userService: UserServiceProtocol
    
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
    
    func fetchProfile() async {
        self.viewState = .loading
        do {
            let user = try await userService.getCurrentUser()
            self.user = user
            self.viewState = .loaded
        } catch {
            self.viewState = .error(error.localizedDescription)
            // Handle specific errors like 'Auth session missing'
        }
    }
    
    func updateProfile(jobTitle: String, bio: String) async {
        guard let userId = user?.id else { return }
        
        var params = UpdateProfileParams()
        params.jobTitle = jobTitle
        params.bio = bio
        
        do {
            let updatedUser = try await userService.updateProfile(userId: userId, params: params)
            self.user = updatedUser
        } catch {
            self.viewState = .error(error.localizedDescription)
        }
    }
    
    func signOut() async {
        await AuthViewModel.shared.signOut()
    }
}
