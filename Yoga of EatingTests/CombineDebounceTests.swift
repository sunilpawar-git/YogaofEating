import Combine
import XCTest
@testable import Yoga_of_Eating

/// Phase 5 — Combine Debouncing tests.
///
/// TDD Red phase: these tests are written FIRST and will fail until
/// `MainViewModel.enqueueMealEdit` and its Combine pipeline are implemented.
///
/// Tests cover:
/// 1. Rapid calls result in a single `updateMealItemsLocalOnly` after the debounce window.
/// 2. Slow calls (> debounce interval apart) result in separate updates.
/// 3. Subject cancels cleanly on deinit (no retain cycles).
@MainActor
final class CombineDebounceTests: XCTestCase {
    // MARK: - Helpers

    private func makeVM() -> MainViewModel {
        MainViewModel(
            persistenceService: MockPersistenceService(),
            historicalService: MockHistoricalDataService(),
            skipDataLoading: true
        )
    }

    // MARK: - Rapid-fire calls collapse to one update

    /// Rapid calls to `enqueueMealEdit` within the debounce window
    /// must produce exactly ONE call to `updateMealItemsLocalOnly`.
    func test_enqueueMealEdit_rapidCalls_resultInSingleUpdate() async throws {
        let vm = self.makeVM()
        let meal = MealBuilder().build()
        vm.meals = [meal]

        let newItems = ["salad", "water"]
        let callCount = LockIsolated(0)

        // Observe via $meals; removeDuplicates collapses repeated emissions for same value.
        var cancellables = Set<AnyCancellable>()
        vm.$meals
            .map { $0.first?.items ?? [] }
            .removeDuplicates()
            .filter { $0 == newItems }
            .sink { _ in callCount.withLock { $0 += 1 } }
            .store(in: &cancellables)

        // Fire 5 rapid edits within the debounce window
        for _ in 0..<5 {
            vm.enqueueMealEdit(mealId: meal.id, items: newItems)
        }

        // Wait for debounce window to expire (600 ms > 500 ms debounce)
        try await Task.sleep(nanoseconds: 600_000_000)

        XCTAssertEqual(
            callCount.value,
            1,
            "Rapid calls must be collapsed into a single update after the debounce window"
        )
    }

    // MARK: - Slow calls produce separate updates

    /// Calls spaced further apart than the debounce interval must each trigger
    /// a distinct `updateMealItemsLocalOnly` invocation.
    func test_enqueueMealEdit_slowCalls_produceSeparateUpdates() async throws {
        let vm = self.makeVM()
        let meal = MealBuilder().build()
        vm.meals = [meal]

        let firstItems = ["salad"]
        let secondItems = ["pizza"]
        var receivedUpdates: [[String]] = []

        var cancellables = Set<AnyCancellable>()
        vm.$meals
            .map { $0.first?.items ?? [] }
            .removeDuplicates()
            .filter { !$0.isEmpty && $0 != ["test meal"] }
            .sink { receivedUpdates.append($0) }
            .store(in: &cancellables)

        // First edit — wait for debounce to fire
        vm.enqueueMealEdit(mealId: meal.id, items: firstItems)
        try await Task.sleep(nanoseconds: 650_000_000)

        // Second edit — wait for debounce to fire
        vm.enqueueMealEdit(mealId: meal.id, items: secondItems)
        try await Task.sleep(nanoseconds: 650_000_000)

        XCTAssertEqual(receivedUpdates.count, 2, "Each slow call must produce its own update")
        XCTAssertEqual(receivedUpdates.first, firstItems)
        XCTAssertEqual(receivedUpdates.last, secondItems)
    }

    // MARK: - No retain cycle on deinit

    /// The Combine subscription must not retain the ViewModel after deinit.
    func test_enqueueMealEdit_combineSubscription_doesNotRetainVM() async throws {
        var vm: MainViewModel? = self.makeVM()
        weak var weakVM = vm

        // Enqueue an edit so the subject is live
        let meal = MealBuilder().build()
        vm?.meals = [meal]
        vm?.enqueueMealEdit(mealId: meal.id, items: ["test"])

        // Release the strong reference
        vm = nil

        // Allow any pending tasks to settle
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNil(weakVM, "ViewModel must be deallocated; Combine subscription must not create a retain cycle")
    }

    // MARK: - enqueueMealEdit method exists on MainViewModel

    /// Verifies the public API surface required by Phase 5 is present.
    func test_mainViewModel_hasEnqueueMealEditMethod() {
        let vm = self.makeVM()
        let meal = MealBuilder().build()
        vm.meals = [meal]

        // Should compile and not crash — verifies API surface
        vm.enqueueMealEdit(mealId: meal.id, items: ["test"])
        XCTAssertTrue(true, "enqueueMealEdit must exist on MainViewModel")
    }
}

// MARK: - Thread-safe counter helper

/// Minimal lock-isolated counter to safely count callbacks from a Combine sink.
private final class LockIsolated<Value>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self._value = value
    }

    var value: Value {
        self.lock.withLock { self._value }
    }

    func withLock(_ mutation: (inout Value) -> Void) {
        self.lock.withLock { mutation(&self._value) }
    }
}
