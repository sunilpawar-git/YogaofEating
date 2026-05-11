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

    // MARK: - Insights (Phase 6 - Peekaboo Star)

    /// Controls visibility of the insight bottom sheet
    @Published var showInsightSheet: Bool = false

    /// The current insight to display (generated when sleep is logged)
    @Published var currentInsight: DailyInsight?

    /// The current morning briefing for today
    @Published var currentBriefing: DailyBriefing?

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

    /// Prevents concurrent briefing generation calls from triggering duplicate Firebase requests.
    /// Guards `triggerBriefingGeneration()` to ensure only one async briefing generation runs at a time.
    var isBriefingGenerationInProgress: Bool = false

    /// Tracked task for background sleep badge fetching. Stored so it can be observed in tests
    /// and cancelled if the VM is deallocated before the request completes.
    var sleepBadgeTask: Task<Void, Never>?

    /// Tracked task for the background day-reset monitoring loop. Cancelled on deinit.
    var resetMonitorTask: Task<Void, Never>?

    /// Tracked task for the in-flight briefing generation request.
    /// Cancelled when the selected date changes during generation.
    var briefingTask: Task<Void, Never>?

    /// Tracked task for the in-flight insight generation request.
    /// Cancelled and replaced if triggered again before the previous completes.
    var insightTask: Task<Void, Never>?

    /// Tracked task for the Highlight tab's one-shot HealthKit sleep fetch.
    /// Stored so it is cancelled on deinit (no duplicate fetch on tab re-open).
    var sleepHighlightTask: Task<Void, Never>?

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
    let insightService: InsightGenerationServiceProtocol
    let activityProvider: ActivityDataProvider
    let textSignalExtractor: any TextSignalExtracting
    let synthesisEngine: any DailySynthesizing
    let insightLifecycleService: any InsightLifecycling
    let synthesisScheduler: any SynthesisScheduling

    // MARK: - Activity Data (R4: TDEE resolution chain)

    /// Active (exercise) calories burned today, sourced from `activityProvider`.
    @Published var todayActiveCalories: Double?

    /// Basal (resting) calories burned today, sourced from `activityProvider`.
    @Published var todayBasalCalories: Double?

    /// Combine subscriptions held for the lifetime of the ViewModel.
    private var cancellables = Set<AnyCancellable>()

    /// Subject that receives raw (mealId, items) pairs on every keystroke.
    /// The debounce pipeline downstream collapses rapid edits before forwarding
    /// to `updateMealItemsLocalOnly`. Owned by the ViewModel — never exposed to views.
    private let mealEditSubject = PassthroughSubject<(UUID, [String]), Never>()

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
        insightService: InsightGenerationServiceProtocol? = nil,
        aiCoordinator: (any AIAnalysisCoordinating)? = nil,
        activityProvider: ActivityDataProvider? = nil,
        textSignalExtractor: (any TextSignalExtracting)? = nil,
        synthesisEngine: (any DailySynthesizing)? = nil,
        insightLifecycleService: (any InsightLifecycling)? = nil,
        synthesisScheduler: (any SynthesisScheduling)? = nil,
        skipDataLoading: Bool = false
    ) {
        let healthService = healthProfileService ?? HealthProfileService()
        let historicalSvc = historicalService ?? HistoricalDataService()
        self.healthProfileService = healthService
        self.logicService = logicService ?? AILogicService()
        self.persistenceService = persistenceService ?? PersistenceService.shared
        self.historicalService = historicalSvc
        self.insightService = insightService ?? InsightGenerationService(historicalService: historicalSvc)
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

        // Collapse rapid-fire keystrokes into a single updateMealItemsLocalOnly call.
        // RunLoop.main avoids subtle threading issues with Swift concurrency on @MainActor.
        self.mealEditSubject
            .debounce(for: .milliseconds(TimingConstants.debounceMs), scheduler: RunLoop.main)
            .sink { [weak self] mealId, items in
                self?.updateMealItemsLocalOnly(mealId, items: items)
            }
            .store(in: &self.cancellables)

        if !skipDataLoading {
            self.loadData()
            self.setupResetMonitoring()
        }
    }

    func enqueueMealEdit(mealId: UUID, items: [String]) {
        self.mealEditSubject.send((mealId, items))
    }

    deinit {
        self.resetMonitorTask?.cancel()
        self.sleepBadgeTask?.cancel()
        self.briefingTask?.cancel()
        self.insightTask?.cancel()
        self.sleepHighlightTask?.cancel()
    }
}
