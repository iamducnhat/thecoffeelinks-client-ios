import XCTest
@testable import TheCoffeeLinks

final class LiteQRAndCacheTests: XCTestCase {
    func testQRExpiresAtServerTimestamp() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let qr = MemberQR(payload: "TCLM1.signed", expiresAt: now.addingTimeInterval(120), memberCode: "TCL-1")
        XCTAssertFalse(qr.isExpired(at: now.addingTimeInterval(119)))
        XCTAssertTrue(qr.isExpired(at: now.addingTimeInterval(120)))
        XCTAssertEqual(qr.secondsRemaining(at: now.addingTimeInterval(60)), 60)
    }

    func testCacheRoundTripSupportsOfflineRead() async {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("lite-cache-\(UUID().uuidString).json")
        let cache = LiteCache(fileURL: fileURL)
        let history = HistoryPage(items: [LiteFixture.transaction("cached")], nextCursor: "next")

        await cache.save(member: LiteFixture.member, history: history)
        let loaded = await cache.load()
        XCTAssertEqual(loaded?.member, LiteFixture.member)
        XCTAssertEqual(loaded?.history, history)
        await cache.clear()
        let cleared = await cache.load()
        XCTAssertNil(cleared)
    }
}
