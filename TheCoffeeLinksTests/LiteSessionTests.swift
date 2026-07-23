import XCTest
@testable import TheCoffeeLinks

@MainActor
final class LiteSessionTests: XCTestCase {
    func testOTPVerificationRestoresExistingMember() async {
        let auth = MockAuthRepository(sessionExists: false)
        let loyalty = MockLoyaltyRepository(firstPage: (LiteFixture.member, HistoryPage(items: [], nextCursor: nil)))
        let session = AppSession(container: AppContainer(auth: auth, loyalty: loyalty))

        await session.restore()
        XCTAssertEqual(session.flow, .authentication)
        let didSend = await session.sendOTP(phone: "090 123 4567")
        let didVerify = await session.verifyOTP("123456")
        let sentPhones = await auth.sentPhones
        let verifiedCode = await auth.verifiedCode
        XCTAssertTrue(didSend)
        XCTAssertTrue(didVerify)
        XCTAssertEqual(session.flow, .member)
        XCTAssertEqual(sentPhones, ["+84901234567"])
        XCTAssertEqual(verifiedCode, "123456")
    }

    func testHistoryLoadsTwentyItemPagesWithoutDuplicates() async {
        let firstItems = (0..<20).map { LiteFixture.transaction("first-\($0)") }
        let secondItems = [LiteFixture.transaction("first-19"), LiteFixture.transaction("second-1")]
        let auth = MockAuthRepository(sessionExists: true)
        let loyalty = MockLoyaltyRepository(
            firstPage: (LiteFixture.member, HistoryPage(items: firstItems, nextCursor: "cursor-2")),
            secondPage: (LiteFixture.member, HistoryPage(items: secondItems, nextCursor: nil))
        )
        let session = AppSession(container: AppContainer(auth: auth, loyalty: loyalty))

        await session.restore()
        await session.loadMoreHistory()
        XCTAssertEqual(session.history.count, 21)
        XCTAssertNil(session.nextCursor)
        let cursors = await loyalty.requestedCursors.compactMap { $0 }
        XCTAssertEqual(cursors, ["cursor-2"])
    }

    func testAccountDeletionUsesFreshOTPAndClearsLocalState() async {
        let auth = MockAuthRepository(sessionExists: true)
        let loyalty = MockLoyaltyRepository(firstPage: (LiteFixture.member, HistoryPage(items: [], nextCursor: nil)))
        let session = AppSession(container: AppContainer(auth: auth, loyalty: loyalty))
        await session.restore()

        let didSend = await session.sendDeletionOTP()
        let didDelete = await session.deleteAccount(otp: "654321")
        let deletedOTP = await auth.deletedOTP
        let didClearCache = await loyalty.didClearCache
        XCTAssertTrue(didSend)
        XCTAssertTrue(didDelete)
        XCTAssertEqual(session.flow, .authentication)
        XCTAssertNil(session.member)
        XCTAssertEqual(deletedOTP, "654321")
        XCTAssertTrue(didClearCache)
    }

    func testExpiredSessionDoesNotExposeCachedMemberData() async {
        let cached = (LiteFixture.member, HistoryPage(items: [LiteFixture.transaction("cached")], nextCursor: nil))
        let auth = MockAuthRepository(sessionExists: true)
        let loyalty = MockLoyaltyRepository(
            firstPage: cached,
            cache: cached,
            snapshotError: .unauthorized
        )
        let session = AppSession(container: AppContainer(auth: auth, loyalty: loyalty))

        await session.restore()

        let hasSession = await auth.hasSession()
        let didClearCache = await loyalty.didClearCache
        XCTAssertEqual(session.flow, .authentication)
        XCTAssertNil(session.member)
        XCTAssertTrue(session.history.isEmpty)
        XCTAssertFalse(hasSession)
        XCTAssertTrue(didClearCache)
    }
}
