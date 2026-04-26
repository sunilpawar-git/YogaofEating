import Combine
import Foundation
import SwiftUI

@MainActor
protocol PersistenceServiceProtocol {
    func load() -> PersistenceService.AppData?
    func save(meals: [Meal], smileyState: SmileyState, lastResetDate: Date, historicalData: HistoricalData)
    func deleteAll()
}

@MainActor
class MainViewModel: ObservableObject {
    @Published var smileyState: SmileyState = .neutral
    @Published var meals: [Meal] = [] {
        didSet { self.updateDerivedState() }
    }

    @Published var lastResetDate: Date = .init()

    /// Meals sorted by timestamp (computed once per change, not per render)
    @Published private(set) var sortedMeals: [Meal] = []

    /// Cached fasting periods between consecutive meals
    @Published private(set) var fastingPeriods: [FastingPeriod] = []

    // MARK: - End-of-Day Reflection (Phase 3)

    /// Controls visibility of the end-of-day reflection sheet
    @Published var showReflectionSheet: Bool = false

    /// The hour (24h format) after which reflection prompt should appear. Default: 8 PM (20:00)
    static let reflectionPromptHour: Int = 20

    // MARK: - User-Initiated Reflections (Phase 4 - Redesign)

    /// Controls visibility of the sleep quality input sheet (morning context)
    @Published var showSleepQualitySheet: Bool = false

    /// Controls visibility of the overall feeling input sheet (evening context)
    @Published var showOverallFeelingSheet: Bool = false

    /// Pending action to execute after reflection input is complete
    var pendingMealCreation: Bool = false

    // MARK: - Mind Check (Phase 3 - Mind Check Feature)

    /// Controls visibility of the morning mind check input sheet
    @Published var showMorningMindCheckSheet: Bool = false

    /// Controls visibility of the evening mind check input sheet
    @Published var showEveningMindCheckSheet: Bool = false

    /// Whether evening review is being shown from End-of-Day pill (includes feeling selection)
    @Published var isEndOfDayFlow: Bool = false

    /// Entries being edited (nil when creating new entries)
    @Published var editingMorningEntries: [MindCheckEntry]?

    // MARK: - Insights (Phase 6 - Peekaboo Star)

    /// Controls visibility of the insight bottom sheet
    @Published var showInsightSheet: Bool = false

    /// The current insight to display (generated when sleep is logged)
    @Published var currentInsight: DailyInsight?

    /// Aggregated weekly summary insight.
    @Published var currentWeeklyInsight: WeeklyInsight?

    /// Suggested sleep quality from Apple HealthKit (if available)
    @Published var suggestedSleepQuality: SleepQuality?

    /// Sleep data from Apple HealthKit (for display)
    @Published var appleSleepData: SleepData?

    // MARK: - Reflect Flow (Phase 1.1 Reboot)

    /// Controls visibility of the morning Reflect input sheet (energy + intention)
    @Published var showReflectSheet: Bool = false

    // MARK: - AI Analysis Tracking

    /// Tracks meal IDs currently being analyzed to prevent concurrent duplicate requests.
    /// This addresses the "GTMSessionFetcher was already running" warning.
    var analysisInProgress: Set<UUID> = []

    // MARK: - Day Navigation (Phase 4)

    /// The currently selected date for viewing. Defaults to today.
    @Published var selectedDate: Date = .init()

    // Maximum number of days to navigate back: moved to MainViewModel+DayNavigation.swift

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
    private var resetMonitorTask: Task<Void, Never>?

    init(
        healthProfileService: HealthProfileServiceProtocol? = nil,
        logicService: MealLogicProvider? = nil,
        persistenceService: PersistenceServiceProtocol? = nil,
        historicalService: (any HistoricalDataServiceProtocol)? = nil,
        insightService: InsightGenerationServiceProtocol? = nil
    ) {
        let healthService = healthProfileService ?? HealthProfileService()
        let historicalSvc = historicalService ?? HistoricalDataService()
        self.healthProfileService = healthService
        self.logicService = logicService ?? AILogicService()
        self.persistenceService = persistenceService ?? PersistenceService.shared
        self.historicalService = historicalSvc
        self.insightService = insightService ?? InsightGenerationService(historicalService: historicalSvc)

        // Skip data loading and monitoring if unit testing to avoid interference
        if NSClassFromString("XCTestCase") == nil {
            self.loadData()
            self.setupResetMonitoring()
        }
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

            // Restore today's persisted insight
            if let snapshot = self.historicalService.getSnapshot(for: Date()) {
                self.currentInsight = snapshot.dailyInsight
            }

            self.refreshWeeklyInsight()

            // If sleep quality is already logged today, fetch Apple sleep data for badge display
            if self.todaysSleepQuality != nil {
                self.fetchAppleSleepDataForBadge()
            }
        }

        // Always schedule nudges — even on first run with no persisted data
        self.scheduleSmartNudges()
    }

    func scheduleSmartNudges() {
        let snapshots = self.historicalService.historicalData
            .dailySnapshots
        let times = SmartNudgeService.suggestedMealTimes(
            from: snapshots
        )
        let message = SmartNudgeService.nudgeMessage(
            streak: self.currentStreak
        )
        NotificationManager.shared.scheduleSmartNudges(
            times: times, message: message
        )
    }

    /// Fetches Apple sleep data for badge display (after sleep quality is already saved).
    /// Called on app load when sleep quality is already logged.
    func fetchAppleSleepDataForBadge() {
        Task {
            do {
                _ = try await HealthKitService.shared.requestAuthorization()
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: Date()) {
                    await MainActor.run {
                        self.appleSleepData = sleepData
                        print("📊 Loaded Apple sleep data for badge: \(sleepData.formattedDuration)")
                    }
                }
            } catch {
                // Silently fail - badge will just not show Apple metrics
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
        self.writeWidgetSnapshot()
    }

    private func writeWidgetSnapshot() {
        guard let container = WidgetDataProvider.appGroupContainerURL()
        else { return }

        let snapshot = self.todaysSnapshot
        let progress = snapshot.map {
            DayModuleProgress.compute(from: $0).overallProgress
        } ?? 0

        let bis = snapshot.map {
            BodyIntelligenceService.compute(
                from: $0, sleepData: nil
            ).value
        } ?? 0

        let widgetData = WidgetSnapshot(
            overallProgress: progress,
            bisScore: bis,
            streak: self.currentStreak.current,
            date: Date()
        )

        PersistenceService.writeWidgetSnapshot(widgetData, to: container)
    }

    /// Periodically checks if the day has changed to reset the slate.
    private func setupResetMonitoring() {
        self.resetMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                self?.checkAndResetIfNewDay()
            }
        }
    }

    deinit {
        resetMonitorTask?.cancel()
    }

    func checkAndResetIfNewDay() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(self.lastResetDate) {
            self.resetDay()
            self.lastResetDate = Date()
            self.saveData()
        }
    }
}
