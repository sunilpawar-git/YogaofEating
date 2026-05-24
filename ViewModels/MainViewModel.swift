import Combine
import Foundation
import OSLog
import SwiftUI

private let vmLogger = Logger(subsystem: "com.yogaofeating", category: "MainViewModel")

/// Central state manager for the Yoga of Eating app.
/// Strictly follows MVVM and handles interaction between View and Logic.
@MainActor
class MainViewModel: ObservableObject, MainViewModelProtocol {
    @Published var smileyState: SmileyState = .neutral
    @Published var meals: [Meal] = [] {
        didSet { self.updateDerivedState() }
    }

    @Published var lastResetDate: Date = .init()

    /// Meals sorted by timestamp (computed once per change, not per render).
    /// Internal only — no SwiftUI view binds to this; views receive sorted meals via `meals` or `fastingPeriods`.
    private var sortedMeals: [Meal] = []

    /// Cached fasting periods between consecutive meals
    @Published private(set) var fastingPeriods: [FastingPeriod] = []

    // MARK: - Mind Check (Phase 3 - Mind Check Feature)

    /// Entries being edited (nil when creating new entries)
    @Published var editingMorningEntries: [MindCheckEntry]?

    // MARK: - Insights

    /// Controls visibility of the insight bottom sheet
    @Published var showInsightSheet: Bool = false

    /// The unified daily insight (replaces legacy DailyInsight + DailyBriefing).
    @Published var currentInsight: DailyInsight?

    /// Whether the briefing detail sheet is shown
    @Published var showBriefingSheet: Bool = false

    /// Whether the wellbeing breakdown sheet is shown (opened via smiley long-press)
    @Published var showBreakdownSheet: Bool = false

    /// Suggested sleep quality from Apple HealthKit (if available)
    @Published var suggestedSleepQuality: SleepQuality?

    /// Sleep data from Apple HealthKit (for display)
    @Published var appleSleepData: SleepData?

    // MARK: - Input Validation (Phase 2)

    /// Last validation error encountered; cleared after user dismisses alert
    @Published var lastValidationError: ValidationError?

    /// Whether to show validation error alert to user
    @Published var showValidationErrorAlert: Bool = false

    // MARK: - AI Analysis Tracking

    /// Coordinator for AI analysis tasks. Owns task lifecycle and write-back closures;
    /// never holds a direct reference to MainViewModel (DIP-compliant).
    let aiCoordinator: any AIAnalysisCoordinating

    /// Prevents concurrent insight generation calls.
    var isInsightGenerationInProgress: Bool = false

    /// Tracked task for background sleep badge fetching. Stored so it can be observed in tests
    /// and cancelled if the VM is deallocated before the request completes.
    var sleepBadgeTask: Task<Void, Never>?

    /// Tracked task for the background day-reset monitoring loop. Cancelled on deinit.
    var resetMonitorTask: Task<Void, Never>?

    /// Tracked task for the in-flight insight generation request.
    /// Cancelled and replaced if triggered again before the previous completes.
    var insightTask: Task<Void, Never>?

    /// Tracked task for the Highlight tab's one-shot HealthKit sleep fetch.
    /// Stored so it is cancelled on deinit (no duplicate fetch on tab re-open).
    var sleepHighlightTask: Task<Void, Never>?

    /// Tracked task for the activity-data refresh pipeline.
    /// Cancelled and replaced on each call to `refreshActivityDataIfNeeded()`.
    /// Not `private` because the setter is in a separate extension file (MainViewModel+Lifecycle.swift).
    /// No code outside of `refreshActivityDataIfNeeded()` should write this property.
    var activityRefreshTask: Task<Void, Never>?

    // MARK: - Day Navigation (Phase 4)

    /// The currently selected date for viewing. Defaults to today.
    @Published var selectedDate: Date = .init()

    /// Maximum number of days the user can navigate back. Default: 30 days.
    static let maxDaysBack: Int = 30

    /// Updates derived state (sorted meals and fasting periods) when meals change
    private func updateDerivedState() {
        self.sortedMeals = self.meals.sorted { $0.timestamp < $1.timestamp }
        self.fastingPeriods = FastingLogicService.calculateFastingPeriods(from: self.sortedMeals)
    }

    let logicService: MealLogicProvider
    let persistenceService: PersistenceServiceProtocol
    let historicalService: any HistoricalDataServiceProtocol
    let healthProfileService: HealthProfileServiceProtocol
    let activityProvider: ActivityDataProvider
    let textSignalExtractor: any TextSignalExtracting
    let synthesisEngine: any DailySynthesizing
    let insightLifecycleService: any InsightLifecycling
    let synthesisScheduler: any SynthesisScheduling
    /// Authentication service used for account-switch detection on launch.
    /// Nil in test contexts (prevents Firebase access from test-created ViewModels).
    let authService: (any AuthServiceProtocol)?
    /// UserDefaults store used for persistence flags (e.g. lastSignedInUID, hasDeletedAllData).
    /// Injected so tests can use an isolated suite and avoid polluting UserDefaults.standard.
    let userDefaults: UserDefaults

    // MARK: - Activity Data (R4: TDEE resolution chain)

    /// Active (exercise) calories burned today, sourced from `activityProvider`.
    @Published var todayActiveCalories: Double?

    /// Basal (resting) calories burned today, sourced from `activityProvider`.
    @Published var todayBasalCalories: Double?

    /// Timestamp of the last successful activity data fetch.
    /// Used by `refreshActivityDataIfNeeded()` to enforce the cooldown window.
    /// Written only from `refreshActivityDataIfNeeded()` in MainViewModel+Lifecycle.swift.
    /// Not `private(set)` because Swift does not support that modifier across extension files,
    /// but no View should ever write to this property.
    var lastActivityDataFetchDate: Date?

    /// Combine subscriptions held for the lifetime of the ViewModel.
    private var cancellables = Set<AnyCancellable>()

    /// Cached formatter for the selected date display. Allocated once per VM instance
    /// rather than on every call to `formattedSelectedDate`.
    let selectedDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "eee, d MMM yyyy"
        return f
    }()

    init(
        healthProfileService: HealthProfileServiceProtocol? = nil,
        logicService: MealLogicProvider? = nil,
        persistenceService: PersistenceServiceProtocol? = nil,
        historicalService: (any HistoricalDataServiceProtocol)? = nil,
        aiCoordinator: (any AIAnalysisCoordinating)? = nil,
        activityProvider: ActivityDataProvider? = nil,
        textSignalExtractor: (any TextSignalExtracting)? = nil,
        synthesisEngine: (any DailySynthesizing)? = nil,
        insightLifecycleService: (any InsightLifecycling)? = nil,
        synthesisScheduler: (any SynthesisScheduling)? = nil,
        authService: (any AuthServiceProtocol)? = nil,
        userDefaults: UserDefaults = .standard,
        skipDataLoading: Bool = false
    ) {
        let healthService = healthProfileService ?? HealthProfileService()
        let historicalSvc = historicalService ?? HistoricalDataService()
        self.healthProfileService = healthService
        self.logicService = logicService ?? AILogicService()
        self.authService = authService
        self.userDefaults = userDefaults
        self.persistenceService = persistenceService ?? PersistenceService.shared
        self.historicalService = historicalSvc
        self.aiCoordinator = aiCoordinator ?? AIAnalysisCoordinator()
        self.activityProvider = activityProvider ?? HealthKitService.shared
        self.textSignalExtractor = textSignalExtractor ?? TextSignalExtractor()
        self.synthesisEngine = synthesisEngine ?? DailySynthesisEngine()
        self
            .insightLifecycleService = insightLifecycleService ??
            InsightLifecycleService(historicalService: historicalSvc)
        // Phase 1: store scheduler (no handler yet — [weak self] not valid before all properties set).
        let sched: any SynthesisScheduling = synthesisScheduler ?? SynthesisScheduler()
        self.synthesisScheduler = sched
        // Phase 2: wire handler now that self is fully initialized; skip for injected mocks.
        if let realScheduler = sched as? SynthesisScheduler {
            realScheduler.setHandler { [weak self] trigger in
                self?.performInsightLifecycle(trigger: trigger)
            }
        }

        // Wire back-reference via protocol (DIP-compliant; no concrete cast needed).
        historicalSvc.setMainViewModel(self)

        // Forward historicalService mutations to objectWillChange so view contracts re-render.
        historicalSvc.willChangePublisher
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &self.cancellables)

        // Re-render calorie pill when health-profile settings change (e.g. activity level).
        // Decoupled from SettingsViewModel via NotificationCenter (no direct reference).
        NotificationCenter.default
            .publisher(for: AppNotification.healthProfileDidChange)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &self.cancellables)

        if !skipDataLoading {
            self.loadData()
            self.setupResetMonitoring()
        }
    }

    deinit {
        self.resetMonitorTask?.cancel()
        self.sleepBadgeTask?.cancel()
        self.insightTask?.cancel()
        self.sleepHighlightTask?.cancel()
        self.activityRefreshTask?.cancel()
    }
}
