import XCTest
@testable import Yoga_of_Eating

/// Phase 2 — Async/Concurrency Hardening tests.
///
/// Tests describe the desired behaviour of tracked Tasks and
/// proper Task lifecycle management.
@MainActor
final class ConcurrencyTests: XCTestCase {
    // MARK: - Helpers

    /// VM without data loading (for tests that don't need monitoring started)
    private func makeVM() -> MainViewModel {
        MainViewModel(skipDataLoading: true)
    }

    /// VM with data loading enabled (monitoring loop is started, uses mock persistence)
    private func makeVMWithMonitoring() -> MainViewModel {
        MainViewModel(
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService(),
            skipDataLoading: false
        )
    }

    // MARK: - resetMonitorTask lifecycle

    func test_setupResetMonitoring_storesTask() {
        let vm = self.makeVMWithMonitoring()
        // resetMonitorTask must be stored so it can be cancelled on deinit.
        XCTAssertNotNil(vm.resetMonitorTask, "resetMonitorTask must be non-nil after loadData/setupResetMonitoring")
    }

    func test_resetMonitorTask_isCancelledAfterDeinit() async {
        var task: Task<Void, Never>?
        do {
            let vm = self.makeVMWithMonitoring()
            task = vm.resetMonitorTask
            XCTAssertNotNil(task, "precondition: resetMonitorTask must be set before deinit check")
        }
        // vm has been deallocated; give the event loop a tick to run deinit
        await Task.yield()
        XCTAssertEqual(task?.isCancelled, true, "resetMonitorTask must be cancelled when MainViewModel is deallocated")
    }

    // MARK: - sleepBadgeTask lifecycle

    func test_sleepBadgeTask_isNilBeforeFetch() {
        let vm = self.makeVM()
        XCTAssertNil(vm.sleepBadgeTask, "sleepBadgeTask should be nil before any fetch is requested")
    }

    // MARK: - insightTask lifecycle

    func test_insightTask_isStoredDuringGeneration() async {
        let vm = self.makeVM()
        vm.triggerInsightGeneration()
        XCTAssertNotNil(vm.insightTask, "insightTask must be stored when insight generation is triggered")
    }

    func test_insightTask_isCancelledOnRequest() async {
        let vm = self.makeVM()
        vm.triggerInsightGeneration()
        let initialTask = vm.insightTask

        vm.cancelInsightTask()

        XCTAssertEqual(
            initialTask?.isCancelled,
            true,
            "insightTask must be cancellable"
        )
    }

    // MARK: - insightTask cancellation while in-flight (flake-proof with slow mock)

    func test_insightTask_isCancelledBeforeCompletion_withSlowLifecycleService() async throws {
        let slowMock = SlowMockInsightLifecycleService()
        let vm = MainViewModel(
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService(),
            insightLifecycleService: slowMock,
            skipDataLoading: true
        )

        vm.triggerInsightGeneration()
        let task = vm.insightTask

        XCTAssertNotNil(task, "insightTask must be in-flight when slow service is used")

        vm.cancelInsightTask()

        XCTAssertEqual(task?.isCancelled, true, "insightTask must be cancelled before it can complete")
    }
}

// MARK: - SlowMockInsightLifecycleService

@MainActor
private final class SlowMockInsightLifecycleService: InsightLifecycling {
    func generateEnrichedInsight(
        for _: Date, synthesis _: DailySynthesis,
        recentSnapshots _: [DailySmileySnapshot],
        healthKitSleepData _: [Date: SleepData]
    ) async -> DailyInsight? { nil }

    func generateBriefing(for _: Date, healthKitSleepData _: [Date: SleepData]) async -> DailyInsight? {
        try? await Task.sleep(nanoseconds: .max)
        return nil
    }
}
