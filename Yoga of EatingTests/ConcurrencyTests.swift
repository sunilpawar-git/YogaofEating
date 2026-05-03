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
}
