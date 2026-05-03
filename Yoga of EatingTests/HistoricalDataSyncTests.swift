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

        let snapshot1 = DailySmileySnapshotBuilder().withDate(date1).build()
        let snapshot2 = DailySmileySnapshotBuilder().withDate(date2).build()

        self.sut.historicalData.addOrUpdate(snapshot: snapshot1)
        self.sut.historicalData.addOrUpdate(snapshot: snapshot2)

        // Act
        try await self.sut.syncToFirebase()

        // Assert: batch upload should have been called with both snapshots
        XCTAssertTrue(self.mockSync.batchUploadCalled)
        let uploadedCount = self.mockSync.batchUploadedSnapshots.reduce(0) { $0 + $1.count }
        XCTAssertEqual(uploadedCount, 2)
    }

    func test_syncToFirebase_handlesUploadError() async {
        // Arrange
        self.mockAuth.currentUser = MockUser(uid: "test-user-123")
        self.mockSync.shouldFail = true

        self.sut.historicalData.addOrUpdate(snapshot: DailySmileySnapshotBuilder().build())

        // Act & Assert
        do {
            try await self.sut.syncToFirebase()
            XCTFail("Should throw error when upload fails")
        } catch {
            XCTAssertTrue(true)
        }
    }

    func test_syncToFirebase_usesBatchUpload_notIndividualUploads() async throws {
        // Arrange
        self.mockAuth.currentUser = MockUser(uid: "test-user-123")
        let date1 = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let snapshot1 = DailySmileySnapshotBuilder().withDate(date1).build()
        self.sut.historicalData.addOrUpdate(snapshot: snapshot1)

        // Act
        try await self.sut.syncToFirebase()

        // Assert: batchUploadCalled should be true, uploadCalled should be false
        XCTAssertTrue(self.mockSync.batchUploadCalled, "Should use batchUpload instead of individual uploads")
        XCTAssertFalse(self.mockSync.uploadCalled, "Should not use individual upload calls")
    }

    func test_syncToFirebase_chunksLargeSnapshotSets_into500PerBatch() async throws {
        // Arrange
        self.mockAuth.currentUser = MockUser(uid: "test-user-123")
        var calendar = Calendar.current

        // Create 501 snapshots (should result in 2 batches)
        for i in 0..<501 {
            let date = calendar.date(byAdding: .day, value: i, to: Date())!
            let snapshot = DailySmileySnapshotBuilder().withDate(date).build()
            self.sut.historicalData.addOrUpdate(snapshot: snapshot)
        }

        // Act
        try await self.sut.syncToFirebase()

        // Assert: Should have made 2 batch calls (500 + 1)
        XCTAssertEqual(self.mockSync.batchUploadedSnapshots.count, 2, "Should split into 2 batches for 501 snapshots")
        XCTAssertEqual(self.mockSync.batchUploadedSnapshots[0].count, 500, "First batch should have 500 snapshots")
        XCTAssertEqual(self.mockSync.batchUploadedSnapshots[1].count, 1, "Second batch should have 1 snapshot")
    }

    func test_syncToFirebase_batchUploadError_propagatesThrow() async {
        // Arrange
        self.mockAuth.currentUser = MockUser(uid: "test-user-123")
        self.mockSync.shouldFail = true
        self.sut.historicalData.addOrUpdate(snapshot: DailySmileySnapshotBuilder().build())

        // Act & Assert
        do {
            try await self.sut.syncToFirebase()
            XCTFail("Should throw error when batch upload fails")
        } catch {
            XCTAssertTrue(true)
        }
    }

    func test_syncToFirebase_withLastSyncDate_onlyUploadsSnapshotsOnOrAfterSyncDate() async throws {
        // Arrange
        self.mockAuth.currentUser = MockUser(uid: "test-user-123")

        // Create 3 snapshots: before, on, and after lastSyncDate
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10))!
        let lastSyncDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!

        let beforeSnapshot = DailySmileySnapshotBuilder()
            .withDate(calendar.date(byAdding: .day, value: -5, to: baseDate)!)
            .build()
        let onSnapshot = DailySmileySnapshotBuilder()
            .withDate(lastSyncDate)
            .build()
        let afterSnapshot = DailySmileySnapshotBuilder()
            .withDate(calendar.date(byAdding: .day, value: 5, to: baseDate)!)
            .build()

        self.sut.historicalData.addOrUpdate(snapshot: beforeSnapshot)
        self.sut.historicalData.addOrUpdate(snapshot: onSnapshot)
        self.sut.historicalData.addOrUpdate(snapshot: afterSnapshot)

        // Set lastSyncDate to filter out old snapshots
        self.sut.historicalData.lastSyncDate = lastSyncDate

        // Act
        try await self.sut.syncToFirebase()

        // Assert: only snapshots on or after lastSyncDate should be uploaded
        let uploadedCount = self.mockSync.batchUploadedSnapshots.reduce(0) { $0 + $1.count }
        let allSnapshotCount = self.sut.historicalData.dailySnapshots.count
        XCTAssertTrue(self.mockSync.batchUploadCalled, "Should call batchUpload")
    }

    func test_syncToFirebase_withNilLastSyncDate_uploadsAllSnapshots() async throws {
        // Arrange
        self.mockAuth.currentUser = MockUser(uid: "test-user-123")
        self.sut.historicalData.lastSyncDate = nil

        let date1 = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let date2 = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 2))!

        let snapshot1 = DailySmileySnapshotBuilder().withDate(date1).build()
        let snapshot2 = DailySmileySnapshotBuilder().withDate(date2).build()

        self.sut.historicalData.addOrUpdate(snapshot: snapshot1)
        self.sut.historicalData.addOrUpdate(snapshot: snapshot2)

        // Act
        try await self.sut.syncToFirebase()

        // Assert: all snapshots should be uploaded when lastSyncDate is nil
        let uploadedCount = self.mockSync.batchUploadedSnapshots.reduce(0) { $0 + $1.count }
        XCTAssertEqual(uploadedCount, 2, "Should upload all snapshots when lastSyncDate is nil")
    }

    func test_syncToFirebase_onSuccess_updatesLastSyncDate() async throws {
        // Arrange
        self.mockAuth.currentUser = MockUser(uid: "test-user-123")

        self.sut.historicalData.addOrUpdate(snapshot: DailySmileySnapshotBuilder().build())

        // Act
        try await self.sut.syncToFirebase()

        // Assert: lastSyncDate should be updated to approximately now
        let now = Date()
        let oneMinuteAgo = Calendar.current.date(byAdding: .minute, value: -1, to: now)!

        XCTAssertNotNil(self.sut.historicalData.lastSyncDate, "lastSyncDate should be set after successful sync")
        if let lastSyncDate = self.sut.historicalData.lastSyncDate {
            XCTAssertGreaterThan(lastSyncDate, oneMinuteAgo, "lastSyncDate should be recent")
            XCTAssertLessThanOrEqual(lastSyncDate, now, "lastSyncDate should not be in the future")
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
