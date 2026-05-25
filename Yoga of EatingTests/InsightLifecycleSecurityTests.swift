import Foundation
import XCTest
@testable import Yoga_of_Eating

/// Security tests — auth guards at ViewModel call sites for insight generation.
/// Phase 1: these tests are RED until auth guards are added to triggerInsightGeneration()
/// and triggerEnrichedInsightGeneration() in the ViewModel.
@MainActor
final class InsightLifecycleSecurityTests: XCTestCase {
    private var sut: MainViewModel!
    private var mockInsightService: MockInsightLifecycleService!
    private var mockPersistence: MockPersistenceService!
    private var mockHistorical: MockHistoricalDataService!

    override func setUp() {
        super.setUp()
        self.mockInsightService = MockInsightLifecycleService()
        self.mockPersistence = MockPersistenceService()
        self.mockHistorical = MockHistoricalDataService()
    }

    override func tearDown() {
        self.sut = nil
        self.mockInsightService = nil
        self.mockPersistence = nil
        self.mockHistorical = nil
        super.tearDown()
    }

    func test_triggerInsightGeneration_whenUnauthenticated_doesNotCallService() async {
        let unauthService = MockAuthService()
        unauthService.currentUser = nil
        self.sut = MainViewModel(
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            insightLifecycleService: self.mockInsightService,
            authService: unauthService,
            skipDataLoading: true
        )

        self.sut.triggerInsightGeneration()
        try? await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertFalse(self.mockInsightService.generateBriefingCalled)
    }

    func test_triggerEnrichedInsightGeneration_whenUnauthenticated_doesNotCallService() async {
        let unauthService = MockAuthService()
        unauthService.currentUser = nil
        self.sut = MainViewModel(
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            insightLifecycleService: self.mockInsightService,
            authService: unauthService,
            skipDataLoading: true
        )

        self.sut.triggerEnrichedInsightGeneration(for: Date())
        try? await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertFalse(self.mockInsightService.generateEnrichedInsightCalled)
    }

    func test_triggerInsightGeneration_whenAuthenticated_callsService() async {
        let authService = MockAuthService()
        authService.currentUser = MockAuthUser(uid: "test_user_uid")
        self.sut = MainViewModel(
            persistenceService: self.mockPersistence,
            historicalService: self.mockHistorical,
            insightLifecycleService: self.mockInsightService,
            authService: authService,
            skipDataLoading: true
        )

        self.sut.triggerInsightGeneration()
        try? await Task.sleep(nanoseconds: TimingConstants.testSettleDelayNanoseconds)

        XCTAssertTrue(self.mockInsightService.generateBriefingCalled)
    }
}
