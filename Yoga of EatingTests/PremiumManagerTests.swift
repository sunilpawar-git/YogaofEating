import XCTest
@testable import Yoga_of_Eating

@MainActor
final class PremiumManagerTests: XCTestCase {
    func test_default_isNotPremium() {
        let manager = PremiumManager()
        XCTAssertFalse(manager.isPremium)
    }

    func test_setPremiumForTesting_updatesState() {
        let manager = PremiumManager()
        manager.setPremiumForTesting(true)
        XCTAssertTrue(manager.isPremium)
    }
}
