import Foundation

/// App configuration loaded from Config.plist
/// IMPORTANT: Do not commit Config.plist with production values to source control
struct Secrets {
    
    private static let config: [String: Any] = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            #if DEBUG
            // Fallback for development - these should be replaced in production
            return [
                "SUPABASE_URL": "https://ggikmpqyhkfhctwqbytk.supabase.co",
                "SUPABASE_ANON_KEY": "your-anon-key-here",
                "API_BASE_URL": "http://localhost:3000"
            ]
            #else
            fatalError("Config.plist not found. Please create Config.plist with required keys.")
            #endif
        }
        return dict
    }()
    
    static var supabaseURL: URL {
        guard let urlString = config["SUPABASE_URL"] as? String,
              let url = URL(string: urlString) else {
            fatalError("Invalid SUPABASE_URL in Config.plist")
        }
        return url
    }
    
    static var supabaseAnonKey: String {
        guard let key = config["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not found in Config.plist")
        }
        return key
    }
    
    static var apiBaseURL: URL {
        guard let urlString = config["API_BASE_URL"] as? String,
              let url = URL(string: urlString) else {
            // Default fallback
            return URL(string: "https://server-nu-three-90.vercel.app")!
        }
        return url
    }
}
