import Foundation
@testable import TheCoffeeLinks

actor MockAuthRepository: AuthRepositoryProtocol {
    var sessionExists: Bool
    private(set) var sentPhones: [String] = []
    private(set) var verifiedCode: String?
    private(set) var deletedOTP: String?

    init(sessionExists: Bool) { self.sessionExists = sessionExists }

    func hasSession() async -> Bool { sessionExists }
    func sendOTP(to phone: String) async throws { sentPhones.append(phone) }
    func verifyOTP(phone: String, code: String) async throws { verifiedCode = code; sessionExists = true }
    func updateName(_ name: String) async throws {}
    func signOut() async { sessionExists = false }
    func deleteAccount(phone: String, otp: String) async throws { deletedOTP = otp; sessionExists = false }
}

actor MockLoyaltyRepository: LoyaltyRepositoryProtocol {
    var firstPage: (Member, HistoryPage)
    var secondPage: (Member, HistoryPage)?
    var cache: (Member, HistoryPage)?
    var qr: MemberQR?
    var snapshotError: APIError?
    private(set) var requestedCursors: [String?] = []
    private(set) var didClearCache = false

    init(
        firstPage: (Member, HistoryPage),
        secondPage: (Member, HistoryPage)? = nil,
        cache: (Member, HistoryPage)? = nil,
        snapshotError: APIError? = nil
    ) {
        self.firstPage = firstPage
        self.secondPage = secondPage
        self.cache = cache
        self.snapshotError = snapshotError
    }

    func memberSnapshot(cursor: String?) async throws -> (Member, HistoryPage) {
        requestedCursors.append(cursor)
        if let snapshotError { throw snapshotError }
        if cursor != nil, let secondPage { return secondPage }
        return firstPage
    }
    func cachedSnapshot() async -> (Member, HistoryPage)? { cache }
    func memberQR() async throws -> MemberQR { qr ?? MemberQR(payload: "TCLM1.test", expiresAt: Date().addingTimeInterval(120), memberCode: firstPage.0.memberCode) }
    func clearCache() async { didClearCache = true; cache = nil }
}

enum LiteFixture {
    static let member = Member(
        id: "member-1",
        fullName: "Nguyễn An",
        phone: "+84901234567",
        memberCode: "TCL-000001",
        points: 120,
        memberSince: Date(timeIntervalSince1970: 1_700_000_000),
        tier: nil
    )

    static func transaction(_ id: String, points: Int = 10) -> PointTransaction {
        PointTransaction(
            id: id,
            points: points,
            kind: "earned",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            storeName: "Quận 1",
            invoiceCode: "INV-\(id)",
            eligibleAmount: points * 1_000,
            vndPerPoint: 1_000,
            description: nil
        )
    }
}
