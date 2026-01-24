import SwiftUI
import Combine

enum NetworkState: Equatable {
    case idle
    case loading
    case success(String?)
    case error(String)
    
    static func == (lhs: NetworkState, rhs: NetworkState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.success(let lhs), .success(let rhs)):
            return lhs == rhs
        case (.error(let lhs), .error(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

class BaseViewModel: ObservableObject {
    @Published var state: NetworkState = .idle
    @Published var error: String?
    @Published var isLoading: Bool = false
    
    func withLoading(_ block: @escaping () async throws -> Void) {
        Task {
            await MainActor.run {
                isLoading = true
                state = .loading
                error = nil
            }
            
            do {
                try await block()
                await MainActor.run {
                    isLoading = false
                    state = .success(nil)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let msg = error.localizedDescription
                    self.error = msg
                    state = .error(msg)
                    DependencyContainer.shared.logger.log(msg, level: .error)
                }
            }
        }
    }
}
