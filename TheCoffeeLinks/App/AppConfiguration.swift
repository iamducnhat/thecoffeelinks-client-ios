import Foundation

struct AppConfiguration {
    let apiBaseURL: URL

    static let live: AppConfiguration = {
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let rawURL = values["API_BASE_URL"] as? String,
            let apiBaseURL = URL(string: rawURL)
        else {
            preconditionFailure("Config.plist must contain a valid API_BASE_URL")
        }
        return AppConfiguration(apiBaseURL: apiBaseURL)
    }()
}
