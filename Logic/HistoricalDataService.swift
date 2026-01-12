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
    func clearAllData()

    /// Updates or adds a reflection for a specific date.
    /// If a snapshot exists for the date, adds/updates the reflection.
    /// If no snapshot exists, creates a new one with empty meals and the reflection.
    func updateReflection(for date: Date, reflection: DailyReflection)

    /// Updates or adds morning mind check entries for a specific date.
    func updateMorningMindCheck(for date: Date, entries: [MindCheckEntry])

    /// Updates or adds evening mind check entries for a specific date.
    func updateEveningMindCheck(for date: Date, entries: [MindCheckEntry])
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
    /// If a snapshot already exists for the same day, it will be updated while preserving any existing reflection.
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

        // Preserve existing reflection if snapshot already exists for this day
        let existingReflection = self.historicalData.snapshot(for: normalizedDate)?.reflection

        // Create snapshot with preserved reflection
        let snapshot = DailySmileySnapshot(
            id: UUID(),
            date: normalizedDate,
            smileyState: state,
            meals: meals,
            mealCount: meals.count,
            averageHealthScore: averageScore,
            reflection: existingReflection
        )

        // Add or update in historical data
        self.historicalData.addOrUpdate(snapshot: snapshot)

        // Persist to disk
        self.saveHistoricalData()
    }

    /// Updates or adds a reflection for a specific date.
    /// If a snapshot exists for the date, adds/updates the reflection while preserving meals.
    /// If no snapshot exists, creates a new one with empty meals and the reflection.
    func updateReflection(for date: Date, reflection: DailyReflection) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        // Check if snapshot already exists
        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            // Update existing snapshot with new reflection
            let updatedSnapshot = DailySmileySnapshot(
                id: existingSnapshot.id,
                date: existingSnapshot.date,
                smileyState: existingSnapshot.smileyState,
                meals: existingSnapshot.meals,
                mealCount: existingSnapshot.mealCount,
                averageHealthScore: existingSnapshot.averageHealthScore,
                reflection: reflection
            )
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            // Create new snapshot with reflection but empty meals
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                reflection: reflection
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }

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
        // Capture userId and snapshots upfront to prevent race conditions
        // during the async upload loop
        guard let userId = self.authService.currentUser?.uid else {
            struct AuthError: Error {}
            throw AuthError()
        }

        // Take a snapshot of the data to sync to avoid issues if data changes mid-sync
        let snapshotsToSync = self.historicalData.dailySnapshots

        // Sequential sync of all local snapshots to cloud
        for snapshot in snapshotsToSync {
            try await self.syncService.upload(snapshot: snapshot, userId: userId)
        }
    }

    /// Clears all historical data. Used for factory reset.
    func clearAllData() {
        self.historicalData = HistoricalData()
        self.lastKnownMeals = []
        self.lastKnownState = .neutral
        self.lastKnownResetDate = Date()
    }

    // MARK: - Mind Check Methods

    /// Updates or adds morning mind check entries for a specific date.
    /// If a snapshot exists for the date, adds/updates the entries while preserving other data.
    /// If no snapshot exists, creates a new one with empty meals and the entries.
    func updateMorningMindCheck(for date: Date, entries: [MindCheckEntry]) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withMindChecks(morningMindCheck: entries)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                morningMindCheck: entries
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }

        self.saveHistoricalData()
    }

    /// Updates or adds evening mind check entries for a specific date.
    /// If a snapshot exists for the date, adds/updates the entries while preserving other data.
    /// If no snapshot exists, creates a new one with empty meals and the entries.
    func updateEveningMindCheck(for date: Date, entries: [MindCheckEntry]) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withMindChecks(eveningMindCheck: entries)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                eveningMindCheck: entries
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }

        self.saveHistoricalData()
    }
}
