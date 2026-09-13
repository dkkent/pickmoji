import XCTest
@testable import Pickmoji

final class FrecencyTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var now: Date!

    override func setUp() {
        super.setUp()
        suiteName = "PickmojiTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        now = Date(timeIntervalSince1970: 1_800_000_000)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeStore() -> UsageStore {
        UsageStore(defaults: defaults, now: { self.now })
    }

    private func days(_ n: Double) -> TimeInterval { n * 24 * 3600 }

    func testRecordIncrementsCountAndUpdatesLastUsed() {
        let store = makeStore()
        store.record("😀")
        now = now.addingTimeInterval(60)
        store.record("😀")
        XCTAssertEqual(store.records["😀"], .init(count: 2, lastUsed: now))
    }

    func testRecentUseBeatsStaleFrequentUse() {
        let store = makeStore()
        for _ in 0..<3 { store.record("🚀") }
        now = now.addingTimeInterval(days(20))
        store.record("😀")
        XCTAssertEqual(store.top(), ["😀", "🚀"])
    }

    func testEqualRecencyOrdersByCount() {
        let store = makeStore()
        store.record("😀")
        store.record("🚀")
        store.record("🚀")
        XCTAssertEqual(store.top(), ["🚀", "😀"])
    }

    func testScoreDecaysWithAge() {
        let record = UsageStore.Record(count: 2, lastUsed: now)
        let fresh = UsageStore.score(record, now: now)
        let dayOld = UsageStore.score(record, now: now.addingTimeInterval(days(1)))
        let weekOld = UsageStore.score(record, now: now.addingTimeInterval(days(8)))
        let ancient = UsageStore.score(record, now: now.addingTimeInterval(days(90)))
        XCTAssertGreaterThan(fresh, dayOld)
        XCTAssertGreaterThan(dayOld, weekOld)
        XCTAssertGreaterThan(weekOld, ancient)
        XCTAssertEqual(fresh, 200)
    }

    func testTopRespectsLimit() {
        let store = makeStore()
        for i in 0..<20 {
            store.record("e\(i)")
            now = now.addingTimeInterval(1)
        }
        XCTAssertEqual(store.top(16).count, 16)
        XCTAssertEqual(store.top(3), ["e19", "e18", "e17"])
    }

    func testClearRemovesEverything() {
        let store = makeStore()
        store.record("😀")
        store.clear()
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertTrue(store.top().isEmpty)
        XCTAssertTrue(makeStore().records.isEmpty)
    }

    func testRecordsPersistAcrossInstances() {
        makeStore().record("😀")
        let reloaded = makeStore()
        XCTAssertEqual(reloaded.records["😀"]?.count, 1)
        XCTAssertEqual(reloaded.top(), ["😀"])
    }
}
