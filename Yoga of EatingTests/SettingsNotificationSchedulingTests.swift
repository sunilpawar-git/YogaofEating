import HealthKit
import XCTest
@testable import Yoga_of_Eating

/// Tests that SettingsViewModel routes notification and HealthKit calls through
/// injected protocol dependencies, not the singletons directly (DIP compliance).
@MainActor
final class SettingsNotificationSchedulingTests: XCTestCase {
    private var mockNotifScheduler: MockNotificationScheduler!
    private var mockHealthKit: MockHealthKitBodyMetricsProvider!
    private var mockHistorical: MockHistoricalDataService!
    private var mockAuth: MockAuthService!
    private var testDefaults: UserDefaults!
    private var sut: SettingsViewModel!

    override func setUp() async throws {
        try await super.setUp()
        self.mockNotifScheduler = MockNotificationScheduler()
        self.mockHealthKit = MockHealthKitBodyMetricsProvider()
        self.mockHistorical = MockHistoricalDataService()
        self.mockAuth = MockAuthService()
        self.testDefaults = UserDefaults(suiteName: "SettingsNotificationSchedulingTests.\(UUID().uuidString)")!
        self.sut = SettingsViewModel(
            historicalService: self.mockHistorical,
            authService: self.mockAuth,
            userDefaults: self.testDefaults,
            notificationScheduler: self.mockNotifScheduler,
            healthKitProvider: self.mockHealthKit
        )
        // Reset counts — init may trigger didSet observers before isFullyInitialized guards kick in.
        self.mockNotifScheduler.resetCounts()
        self.mockHealthKit.resetCounts()
    }

    override func tearDown() async throws {
        self.sut = nil
        self.testDefaults = nil
        self.mockNotifScheduler = nil
        self.mockHealthKit = nil
        self.mockHistorical = nil
        self.mockAuth = nil
        try await super.tearDown()
    }

    // MARK: - NotificationScheduling: morning nudge

    func test_enableMorningNudge_callsScheduleMorningNudgeOnInjectedScheduler() {
        self.sut.isMorningNudgeEnabled = false
        self.mockNotifScheduler.resetCounts()

        self.sut.isMorningNudgeEnabled = true

        XCTAssertEqual(
            self.mockNotifScheduler.scheduleMorningNudgeCallCount,
            1,
            "Enabling the morning nudge must call scheduleMorningNudge via the injected scheduler"
        )
    }

    func test_disableMorningNudge_callsCancelMorningNudgeOnInjectedScheduler() {
        self.sut.isMorningNudgeEnabled = true
        self.mockNotifScheduler.resetCounts()

        self.sut.isMorningNudgeEnabled = false

        XCTAssertEqual(
            self.mockNotifScheduler.cancelMorningNudgeCallCount,
            1,
            "Disabling the morning nudge must call cancelMorningNudge via the injected scheduler"
        )
    }

    func test_morningBriefingTimeChange_whenNudgeEnabled_callsScheduleMorningNudge() {
        self.sut.isMorningNudgeEnabled = true
        self.mockNotifScheduler.resetCounts()

        self.sut.morningBriefingTime = Date().addingTimeInterval(3600)

        XCTAssertEqual(
            self.mockNotifScheduler.scheduleMorningNudgeCallCount,
            1,
            "Changing briefing time while nudge is enabled must reschedule via injected scheduler"
        )
    }

    // MARK: - NotificationScheduling: meal reminders

    func test_enableMealReminders_callsScheduleDefaultMealRemindersOnInjectedScheduler() {
        self.sut.areMealRemindersEnabled = false
        self.mockNotifScheduler.resetCounts()

        self.sut.areMealRemindersEnabled = true

        XCTAssertEqual(
            self.mockNotifScheduler.scheduleDefaultMealRemindersCallCount,
            1,
            "Enabling meal reminders must call scheduleDefaultMealReminders via injected scheduler"
        )
    }

    func test_disableMealReminders_callsCancelMealRemindersOnInjectedScheduler() {
        self.sut.areMealRemindersEnabled = true
        self.mockNotifScheduler.resetCounts()

        self.sut.areMealRemindersEnabled = false

        XCTAssertEqual(
            self.mockNotifScheduler.cancelMealRemindersCallCount,
            1,
            "Disabling meal reminders must call cancelMealReminders via injected scheduler"
        )
    }

    // MARK: - HealthKitBodyMetricsProviding

    func test_syncWithHealthKit_callsRequestAuthorizationOnInjectedProvider() async throws {
        self.sut.syncWithHealthKit()
        // Allow the fire-and-forget Task to execute on the main actor.
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(
            self.mockHealthKit.requestAuthorizationCallCount,
            1,
            "syncWithHealthKit must call requestAuthorization via the injected provider"
        )
    }

    func test_syncWithHealthKit_callsFetchLatestWeightOnInjectedProvider() async throws {
        self.sut.syncWithHealthKit()
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(
            self.mockHealthKit.fetchLatestWeightCallCount,
            1,
            "syncWithHealthKit must call fetchLatestWeight via the injected provider"
        )
    }

    func test_syncWithHealthKit_whenAuthThrows_doesNotFetchMetrics() async throws {
        self.mockHealthKit.shouldThrow = true

        self.sut.syncWithHealthKit()
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(self.mockHealthKit.requestAuthorizationCallCount, 1)
        XCTAssertEqual(
            self.mockHealthKit.fetchLatestWeightCallCount,
            0,
            "fetchLatestWeight must not be called when authorization throws"
        )
    }
}
