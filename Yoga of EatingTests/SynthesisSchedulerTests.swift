import XCTest

@testable import Yoga_of_Eating

@MainActor
final class SynthesisSchedulerTests: XCTestCase {
    // MARK: - Debounce Collapsing

    func test_schedule_rapidTriggersInDebounceWindow_produceSingleCall() async throws {
        var handlerCalls: [SynthesisTrigger] = []
        let scheduler = SynthesisScheduler(debounceNanoseconds: 1_000_000) { trigger in
            handlerCalls.append(trigger)
        }

        scheduler.schedule(.mealUpdated)
        scheduler.schedule(.mealUpdated)
        scheduler.schedule(.mealUpdated)

        try await Task.sleep(nanoseconds: 10_000_000) // 10ms — well past 1ms debounce
        XCTAssertEqual(handlerCalls.count, 1)
        XCTAssertEqual(handlerCalls.first, .mealUpdated)
    }

    func test_schedule_differentTriggersInWindow_lastTriggerWins() async throws {
        var handlerCalls: [SynthesisTrigger] = []
        let scheduler = SynthesisScheduler(debounceNanoseconds: 1_000_000) { trigger in
            handlerCalls.append(trigger)
        }

        scheduler.schedule(.mealUpdated)
        scheduler.schedule(.journalSaved)
        scheduler.schedule(.feelingUpdated)

        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertEqual(handlerCalls.count, 1)
        XCTAssertEqual(handlerCalls.first, .feelingUpdated)
    }

    func test_schedule_triggerAfterDebounceWindow_producesTwoSeparateCalls() async throws {
        var handlerCalls: [SynthesisTrigger] = []
        let scheduler = SynthesisScheduler(debounceNanoseconds: 1_000_000) { trigger in
            handlerCalls.append(trigger)
        }

        scheduler.schedule(.mealUpdated)
        try await Task.sleep(nanoseconds: 10_000_000) // Wait for first debounce to fire

        scheduler.schedule(.journalSaved)
        try await Task.sleep(nanoseconds: 10_000_000) // Wait for second debounce to fire

        XCTAssertEqual(handlerCalls.count, 2)
        XCTAssertEqual(handlerCalls[0], .mealUpdated)
        XCTAssertEqual(handlerCalls[1], .journalSaved)
    }

    // MARK: - Sleep Trigger Bypass

    func test_schedule_sleepLogged_bypassesDebounce() async throws {
        var handlerCalls: [SynthesisTrigger] = []
        // Large debounce that would never fire in test time normally
        let scheduler = SynthesisScheduler(debounceNanoseconds: 60_000_000_000) { trigger in
            handlerCalls.append(trigger)
        }

        scheduler.schedule(.sleepLogged)

        try await Task.sleep(nanoseconds: 10_000_000) // 10ms — debounce would be 60s
        XCTAssertEqual(handlerCalls.count, 1)
        XCTAssertEqual(handlerCalls.first, .sleepLogged)
    }

    func test_schedule_sleepLogged_alwaysFiresRegardlessOfPendingTask() async throws {
        var handlerCalls: [SynthesisTrigger] = []
        let scheduler = SynthesisScheduler(debounceNanoseconds: 60_000_000_000) { trigger in
            handlerCalls.append(trigger)
        }

        // Queue a long-debounce trigger, then immediately follow with sleepLogged
        scheduler.schedule(.mealUpdated)
        scheduler.schedule(.sleepLogged)

        try await Task.sleep(nanoseconds: 10_000_000)
        // Only sleepLogged fires (it replaced + bypassed the mealUpdated debounce)
        XCTAssertEqual(handlerCalls.count, 1)
        XCTAssertEqual(handlerCalls.first, .sleepLogged)
    }

    // MARK: - Task Cancellation

    func test_schedule_newTrigger_cancelsPreviousPendingTask() async throws {
        var handlerCalls: [SynthesisTrigger] = []
        let scheduler = SynthesisScheduler(debounceNanoseconds: 1_000_000) { trigger in
            handlerCalls.append(trigger)
        }

        scheduler.schedule(.mealUpdated)
        // Immediately cancel by scheduling a new trigger
        scheduler.schedule(.morningThoughtsChanged)

        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertEqual(handlerCalls.count, 1)
        // First trigger was cancelled; only second fires
        XCTAssertEqual(handlerCalls.first, .morningThoughtsChanged)
    }

    // MARK: - All Trigger Types

    func test_schedule_allNonSleepTriggers_respectDebounce() async throws {
        let nonSleepTriggers: [SynthesisTrigger] = [
            .mealUpdated, .journalSaved, .todoCompleted, .feelingUpdated, .morningThoughtsChanged
        ]
        for trigger in nonSleepTriggers {
            var handlerCalls: [SynthesisTrigger] = []
            let scheduler = SynthesisScheduler(debounceNanoseconds: 1_000_000) { t in
                handlerCalls.append(t)
            }

            scheduler.schedule(trigger)
            scheduler.schedule(trigger) // rapid duplicate

            try await Task.sleep(nanoseconds: 10_000_000)
            XCTAssertEqual(handlerCalls.count, 1, "Trigger \(trigger) should debounce to one call")
        }
    }
}
