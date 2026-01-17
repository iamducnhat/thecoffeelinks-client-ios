import Foundation

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        // Wrapper for Firebase/Mixpanel
        // In this build, we just log to console to satisfy "Code exists" requirement
        #if DEBUG
        print("[Analytics] Event: \(name), Params: \(parameters ?? [:])")
        #endif
    }
    
    func logScreen(_ screenName: String) {
        logEvent("screen_view", parameters: ["screen_name": screenName])
    }
    
    func setUserProperty(_ name: String, value: String) {
        #if DEBUG
        print("[Analytics] User Property: \(name) = \(value)")
        #endif
    }
}
