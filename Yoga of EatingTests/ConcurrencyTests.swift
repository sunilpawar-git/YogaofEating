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

    // MARK: - briefingTask lifecycle

    func test_briefingTask_isStoredDuringGeneration() async {
        let vm = self.makeVM()
        // Trigger briefing generation to confirm the task is captured
        vm.triggerBriefingGeneration()
        // After triggering, the task should be non-nil (generation in progress or just started)
        XCTAssertNotNil(vm.briefingTask, "briefingTask must be stored when briefing generation is triggered")
    }

    func test_briefingTask_isCancelledOnDateChange() async {
        let vm = self.makeVM()
        vm.triggerBriefingGeneration()
        let initialTask = vm.briefingTask

        // Simulating a date navigation change should cancel the in-flight briefing task
        vm.cancelBriefingTask()

        XCTAssertEqual(
            initialTask?.isCancelled,
            true,
            "briefingTask must be cancelled when date changes during generation"
        )
    }

    // MARK: - briefingTask cancellation while in-flight (flake-proof with slow mock)

    /// Uses a slow insight service to guarantee the task is in-flight when cancellation is tested.
    /// Without this, the task may complete before the assertion fires (timing-sensitive false positive).
    func test_briefingTask_isCancelledBeforeCompletion_withSlowInsightService() async throws {
        let vm = MainViewModel(
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService(),
            insightService: SlowMockInsightGenerationService(),
            skipDataLoading: true
        )

        vm.triggerBriefingGeneration()
        let task = vm.briefingTask

        XCTAssertNotNil(task, "briefingTask must be in-flight when slow service is used")

        vm.cancelBriefingTask()

        XCTAssertEqual(task?.isCancelled, true, "briefingTask must be cancelled before it can complete")
    }
}

// MARK: - SlowMockInsightGenerationService

/// An insight service that never completes, guaranteeing the briefingTask is always in-flight
/// when cancellation tests run. Prevents false positives from timing-sensitive task completion.
@MainActor
private final class SlowMockInsightGenerationService: InsightGenerationServiceProtocol {
    func gatherDataForInsight() -> [DailySmileySnapshot] { [] }
    func createInsightPrompt(from _: [DailySmileySnapshot]) -> String { "" }
    func saveInsight(_: DailyInsight, for _: Date) {}
    func shouldGenerateInsight(for _: Date) -> Bool { true }

    func generateInsight(for _: Date, healthKitSleepData _: [Date: SleepData]) async throws -> DailyInsight? {
        // Suspend indefinitely so the task is always cancellable
        try await Task.sleep(nanoseconds: .max)
        return nil
    }

    func generateWeeklyInsight() async -> WeeklyInsight? {
        try? await Task.sleep(nanoseconds: .max)
        return nil
    }

    func generateBriefing(for _: Date, healthKitSleepData _: [Date: SleepData]) async -> DailyBriefing? {
        // Suspend indefinitely so the briefingTask is always in-flight
        try? await Task.sleep(nanoseconds: .max)
        return nil
    }
}
