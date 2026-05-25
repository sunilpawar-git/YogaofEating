import XCTest
@testable import Yoga_of_Eating

/// Tests for the time-of-day greeting computed by MainViewModel.
/// Verifies MVVM-correct placement (logic in ViewModel, not in View).
@MainActor
final class BriefingGreetingTests: XCTestCase {
    private var sut: MainViewModel!

    override func setUp() {
        super.setUp()
        self.sut = MainViewModel(
            persistenceService: MockPersistenceService(),
            skipDataLoading: true
        )
    }

    override func tearDown() {
        self.sut = nil
        super.tearDown()
    }

    func test_currentGreeting_atHour6_returnsMorning() {
        let date = self.date(hour: 6)
        XCTAssertEqual(self.sut.greeting(for: date), Strings.Briefing.greetingMorning)
    }

    func test_currentGreeting_atHour13_returnsAfternoon() {
        let date = self.date(hour: 13)
        XCTAssertEqual(self.sut.greeting(for: date), Strings.Briefing.greetingAfternoon)
    }

    func test_currentGreeting_atHour19_returnsEvening() {
        let date = self.date(hour: 19)
        XCTAssertEqual(self.sut.greeting(for: date), Strings.Briefing.greetingEvening)
    }

    func test_currentGreeting_atHour2_returnsNight() {
        let date = self.date(hour: 2)
        XCTAssertEqual(self.sut.greeting(for: date), Strings.Briefing.greetingNight)
    }

    // MARK: - Helpers

    private func date(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }
}
