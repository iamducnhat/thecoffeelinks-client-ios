import SwiftUI
import Combine

// MARK: - App-wide Error Types
enum AppError: LocalizedError {
    case networkError(String)
    case authenticationError(String)
    case validationError(String)
    case notFound(String)
    case serverError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Network Error: \(msg)"
        case .authenticationError(let msg): return "Authentication Error: \(msg)"
        case .validationError(let msg): return "Validation Error: \(msg)"
        case .notFound(let msg): return "Not Found: \(msg)"
        case .serverError(let msg): return "Server Error: \(msg)"
        case .unknown(let msg): return msg
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .networkError: return "Unable to connect. Please check your internet connection."
        case .authenticationError: return "Please sign in again to continue."
        case .validationError(let msg): return msg
        case .notFound: return "The requested item could not be found."
        case .serverError: return "Something went wrong. Please try again later."
        case .unknown: return "An unexpected error occurred."
        }
    }
}

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
