import Combine
import XCTest
@testable import Yoga_of_Eating

/// Phase 3A — Protocol upgrade regression tests.
///
/// Verifies that MainViewModel no longer holds a concrete back-reference to
/// HistoricalDataService and that the DIP-compliant `setMainViewModel` path
/// is wired correctly.
@MainActor
final class MainViewModelProtocolTests: XCTestCase {
    // MARK: - Helpers

    private func makeVM(historicalService: (any HistoricalDataServiceProtocol)? = nil) -> MainViewModel {
        MainViewModel(
            persistenceService: MockPersistenceService(),
            historicalService: historicalService ?? MockHistoricalDataService(),
            skipDataLoading: true
        )
    }

    // MARK: - Protocol conformance

    func test_mainViewModel_conformsToMainViewModelProtocol() {
        let vm = self.makeVM()
        // MainViewModel must be usable wherever MainViewModelProtocol is expected.
        // This is a compile-time guarantee; the test verifies the cast succeeds at runtime.
        XCTAssertNotNil(vm as? any MainViewModelProtocol, "MainViewModel must conform to MainViewModelProtocol")
    }

    // MARK: - setMainViewModel wiring

    func test_historicalDataService_setMainViewModel_isCalledOnInit() {
        let trackingService = SetMainViewModelTrackingService()
        _ = MainViewModel(
            persistenceService: MockPersistenceService(),
            historicalService: trackingService,
            skipDataLoading: true
        )
        XCTAssertTrue(
            trackingService.setMainViewModelCalled,
            "HistoricalDataService.setMainViewModel(_:) must be called during MainViewModel.init()"
        )
    }

    func test_historicalDataService_setMainViewModel_receivesMainViewModelInstance() {
        let trackingService = SetMainViewModelTrackingService()
        let vm = MainViewModel(
            persistenceService: MockPersistenceService(),
            historicalService: trackingService,
            skipDataLoading: true
        )
        XCTAssertTrue(
            trackingService.receivedViewModel === vm,
            "setMainViewModel must receive the same MainViewModel instance that called init()"
        )
    }

    // MARK: - No concrete cast

    func test_mainViewModel_init_doesNotRequireConcreteHistoricalDataService() {
        // Using a pure mock (not HistoricalDataService concrete type) must not crash.
        // If a concrete cast is still present, it would silently skip wiring — this
        // test catches that regression by verifying setMainViewModel was called.
        let mock = SetMainViewModelTrackingService()
        _ = MainViewModel(
            persistenceService: MockPersistenceService(),
            historicalService: mock,
            skipDataLoading: true
        )
        XCTAssertTrue(
            mock.setMainViewModelCalled,
            "Protocol-based wiring must work with any HistoricalDataServiceProtocol, not just the concrete type"
        )
    }
}

// MARK: - Test-local mock

/// Tracks whether setMainViewModel(_:) is called and captures the passed instance.
@MainActor
final class SetMainViewModelTrackingService: ObservableObject, HistoricalDataServiceProtocol {
    @Published var historicalData = HistoricalData()
    var setMainViewModelCalled = false
    weak var receivedViewModel: AnyObject?

    func setMainViewModel(_ viewModel: any MainViewModelProtocol) {
        self.setMainViewModelCalled = true
        self.receivedViewModel = viewModel as AnyObject
    }

    var willChangePublisher: AnyPublisher<Void, Never> {
        self.objectWillChange.map { _ in () }.eraseToAnyPublisher()
    }

    func archiveCurrentDay(meals _: [Meal], state _: SmileyState, date _: Date) {}
    func getSnapshot(for _: Date) -> DailySmileySnapshot? { nil }
    func getYearSnapshots(year _: Int) -> [DailySmileySnapshot] { [] }
    func saveHistoricalData() {}
    func syncToFirebase() async throws {}
    func clearAllData() { self.historicalData = HistoricalData() }
    func updateReflection(for _: Date, reflection _: DailyReflection) {}
    func updateMorningMindCheck(for _: Date, entries _: [MindCheckEntry]) {}
    func updateEveningMindCheck(for _: Date, entries _: [MindCheckEntry]) {}
    func updateHighlightData(for _: Date, data _: HighlightData) {}
    func updateReflectData(for _: Date, data _: ReflectData) {}
    func updateBriefing(for _: Date, briefing _: DailyBriefing) {}
    func updateInsight(for _: Date, insight _: DailyInsight) {}
    func updateWellbeingDimensions(for _: Date, dimensions _: WellbeingDimensions, textSignals _: [TextSignal]) {}
    func updateEnrichedInsight(for _: Date, insight _: EnrichedDailyInsight) {}
    func incompleteTodosForCarryOver(from _: Date) -> [MindCheckEntry] { [] }
    func foodDebtStartingState(relativeTo _: Date) -> SmileyState { .neutral }
}
