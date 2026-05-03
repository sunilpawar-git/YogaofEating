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
    /// Also triggers insight generation and ensures Apple sleep data is available for badge.
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

        self.triggerInsightGenerationIfNeeded(for: date)
        self.triggerBriefingGeneration()
    }

    /// Triggers insight generation if conditions are met.
    /// Conditions: No insight exists for today AND sleep quality is logged AND historical data exists.
    func triggerInsightGenerationIfNeeded(for date: Date) {
        if let existingInsight = self.currentInsight,
           Calendar.current.isDate(existingInsight.date, inSameDayAs: date)
        {
            return
        }

        Task {
            do {
                let healthKitSleepData = await self.fetchHealthKitSleepDataForInsights(relativeTo: date)

                if let insight = try await self.insightService.generateInsight(
                    for: date,
                    healthKitSleepData: healthKitSleepData
                ) {
                    self.currentInsight = insight
                }
            } catch {
                reflectionLogger.error("Insight generation failed: \(error.localizedDescription, privacy: .public)")
            }
        }
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
                    "Failed to fetch HealthKit sleep data: \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        return sleepDataByDate
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
