import Foundation

struct AppContainer {
    let auth: any AuthRepositoryProtocol
    let loyalty: any LoyaltyRepositoryProtocol

    static let live: AppContainer = {
        let client = APIClient(baseURL: AppConfiguration.live.apiBaseURL)
        return AppContainer(
            auth: AuthRepository(client: client),
            loyalty: LoyaltyRepository(client: client)
        )
    }()

    static var app: AppContainer {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") { return uiTest }
#endif
        return live
    }
}
