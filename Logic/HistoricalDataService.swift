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

    /// Updates or adds highlight data for a specific date.
    func updateHighlightData(for date: Date, data: HighlightData)

    /// Updates or adds reflect data for a specific date.
    func updateReflectData(for date: Date, data: ReflectData)

    /// Updates or adds a morning briefing for a specific date.
    func updateBriefing(for date: Date, briefing: DailyBriefing)

    /// Returns incomplete .todo entries from the given date's snapshot, each with
    /// carriedOverCount incremented by 1. Used by resetDay() to seed the next day's todos.
    func incompleteTodosForCarryOver(from date: Date) -> [MindCheckEntry]

    /// Returns .concerned if the two most recent days with meals both scored below
    /// ScoringThresholds.foodDebtBadDay; otherwise returns .neutral.
    /// Used by resetDay() to set the smiley's starting state.
    func foodDebtStartingState(relativeTo date: Date) -> SmileyState
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

    // Weak back-reference to MainViewModel so saveHistoricalData() always uses
    // the authoritative meals / state / resetDate rather than stale caches.
    // Set by MainViewModel immediately after init.
    weak var mainViewModel: MainViewModel?

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

        // Calculate average health score
        let averageScore: Double
        if meals.isEmpty {
            averageScore = 0.5 // Default for empty days
        } else {
            let totalScore = meals.map(\.healthScore).reduce(0, +)
            averageScore = totalScore / Double(meals.count)
        }

        // Preserve existing data if snapshot already exists for this day
        let existing = self.historicalData.snapshot(for: normalizedDate)
        let existingReflection = existing?.reflection
        // Re-use the existing snapshot ID so cloud sync can identify the same day.
        // Fall back to a stable UUID derived from the ISO date string so new days
        // also get a consistent identity across calls.
        let stableId = existing?.id ?? UUID(uuidString: Self.stableUUIDString(for: normalizedDate)) ?? UUID()

        // Create snapshot preserving all per-day user data
        let snapshot = DailySmileySnapshot(
            id: stableId,
            date: normalizedDate,
            smileyState: state,
            meals: meals,
            mealCount: meals.count,
            averageHealthScore: averageScore,
            reflection: existingReflection,
            morningMindCheck: existing?.morningMindCheck,
            eveningMindCheck: existing?.eveningMindCheck,
            highlightData: existing?.highlightData,
            reflectData: existing?.reflectData,
            briefing: existing?.briefing
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
            let updatedSnapshot = existingSnapshot.withReflection(reflection)
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

    /// Saves historical data to persistent storage by delegating to the canonical
    /// save path in MainViewModel (which holds the authoritative meals/state/resetDate).
    /// Falls back to a history-only save when MainViewModel is not wired up yet.
    func saveHistoricalData() {
        if let vm = mainViewModel {
            vm.saveData()
        } else {
            // Fallback path: called before MainViewModel wires itself (e.g. during init)
            // or in unit tests where no MainViewModel exists.
            // Read current persisted state for meals/smiley; fall back to empty defaults
            // so historical data is always persisted even when load() returns nil.
            let existing = self.persistenceService.load()
            self.persistenceService.save(
                meals: existing?.meals ?? [],
                smileyState: existing?.smileyState ?? .neutral,
                lastResetDate: existing?.lastResetDate ?? Date(),
                historicalData: self.historicalData
            )
        }
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
    }

    // MARK: - Private Helpers

    /// Produces a deterministic UUID-shaped string from an ISO date string so that
    /// the same calendar day always maps to the same snapshot UUID, enabling
    /// idempotent cloud uploads and deduplication.
    private static func stableUUIDString(for date: Date) -> String {
        let iso = ISO8601DateFormatter().string(from: date)
        // Simple 32-char hex derived from string hash to form a valid UUID
        let hash = iso.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { acc, byte in
            (acc ^ UInt64(byte)) &* 1_099_511_628_211
        }
        let hex = String(format: "%016llx", hash) + String(format: "%016llx", hash &+ 1)
        let u = Array(hex)
        return "\(String(u[0..<8]))-\(String(u[8..<12]))-4\(String(u[13..<16]))-8\(String(u[17..<20]))-\(String(u[20..<32]))"
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

    // MARK: - Highlight & Reflect Data Methods

    func updateHighlightData(for date: Date, data: HighlightData) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withHighlightData(data)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                highlightData: data
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }

        self.saveHistoricalData()
    }

    func updateReflectData(for date: Date, data: ReflectData) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withReflectData(data)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                reflectData: data
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }

        self.saveHistoricalData()
    }

    func updateBriefing(for date: Date, briefing: DailyBriefing) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existingSnapshot = self.historicalData.snapshot(for: normalizedDate) {
            let updatedSnapshot = existingSnapshot.withBriefing(briefing)
            self.historicalData.addOrUpdate(snapshot: updatedSnapshot)
        } else {
            let newSnapshot = DailySmileySnapshot(
                id: UUID(),
                date: normalizedDate,
                smileyState: .neutral,
                meals: [],
                mealCount: 0,
                averageHealthScore: 0.5,
                briefing: briefing
            )
            self.historicalData.addOrUpdate(snapshot: newSnapshot)
        }

        self.saveHistoricalData()
    }

    // MARK: - Todo Carry-Over

    func incompleteTodosForCarryOver(from date: Date) -> [MindCheckEntry] {
        guard let todos = self.getSnapshot(for: date)?.highlightData?.todos else { return [] }
        return todos
            .filter { $0.category == .todo && $0.isAccomplished != true }
            .map { $0.withCarriedOverCount($0.carriedOverCount + 1) }
    }

    // MARK: - Food Debt Starting State

    func foodDebtStartingState(relativeTo date: Date) -> SmileyState {
        let calendar = Calendar.current
        guard
            let d1 = calendar.date(byAdding: .day, value: -1, to: date),
            let d2 = calendar.date(byAdding: .day, value: -2, to: date),
            let s1 = self.getSnapshot(for: d1),
            s1.mealCount > 0,
            s1.averageHealthScore < ScoringThresholds.foodDebtBadDay,
            let s2 = self.getSnapshot(for: d2),
            s2.mealCount > 0,
            s2.averageHealthScore < ScoringThresholds.foodDebtBadDay
        else { return .neutral }
        return .concerned
    }
}
