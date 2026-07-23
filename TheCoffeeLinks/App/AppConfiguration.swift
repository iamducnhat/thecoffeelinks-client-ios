import Foundation

struct AppConfiguration {
    let apiBaseURL: URL

    static let live: AppConfiguration = {
        #if DEBUG
        let apiURLKey = "API_BASE_URL_DEBUG"
        #else
        let apiURLKey = "API_BASE_URL"
        #endif

        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let rawURL = (values[apiURLKey] as? String) ?? (values["API_BASE_URL"] as? String),
            let apiBaseURL = URL(string: rawURL)
        else {
            preconditionFailure("Config.plist must contain a valid API base URL")
        }
        return AppConfiguration(apiBaseURL: apiBaseURL)
    }()
}
