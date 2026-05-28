import Foundation
import OSLog

private let reflectionLogger = Logger(subsystem: "com.yogaofeating", category: "Reflection")

// MARK: - Reflection (Sleep, Feeling, Insight Trigger)

extension MainViewModel {
    /// Returns today's reflection if one has been saved.
    var todaysReflection: DailyReflection? {
        let today = Date()
        return self.historicalService.getSnapshot(for: today)?.reflection
    }

    /// Returns today's sleep quality if logged.
    var todaysSleepQuality: SleepQuality? {
        self.todaysReflection?.sleepQuality
    }

    /// Returns today's overall feeling if logged.
    var todaysFeeling: ReflectionFeeling? {
        self.todaysReflection?.feeling
    }

    /// Saves sleep quality for today, merging with existing reflection if present.
    /// Schedules the full insight lifecycle via `synthesisScheduler` (bypasses debounce).
    func saveSleepQuality(_ quality: SleepQuality, at date: Date = Date()) {
        let newReflection = DailyReflection.withSleepQuality(quality, at: date)

        if let existing = self.todaysReflection {
            let merged = newReflection.merging(with: existing)
            self.historicalService.updateReflection(for: date, reflection: merged)
        } else {
            self.historicalService.updateReflection(for: date, reflection: newReflection)
        }

        if self.appleSleepData == nil {
            self.fetchAppleSleepDataForBadge()
        }

        // .sleepLogged bypasses debounce — fires full insight + briefing + enriched cycle immediately.
        self.synthesisScheduler.schedule(.sleepLogged)
    }

    /// Single entry point for the insight lifecycle, called by `SynthesisScheduler`.
    ///
    /// For `.sleepLogged`: runs full pipeline — legacy insight, morning briefing, and enriched insight.
    /// For all other triggers: re-synthesises smiley and regenerates enriched insight.
    func performInsightLifecycle(trigger: SynthesisTrigger) {
        let date = Date()
        self.updateSmileyStateFromAllMeals()

        if trigger == .sleepLogged {
            self.triggerInsightGeneration()
        }

        self.triggerEnrichedInsightGeneration(for: date)
    }

    /// Fetches HealthKit sleep data for the last N days for insight generation.
    func fetchHealthKitSleepDataForInsights(relativeTo date: Date) async -> [Date: SleepData] {
        var sleepDataByDate: [Date: SleepData] = [:]
        let calendar = Calendar.current

        for daysAgo in 0..<3 {
            guard let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: date) else { continue }

            do {
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: targetDate) {
                    sleepDataByDate[calendar.startOfDay(for: targetDate)] = sleepData
                    reflectionLogger.debug("Fetched HealthKit sleep data")
                }
            } catch {
                reflectionLogger.error(
                    "Failed to fetch HealthKit sleep data: \(error.localizedDescription, privacy: .private)"
                )
            }
        }

        return sleepDataByDate
    }

    /// Triggers enriched insight generation after sleep is logged.
    /// Uses the current synthesis to produce an `EnrichedDailyInsight` via `InsightLifecycleService`.
    func triggerEnrichedInsightGeneration(for date: Date) {
        guard self.authService?.currentUser?.uid != nil else { return }
        Task {
            let snapshot = self.historicalService.getSnapshot(for: self.selectedDate)
            let healthKitData = await self.fetchHealthKitSleepDataForInsights(relativeTo: date)
            let recentSnapshots = (0..<7).compactMap { daysAgo -> DailySmileySnapshot? in
                guard let target = Calendar.current.date(byAdding: .day, value: -daysAgo, to: date) else {
                    return nil
                }
                return self.historicalService.getSnapshot(for: target)
            }.filter { !$0.isEmpty }

            let synthesis = self.synthesisEngine.synthesize(
                meals: self.meals,
                highlightData: snapshot?.highlightData,
                reflectData: snapshot?.reflectData,
                appleSleepData: self.appleSleepData,
                activeCaloriesBurned: self.todayActiveCalories
            )

            _ = await self.insightLifecycleService.generateEnrichedInsight(
                for: date,
                synthesis: synthesis,
                recentSnapshots: recentSnapshots,
                healthKitSleepData: healthKitData
            )
        }
    }

    /// Saves overall feeling for today, merging with existing reflection if present.
    func saveOverallFeeling(_ feeling: ReflectionFeeling, at date: Date = Date()) {
        let newReflection = DailyReflection.withFeeling(feeling, at: date)

        if let existing = self.todaysReflection {
            let merged = newReflection.merging(with: existing)
            self.historicalService.updateReflection(for: date, reflection: merged)
        } else {
            self.historicalService.updateReflection(for: date, reflection: newReflection)
        }
    }
}
