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

        // Wire back-reference via protocol so HistoricalDataService.saveHistoricalData()
        // delegates to the single canonical save path here.
        // No concrete cast needed — protocol method satisfies DIP.
        historicalSvc.setMainViewModel(self)

        // Forward historicalService mutations to MainViewModel.objectWillChange so that
        // computed view contracts (highlightViewData, reflectViewData) trigger SwiftUI
        // re-renders even when no @Published property on MainViewModel changes directly.
        historicalSvc.willChangePublisher
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &self.cancellables)

        // Combine debounce pipeline for local meal edits during typing.
        // Views call `enqueueMealEdit` on every keystroke; rapid-fire calls are collapsed
        // into a single `updateMealItemsLocalOnly` invocation after the debounce window.
        // RunLoop.main is used instead of DispatchQueue.main to avoid subtle threading
        // issues with Swift concurrency on @MainActor classes.
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

    deinit {
        self.resetMonitorTask?.cancel()
        self.sleepBadgeTask?.cancel()
        self.briefingTask?.cancel()
    }

    /// Loads persisted data or starts fresh
    func loadData() {
        if let data = self.persistenceService.load() {
            self.meals = data.meals
            self.smileyState = data.smileyState
            self.lastResetDate = data.lastResetDate
            self.historicalService.historicalData = data.historicalData

            // Still check if we need to reset for a new day since the last save
            self.checkAndResetIfNewDay()

            // If sleep quality is already logged today, fetch Apple sleep data for badge display
            if self.todaysSleepQuality != nil {
                self.fetchAppleSleepDataForBadge()
            }
        }

        // Hydrate today's briefing from persisted snapshot (independent of persistence load)
        if self.currentBriefing == nil,
           let todayBriefing = self.historicalService.getSnapshot(for: Date())?.briefing
        {
            self.currentBriefing = todayBriefing
        }
    }

    /// Fetches Apple sleep data for badge display (after sleep quality is already saved).
    /// Called on app load when sleep quality is already logged.
    func fetchAppleSleepDataForBadge() {
        self.sleepBadgeTask = Task {
            do {
                _ = try await HealthKitService.shared.requestAuthorization()
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: Date()) {
                    self.appleSleepData = sleepData
                    vmLogger
                        .info(
                            "Loaded Apple sleep data for badge: \(sleepData.formattedDuration, privacy: .public)"
                        )
                }
            } catch {
                // Non-critical: badge simply won't show Apple metrics. Log at .info for debuggability.
                vmLogger.info("Sleep badge fetch unavailable: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Saves current state
    func saveData() {
        self.persistenceService.save(
            meals: self.meals,
            smileyState: self.smileyState,
            lastResetDate: self.lastResetDate,
            historicalData: self.historicalService.historicalData
        )
    }

    /// Periodically checks if the day has changed to reset the slate.
    private func setupResetMonitoring() {
        self.resetMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                // CancellationError from sleep is intentional (task cancelled on deinit) — no-op
                try? await Task.sleep(nanoseconds: TimingConstants.dayResetPollIntervalNanoseconds)
                self?.checkAndResetIfNewDay()
            }
        }
    }

    /// Cancels the in-flight briefing generation task, if any.
    /// Called when the selected date changes so stale briefing work is discarded.
    func cancelBriefingTask() {
        self.briefingTask?.cancel()
        self.briefingTask = nil
    }

    func checkAndResetIfNewDay() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(self.lastResetDate) {
            self.resetDay()
            self.lastResetDate = Date()
            self.saveData()
        }
    }

    /// Enqueues a local meal edit for debounced processing.
    ///
    /// Views call this on every keystroke instead of calling `updateMealItemsLocalOnly` directly.
    /// The Combine pipeline in `init` debounces rapid calls and forwards the final value
    /// to `updateMealItemsLocalOnly` after `TimingConstants.debounceMs` of silence.
    ///
    /// - Parameters:
    ///   - mealId: The ID of the meal being edited.
    ///   - items: The current parsed items from the text field.
    func enqueueMealEdit(mealId: UUID, items: [String]) {
        self.mealEditSubject.send((mealId, items))
    }
}
