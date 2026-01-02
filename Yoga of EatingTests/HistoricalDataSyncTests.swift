import XCTest
@testable import Yoga_of_Eating

@MainActor
final class HistoricalDataSyncTests: XCTestCase {
    var sut: HistoricalDataService!
    var mockPersistence: MockPersistenceService!
    var mockAuth: MockAuthService!
    var mockSync: MockCloudSyncService!

    override func setUp() {
        super.setUp()
        self.mockPersistence = MockPersistenceService()
        self.mockAuth = MockAuthService()
        self.mockSync = MockCloudSyncService()

        // Note: This will fail to compile until we update HistoricalDataService initializer
        self.sut = HistoricalDataService(
            persistenceService: self.mockPersistence,
            authService: self.mockAuth,
            syncService: self.mockSync
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockPersistence = nil
        self.mockAuth = nil
        self.mockSync = nil
        super.tearDown()
    }

    func test_syncToFirebase_throwsError_whenNotAuthenticated() async {
        // Arrange
        self.mockAuth.currentUser = nil

        // Act & Assert
        do {
            try await self.sut.syncToFirebase()
            XCTFail("Should throw error when not authenticated")
        } catch {
            XCTAssertTrue(true)
        }
    }

    func test_syncToFirebase_callsUpload_forAllSnapshots() async throws {
        // Arrange
        self.mockAuth.currentUser = MockUser(uid: "test-user-123")

        let date1 = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let date2 = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 2))!

        let snapshot1 = DailySmileySnapshot(
            id: UUID(),
            date: date1,
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.5
        )
        let snapshot2 = DailySmileySnapshot(
            id: UUID(),
            date: date2,
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.5
        )

        self.sut.historicalData.addOrUpdate(snapshot: snapshot1)
        self.sut.historicalData.addOrUpdate(snapshot: snapshot2)

        // Act
        try await self.sut.syncToFirebase()

        // Assert
        XCTAssertTrue(self.mockSync.uploadCalled)
        XCTAssertEqual(self.mockSync.uploadedSnapshots.count, 2)
    }

    func test_syncToFirebase_handlesUploadError() async {
        // Arrange
        self.mockAuth.currentUser = MockUser(uid: "test-user-123")
        self.mockSync.shouldFail = true

        self.sut.historicalData.addOrUpdate(snapshot: DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.5
        ))

        // Act & Assert
        do {
            try await self.sut.syncToFirebase()
            XCTFail("Should throw error when upload fails")
        } catch {
            XCTAssertTrue(true)
        }
    }
}

// Helper to mock Firebase User
class MockUser: NSObject, AuthUser {
    let uid: String
    var displayName: String? = "Mock User"
    var email: String? = "mock@example.com"

    init(uid: String) { self.uid = uid }
}
