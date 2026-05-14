import SwiftUI

struct AppEnvironment {
    static let apiBaseURL = "https://api.thecoffeelinks.vn/api"
    
    // Feature Flags (Simulated locally for now)
    static let enableAI = true
    static let enableBooking = true
    static let enableDelivery = true
}

enum APIEndpoint {
    case login
    case register
    case profile
    case stores
    case menu
    
    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .register: return "/auth/register"
        case .profile: return "/auth/me"
        case .stores: return "/stores"
        case .menu: return "/products"
        }
    }
}
