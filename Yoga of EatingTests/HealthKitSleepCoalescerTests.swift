import XCTest
@testable import Yoga_of_Eating

/// TDD tests for HealthKitSleepCoalescer — caching and in-flight query deduplication.
@MainActor
final class HealthKitSleepCoalescerTests: XCTestCase {
    private let stubSleep = SleepData(
        sleepDuration: 7 * 3600,
        timeInBed: 8 * 3600,
        sleepStart: nil,
        sleepEnd: nil,
        sleepScore: 85
    )

    // MARK: - Basic fetch behaviour

    func test_fetch_cacheMiss_executesQuery() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)
        var callCount = 0

        let result = try await coalescer.fetch(for: Date()) {
            callCount += 1
            return self.stubSleep
        }

        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(result?.sleepScore, self.stubSleep.sleepScore)
    }

    func test_fetch_cacheHit_doesNotExecuteQuery() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)
        var callCount = 0
        let date = Date()

        _ = try await coalescer.fetch(for: date) { callCount += 1
            return self.stubSleep
        }
        _ = try await coalescer.fetch(for: date) { callCount += 1
            return self.stubSleep
        }

        XCTAssertEqual(callCount, 1)
    }

    func test_fetch_expiredCache_executesQueryAgain() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 0)
        var callCount = 0
        let date = Date()

        _ = try await coalescer.fetch(for: date) { callCount += 1
            return nil
        }
        _ = try await coalescer.fetch(for: date) { callCount += 1
            return nil
        }

        XCTAssertEqual(callCount, 2)
    }

    func test_fetch_differentDates_executesSeparateQueries() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)
        var callCount = 0
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        _ = try await coalescer.fetch(for: today) { callCount += 1
            return nil
        }
        _ = try await coalescer.fetch(for: yesterday) { callCount += 1
            return nil
        }

        XCTAssertEqual(callCount, 2)
    }

    func test_fetch_returnsNilQueryResult_andCachesIt() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)
        var callCount = 0
        let date = Date()

        let r1 = try await coalescer.fetch(for: date) { callCount += 1
            return nil
        }
        let r2 = try await coalescer.fetch(for: date) { callCount += 1
            return nil
        }

        XCTAssertNil(r1)
        XCTAssertNil(r2)
        XCTAssertEqual(callCount, 1) // nil result is still cached
    }

    // MARK: - clearCache

    func test_clearCache_forcesNewQuery() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)
        var callCount = 0
        let date = Date()

        _ = try await coalescer.fetch(for: date) { callCount += 1
            return nil
        }
        coalescer.clearCache()
        _ = try await coalescer.fetch(for: date) { callCount += 1
            return nil
        }

        XCTAssertEqual(callCount, 2)
    }

    // MARK: - cacheAge

    func test_cacheAge_returnsFreshAgeAfterFetch() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)
        _ = try await coalescer.fetch(for: Date()) { nil }

        let age = coalescer.cacheAge(for: Date())
        XCTAssertNotNil(age)
        XCTAssertLessThan(age!, 1)
    }

    func test_cacheAge_returnsNilBeforeFetch() {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)
        XCTAssertNil(coalescer.cacheAge(for: Date()))
    }

    func test_cacheAge_returnsNilForExpiredEntry() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 0)
        _ = try await coalescer.fetch(for: Date()) { nil }
        XCTAssertNil(coalescer.cacheAge(for: Date()))
    }

    func test_cacheAge_returnsNilAfterClearCache() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)
        _ = try await coalescer.fetch(for: Date()) { nil }
        coalescer.clearCache()
        XCTAssertNil(coalescer.cacheAge(for: Date()))
    }

    // MARK: - In-flight coalescing (core bug fix)

    /// Three concurrent callers for the same date must produce exactly one HealthKit query.
    /// This is the regression test for the cache-stampede bug observed in production logs.
    func test_fetch_concurrentCallsForSameDate_executesQueryOnce() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)
        var queryCallCount = 0

        // Suspension point inside the query ensures concurrent callers see the in-flight task
        let slowQuery: () async throws -> SleepData? = {
            try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)
            queryCallCount += 1
            return self.stubSleep
        }

        let date = Date()
        let t1 = Task { try await coalescer.fetch(for: date, query: slowQuery) }
        let t2 = Task { try await coalescer.fetch(for: date, query: slowQuery) }
        let t3 = Task { try await coalescer.fetch(for: date, query: slowQuery) }

        _ = try await t1.value
        _ = try await t2.value
        _ = try await t3.value

        XCTAssertEqual(queryCallCount, 1, "Concurrent fetches for the same date must execute only one query")
    }

    func test_fetch_concurrentCalls_allReceiveSameResult() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)

        let slowQuery: () async throws -> SleepData? = {
            try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)
            return self.stubSleep
        }

        let date = Date()
        let t1 = Task { try await coalescer.fetch(for: date, query: slowQuery) }
        let t2 = Task { try await coalescer.fetch(for: date, query: slowQuery) }
        let t3 = Task { try await coalescer.fetch(for: date, query: slowQuery) }

        let r1 = try await t1.value
        let r2 = try await t2.value
        let r3 = try await t3.value

        XCTAssertEqual(r1?.sleepScore, self.stubSleep.sleepScore)
        XCTAssertEqual(r2?.sleepScore, self.stubSleep.sleepScore)
        XCTAssertEqual(r3?.sleepScore, self.stubSleep.sleepScore)
    }

    func test_fetch_concurrentCallsDifferentDates_executesSeparateQueries() async throws {
        let coalescer = HealthKitSleepCoalescer(cacheExpiration: 300)
        var queryCallCount = 0

        let slowQuery: () async throws -> SleepData? = {
            try await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)
            queryCallCount += 1
            return nil
        }

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let t1 = Task { try await coalescer.fetch(for: today, query: slowQuery) }
        let t2 = Task { try await coalescer.fetch(for: yesterday, query: slowQuery) }

        _ = try await t1.value
        _ = try await t2.value

        XCTAssertEqual(queryCallCount, 2, "Different dates must not coalesce into a single query")
    }
}
