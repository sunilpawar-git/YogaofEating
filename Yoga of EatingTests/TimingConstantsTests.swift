import XCTest
@testable import Yoga_of_Eating

final class TimingConstantsTests: XCTestCase {
    func test_dayResetPollIntervalNanoseconds_isPositive() {
        XCTAssertGreaterThan(TimingConstants.dayResetPollIntervalNanoseconds, 0)
    }

    func test_dayResetPollIntervalNanoseconds_isAtLeastTenSeconds() {
        // Reset polling faster than 10s would be wasteful
        XCTAssertGreaterThanOrEqual(TimingConstants.dayResetPollIntervalNanoseconds, 10_000_000_000)
    }

    func test_dayResetPollIntervalNanoseconds_isUnderFiveMinutes() {
        // 5 minutes = 300_000_000_000 nanoseconds
        XCTAssertLessThan(TimingConstants.dayResetPollIntervalNanoseconds, 300_000_000_000)
    }

    func test_syncSuccessDisplayNanoseconds_isPositive() {
        XCTAssertGreaterThan(TimingConstants.syncSuccessDisplayNanoseconds, 0)
    }

    func test_syncErrorDisplayNanoseconds_isGreaterThanSuccessDisplay() {
        XCTAssertGreaterThan(
            TimingConstants.syncErrorDisplayNanoseconds,
            TimingConstants.syncSuccessDisplayNanoseconds
        )
    }

    func test_syncRetryDelayNanoseconds_isPositive() {
        XCTAssertGreaterThan(TimingConstants.syncRetryDelayNanoseconds, 0)
    }

    func test_syncMaxRetryAttempts_isAtLeastOne() {
        XCTAssertGreaterThanOrEqual(TimingConstants.syncMaxRetryAttempts, 1)
    }
}
