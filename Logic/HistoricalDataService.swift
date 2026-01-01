import Combine
import Foundation

/// Protocol defining the interface for historical data management.
@MainActor
protocol HistoricalDataServiceProtocol: ObservableObject {
    var historicalData: HistoricalData { get set }
    func archiveCurrentDay(meals: [Meal], state: SmileyState, date: Date)
    func getSnapshot(for date: Date) -> DailySmileySnapshot?
    func getYearSnapshots(year: Int) -> [DailySmileySnapshot]
    func saveHistoricalData()
    func syncToFirebase() async throws
}

/// Service for managing historical meal data and daily snapshots.
/// Handles archival, retrieval, and optional cloud synchronization.
@MainActor
class HistoricalDataService: HistoricalDataServiceProtocol {
    // MARK: - Properties

    @Published var historicalData: HistoricalData
    private let persistenceService: PersistenceServiceProtocol
    private let authService: any AuthServiceProtocol
    private let syncService: any CloudSyncServiceProtocol

    // Cache for saving entire AppData structure
    private var lastKnownMeals: [Meal] = []
    private var lastKnownState: SmileyState = .neutral
    private var lastKnownResetDate: Date = .init()

    // MARK: - Initialization

    init(
        persistenceService: PersistenceServiceProtocol? = nil,
        authService: (any AuthServiceProtocol)? = nil,
        syncService: (any CloudSyncServiceProtocol)? = nil
    ) {
        let resolvedPersistence = persistenceService ?? PersistenceService.shared
        self.persistenceService = resolvedPersistence
        self.authService = authService ?? AuthService.shared
        self.syncService = syncService ?? CloudSyncService()

        // Load existing historical data from persistence
        if let savedData = resolvedPersistence.load() {
            self.historicalData = savedData.historicalData
            self.lastKnownMeals = savedData.meals
            self.lastKnownState = savedData.smileyState
            self.lastKnownResetDate = savedData.lastResetDate
        } else {
            self.historicalData = HistoricalData()
        }
    }

    // MARK: - Archival Methods

    /// Archives the current day's meals and smiley state as a snapshot.
    /// If a snapshot already exists for the same day, it will be updated.
    func archiveCurrentDay(meals: [Meal], state: SmileyState, date: Date) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        // Update caches for persistence
        self.lastKnownMeals = meals
        self.lastKnownState = state

        // Calculate average health score
        let averageScore: Double
        if meals.isEmpty {
            averageScore = 0.5 // Default for empty days
        } else {
            let totalScore = meals.map(\.healthScore).reduce(0, +)
            averageScore = totalScore / Double(meals.count)
        }

        // Create snapshot
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: normalizedDate,
            smileyState: state,
            meals: meals,
            mealCount: meals.count,
            averageHealthScore: averageScore
        )

        // Add or update in historical data
        self.historicalData.addOrUpdate(snapshot: snapshot)

        // Persist to disk
        self.saveHistoricalData()
    }

    // MARK: - Retrieval Methods

    /// Returns the snapshot for a specific date, or nil if not found.
    func getSnapshot(for date: Date) -> DailySmileySnapshot? {
        self.historicalData.snapshot(for: date)
    }

    /// Returns all snapshots for a specific year.
    /// Only returns snapshots that actually exist (not placeholder empty snapshots).
    func getYearSnapshots(year: Int) -> [DailySmileySnapshot] {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: year, month: 1, day: 1)
        let endComponents = DateComponents(year: year, month: 12, day: 31)

        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents)
        else {
            return []
        }

        return self.historicalData.snapshots(in: startDate...endDate)
    }

    // MARK: - Persistence Methods

    /// Saves historical data to persistent storage.
    /// This is called automatically after archiving, but can be called manually if needed.
    func saveHistoricalData() {
        self.persistenceService.save(
            meals: self.lastKnownMeals,
            smileyState: self.lastKnownState,
            lastResetDate: self.lastKnownResetDate,
            historicalData: self.historicalData
        )
    }

    /// Loads historical data from persistent storage.
    /// This is called automatically during initialization.
    func loadHistoricalData() -> HistoricalData {
        if let savedData = persistenceService.load() {
            savedData.historicalData
        } else {
            HistoricalData()
        }
    }

    // MARK: - Cloud Sync Methods

    /// Synchronizes historical data to Firebase.
    /// Requires an authenticated user.
    func syncToFirebase() async throws {
        guard let userId = self.authService.currentUser?.uid else {
            struct AuthError: Error {}
            throw AuthError()
        }

        // Sequential sync of all local snapshots to cloud
        for snapshot in self.historicalData.dailySnapshots {
            try await self.syncService.upload(snapshot: snapshot, userId: userId)
        }
    }
}
