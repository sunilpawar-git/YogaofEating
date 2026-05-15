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

    /// Wires the back-reference from this service to the view model's save path.
    /// Called by MainViewModel.init() immediately after the service is stored.
    /// Conformers use this reference via `MainViewModelProtocol` to avoid a DIP
    /// violation (no concrete HistoricalDataService cast in MainViewModel.init).
    func setMainViewModel(_ viewModel: any MainViewModelProtocol)

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

    /// Updates or stores the unified daily insight for a specific date.
    func updateInsight(for date: Date, insight: DailyInsight)

    /// Updates or adds wellbeing dimensions and text signals for a specific date.
    func updateWellbeingDimensions(for date: Date, dimensions: WellbeingDimensions, textSignals: [TextSignal])

    /// Downloads all snapshots from Firebase and merges them into local storage.
    /// Throws `AppError.syncAuthRequired` when not authenticated.
    /// No-op when the cloud returns no data; saves to disk after a successful restore.
    /// No-op (silent early return) when a restore is already in progress.
    func restoreFromFirebase() async throws

    /// Whether a cloud restore operation is currently in progress.
    /// Guard: a second concurrent restore call returns immediately without re-fetching.
    var isRestoreInProgress: Bool { get }

    /// Whether a cloud sync (upload) operation is currently in progress.
    /// Exposed on the protocol for settings-UI binding and concurrency guards.
    var isSyncInProgress: Bool { get }

    /// Returns incomplete .todo entries from the given date's snapshot, each with
    /// carriedOverCount incremented by 1. Used by resetDay() to seed the next day's todos.
    func incompleteTodosForCarryOver(from date: Date) -> [MindCheckEntry]

    /// Returns .concerned if the two most recent days with meals both scored below
    /// ScoringThresholds.foodDebtBadDay; otherwise returns .neutral.
    /// Used by resetDay() to set the smiley's starting state.
    func foodDebtStartingState(relativeTo date: Date) -> SmileyState

    /// Type-erased publisher that fires whenever the service's state changes.
    /// Allows MainViewModel to subscribe to historical-service mutations via the
    /// protocol existential, without needing a concrete cast to access `objectWillChange`.
    var willChangePublisher: AnyPublisher<Void, Never> { get }
}

/// Service for managing historical meal data and daily snapshots.
/// Handles archival and retrieval only. Cloud sync is delegated to `HistoricalSyncService`.
@MainActor
class HistoricalDataService: HistoricalDataServiceProtocol {
    // MARK: - Properties

    @Published var historicalData: HistoricalData
    /// Set to `true` while a restore is in progress; cleared via `defer` on exit.
    /// Written only by `restoreFromFirebase()` — do not mutate from outside the service.
    @Published var isRestoreInProgress = false
    /// Set to `true` while a sync upload is in progress; cleared via `defer` on exit.
    /// Written only by `syncToFirebase()` — do not mutate from outside the service.
    @Published var isSyncInProgress = false
    let persistenceService: PersistenceServiceProtocol
    let syncHandler: HistoricalSyncService

    // Weak back-reference to MainViewModelProtocol so saveHistoricalData() always uses
    // the authoritative meals / state / resetDate rather than stale caches.
    // Set via setMainViewModel(_:) called by MainViewModel immediately after init.
    // Typed as protocol to satisfy DIP — no concrete MainViewModel reference here.
    weak var mainViewModel: (any MainViewModelProtocol)?

    func setMainViewModel(_ viewModel: any MainViewModelProtocol) {
        self.mainViewModel = viewModel
    }

    var willChangePublisher: AnyPublisher<Void, Never> {
        self.objectWillChange.map { _ in () }.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(
        persistenceService: PersistenceServiceProtocol? = nil,
        authService: (any AuthServiceProtocol)? = nil,
        syncService: (any CloudSyncServiceProtocol)? = nil
    ) {
        let resolvedPersistence = persistenceService ?? PersistenceService.shared
        self.persistenceService = resolvedPersistence

        // Load existing historical data from persistence before wiring syncHandler
        // (syncHandler's snapshotsProvider closure captures self, so historicalData
        //  must be initialised first).
        if let savedData = resolvedPersistence.load() {
            self.historicalData = savedData.historicalData
        } else {
            self.historicalData = HistoricalData()
        }

        // Intentional placeholder; replaced immediately below after `self` is available.
        // Swift requires all stored properties to be set before `self` can be used.
        let resolvedAuth = authService ?? AuthService.shared
        let resolvedSync = syncService ?? CloudSyncService()

        // syncHandler is a value-type-like coordinator — capture self weakly to avoid retain cycle.
        var capturedSelf: HistoricalDataService?
        self.syncHandler = HistoricalSyncService(
            authService: resolvedAuth,
            syncService: resolvedSync,
            snapshotsProvider: { capturedSelf?.historicalData.dailySnapshots ?? [] },
            lastSyncDateProvider: { capturedSelf?.historicalData.lastSyncDate },
            onSyncCompleted: { date in capturedSelf?.historicalData.lastSyncDate = date }
        )
        capturedSelf = self
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
            averageScore = ScoringThresholds.neutral
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
        let analyzedCalories = meals.compactMap(\.estimatedCalories)
        let hasAnyCalorieData = !analyzedCalories.isEmpty
        let totalCalories = analyzedCalories.reduce(0, +)
        // Complete only when every meal has been AI-analyzed — partial sum shown with "~" in UI
        let hasCompleteCalorieData = !meals.isEmpty && meals.allSatisfy { $0.estimatedCalories != nil }
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
            totalCalories: hasAnyCalorieData ? totalCalories : existing?.totalCalories,
            hasCompleteCalorieData: hasAnyCalorieData ? hasCompleteCalorieData : existing?
                .hasCompleteCalorieData ?? false,
            insight: existing?.insight
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

    // MARK: - Private Helpers

    /// Allocated once — ISO8601DateFormatter initialisation is expensive.
    private static let iso8601Formatter = ISO8601DateFormatter()

    /// Produces a deterministic UUID-shaped string from an ISO date string so that
    /// the same calendar day always maps to the same snapshot UUID, enabling
    /// idempotent cloud uploads and deduplication.
    private static func stableUUIDString(for date: Date) -> String {
        let iso = Self.iso8601Formatter.string(from: date)
        // Simple 32-char hex derived from string hash to form a valid UUID
        let hash = iso.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { acc, byte in
            (acc ^ UInt64(byte)) &* 1_099_511_628_211
        }
        let hex = String(format: "%016llx", hash) + String(format: "%016llx", hash &+ 1)
        let u = Array(hex)
        return "\(String(u[0..<8]))-\(String(u[8..<12]))-4\(String(u[13..<16]))-8\(String(u[17..<20]))-\(String(u[20..<32]))"
    }
}
