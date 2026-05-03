// swiftlint:disable force_unwrapping
#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    /// Tests for HistoricalSyncService — the extracted sync responsibility from HistoricalDataService.
    /// RED tests written before HistoricalSyncService.swift exists.
    @MainActor
    final class HistoricalSyncServiceTests: XCTestCase {
        var mockAuth: MockAuthService!
        var mockSync: MockCloudSyncService!
        var sut: HistoricalSyncService!

        private func makeSnapshot(daysAgo: Int, score _: Double = 0.7) -> DailySmileySnapshot {
            DailySmileySnapshotBuilder()
                .daysAgo(daysAgo)
                .withSmileyState(.neutral)
                .build()
        }

        private func makeSut(
            snapshots: [DailySmileySnapshot] = [],
            lastSyncDate: Date? = nil,
            onSyncCompleted: @escaping @MainActor (Date) -> Void = { _ in }
        ) -> HistoricalSyncService {
            HistoricalSyncService(
                authService: self.mockAuth,
                syncService: self.mockSync,
                snapshotsProvider: { snapshots },
                lastSyncDateProvider: { lastSyncDate },
                onSyncCompleted: onSyncCompleted
            )
        }

        override func setUp() {
            super.setUp()
            self.mockAuth = MockAuthService()
            self.mockSync = MockCloudSyncService()
        }

        override func tearDown() {
            self.sut = nil
            self.mockAuth = nil
            self.mockSync = nil
            super.tearDown()
        }

        // MARK: - Auth guard

        func test_sync_throwsSyncAuthRequired_whenNoUser() async {
            self.mockAuth.currentUser = nil
            var callbackFired = false
            self.sut = self.makeSut(snapshots: [self.makeSnapshot(daysAgo: 1)]) { _ in callbackFired = true }

            do {
                try await self.sut.sync()
                XCTFail("Expected syncAuthRequired error")
            } catch AppError.syncAuthRequired {
                // Correct — expected error
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
            XCTAssertFalse(callbackFired, "onSyncCompleted must not fire when auth fails")
        }

        // MARK: - Full sync (no lastSyncDate)

        func test_sync_uploadsAllSnapshots_whenNoLastSyncDate() async throws {
            self.mockAuth.currentUser = MockAuthUser(uid: "user1", displayName: nil, email: nil)
            let snapshots = [makeSnapshot(daysAgo: 2), makeSnapshot(daysAgo: 1)]
            self.sut = self.makeSut(snapshots: snapshots)

            try await self.sut.sync()

            XCTAssertTrue(self.mockSync.batchUploadCalled)
            XCTAssertEqual(self.mockSync.batchUploadedSnapshots.flatMap(\.self).count, 2)
        }

        // MARK: - Delta sync (lastSyncDate set)

        func test_sync_uploadsOnlyRecentSnapshots_whenLastSyncDateSet() async throws {
            self.mockAuth.currentUser = MockAuthUser(uid: "user1", displayName: nil, email: nil)
            let oldSnap = self.makeSnapshot(daysAgo: 10)
            let recentSnap = self.makeSnapshot(daysAgo: 1)
            let lastSync = Calendar.current.date(byAdding: .day, value: -3, to: Date())!

            self.sut = self.makeSut(snapshots: [oldSnap, recentSnap], lastSyncDate: lastSync)

            try await self.sut.sync()

            let uploaded = self.mockSync.batchUploadedSnapshots.flatMap(\.self)
            XCTAssertEqual(uploaded.count, 1)
            XCTAssertEqual(uploaded.first?.id, recentSnap.id)
        }

        // MARK: - Callback fires on success

        func test_sync_callsOnSyncCompleted_afterSuccessfulUpload() async throws {
            self.mockAuth.currentUser = MockAuthUser(uid: "user1", displayName: nil, email: nil)
            var completedDate: Date?
            self.sut = self.makeSut(
                snapshots: [self.makeSnapshot(daysAgo: 1)],
                onSyncCompleted: { date in completedDate = date }
            )

            try await self.sut.sync()

            XCTAssertNotNil(completedDate, "onSyncCompleted must be called after a successful upload")
        }

        // MARK: - Upload failure propagates

        func test_sync_doesNotCallOnSyncCompleted_whenUploadFails() async {
            self.mockAuth.currentUser = MockAuthUser(uid: "user1", displayName: nil, email: nil)
            self.mockSync.shouldFail = true
            var callbackFired = false
            self.sut = self.makeSut(
                snapshots: [self.makeSnapshot(daysAgo: 1)],
                onSyncCompleted: { _ in callbackFired = true }
            )

            do {
                try await self.sut.sync()
                XCTFail("Expected error from failed upload")
            } catch {
                // Expected — upload throws
            }
            XCTAssertFalse(callbackFired, "onSyncCompleted must not fire when upload fails")
        }
    }

#endif
