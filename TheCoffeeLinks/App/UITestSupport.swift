#if DEBUG
import Foundation

private actor UITestState {
    var hasSession: Bool
    var fullName: String
    var deleted = false

    init(isNewMember: Bool) {
        hasSession = !isNewMember
        fullName = isNewMember ? "" : "Nguyễn An"
    }
}

private actor UITestAuthRepository: AuthRepositoryProtocol {
    let state: UITestState
    init(state: UITestState) { self.state = state }

    func hasSession() async -> Bool { await state.hasSession }
    func sendOTP(to phone: String) async throws {}
    func verifyOTP(phone: String, code: String) async throws { await state.setSession() }
    func updateName(_ name: String) async throws { await state.setName(name) }
    func signOut() async { await state.signOut() }
    func deleteAccount(phone: String, otp: String) async throws { await state.delete() }
}

private extension UITestState {
    func setSession() { hasSession = true }
    func setName(_ value: String) { fullName = value }
    func signOut() { hasSession = false }
    func delete() { deleted = true; hasSession = false }
}

private actor UITestLoyaltyRepository: LoyaltyRepositoryProtocol {
    let state: UITestState
    let arguments: [String]

    init(state: UITestState, arguments: [String]) {
        self.state = state
        self.arguments = arguments
    }

    func memberSnapshot(cursor: String?) async throws -> (Member, HistoryPage) {
        let member = Member(
            id: "ui-member",
            fullName: await state.fullName,
            phone: "+84901234567",
            memberCode: "TCL-240102",
            points: 1_280,
            memberSince: Date(timeIntervalSince1970: 1_704_153_600),
            tier: nil
        )
        let first = PointTransaction(
            id: "txn-1",
            points: 42,
            kind: "earned",
            createdAt: Date(),
            storeName: "The Coffee Links · Quận 1",
            invoiceCode: "TCL-INV-0102",
            eligibleAmount: 42_000,
            vndPerPoint: 1_000,
            description: nil
        )
        return (member, HistoryPage(items: [first], nextCursor: nil))
    }

    func cachedSnapshot() async -> (Member, HistoryPage)? { nil }

    func memberQR() async throws -> MemberQR {
        if arguments.contains("-ui-qr-error") { throw APIError.offline }
        let expiration = arguments.contains("-ui-qr-expired") ? Date().addingTimeInterval(-1) : Date().addingTimeInterval(120)
        return MemberQR(payload: "TCLM1.ui-test.signed", expiresAt: expiration, memberCode: "TCL-240102")
    }

    func clearCache() async {}
}

extension AppContainer {
    static var uiTest: AppContainer {
        let arguments = ProcessInfo.processInfo.arguments
        let state = UITestState(isNewMember: arguments.contains("-ui-new-member"))
        return AppContainer(
            auth: UITestAuthRepository(state: state),
            loyalty: UITestLoyaltyRepository(state: state, arguments: arguments)
        )
    }
}
#endif
