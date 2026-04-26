import Foundation

// MARK: - Reflection Flow Extension

extension MainViewModel {
    // MARK: - Context Detection

    /// The hour before which sleep context is valid (noon = 12)
    static let morningCutoffHour: Int = 12

    func isMorningSleepContext(at date: Date = Date()) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        guard hour < Self.morningCutoffHour else { return false }
        guard self.meals.isEmpty else { return false }
        guard self.todaysSleepQuality == nil else { return false }
        return true
    }

    @available(*, deprecated, message: "Use showEndOfDayPill computed property instead")
    func isEveningFeelingContext() -> Bool {
        !self.meals.isEmpty && self.todaysFeeling == nil
    }

    // MARK: - Reflection Saves

    func saveSleepQuality(_ quality: SleepQuality, at date: Date = Date()) {
        let newReflection = DailyReflection.withSleepQuality(quality, at: date)
        if let existing = self.todaysReflection {
            self.historicalService.updateReflection(for: date, reflection: newReflection.merging(with: existing))
        } else {
            self.historicalService.updateReflection(for: date, reflection: newReflection)
        }
        if self.appleSleepData == nil { self.fetchAppleSleepDataForBadge() }
        self.triggerInsightGenerationIfNeeded(for: date)
    }

    func saveOverallFeeling(_ feeling: ReflectionFeeling, at date: Date = Date()) {
        let newReflection = DailyReflection.withFeeling(feeling, at: date)
        if let existing = self.todaysReflection {
            self.historicalService.updateReflection(for: date, reflection: newReflection.merging(with: existing))
        } else {
            self.historicalService.updateReflection(for: date, reflection: newReflection)
        }
    }

    // MARK: - Smiley Tap Flow

    var showEndOfDayPill: Bool {
        !self.meals.isEmpty && self.todaysFeeling == nil
    }

    func handleSmileyTap() {
        guard !self.isUITesting else { self.createNewMeal()
            return
        }
        if self.isMorningSleepContext() {
            self.pendingMealCreation = true
            self.showSleepQualitySheet = true
            self.fetchAppleSleepData()
        } else {
            self.createNewMeal()
        }
    }

    func handleEndOfDayPillTap() {
        self.pendingMealCreation = false
        if let morningEntries = self.todaysMorningMindCheck, !morningEntries.isEmpty {
            self.isEndOfDayFlow = true
            self.showEveningMindCheckSheet = true
        } else {
            self.showOverallFeelingSheet = true
        }
    }

    func completeSleepQualityInput(_ quality: SleepQuality) {
        self.saveSleepQuality(quality)
        self.showSleepQualitySheet = false
        if self.todaysIntention == nil {
            self.showReflectSheet = true
        } else if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
        }
    }

    func completeReflectInput(energy: Int, intention: String) {
        let date = Date()
        let data = DailyReflection.withReflect(energyLevel: energy, intention: intention, at: date)
        if let existing = self.todaysReflection {
            self.historicalService.updateReflection(for: date, reflection: data.merging(with: existing))
        } else {
            self.historicalService.updateReflection(for: date, reflection: data)
        }
        self.showReflectSheet = false
        if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
        }
    }

    func dismissReflectInput() {
        self.showReflectSheet = false
        if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
        }
    }

    func dismissSleepQualityInput() {
        self.showSleepQualitySheet = false
        self.suggestedSleepQuality = nil
        self.appleSleepData = nil
        if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
        }
    }

    func completeOverallFeelingInput(_ feeling: ReflectionFeeling) {
        self.saveOverallFeeling(feeling)
        self.showOverallFeelingSheet = false
        if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
        }
    }

    func dismissOverallFeelingInput() {
        self.showOverallFeelingSheet = false
        if self.pendingMealCreation {
            self.pendingMealCreation = false
            self.createNewMeal()
        }
    }

    // MARK: - Internal Helpers

    var isUITesting: Bool {
        CommandLine.arguments.contains("--uitesting")
    }

    func triggerInsightGenerationIfNeeded(for date: Date) {
        if let existing = self.currentInsight,
           Calendar.current.isDate(existing.date, inSameDayAs: date)
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
                print("⚠️ Insight generation failed: \(error.localizedDescription)")
            }
        }
    }

    func fetchAppleSleepData() {
        Task {
            do {
                _ = try await HealthKitService.shared.requestAuthorization()
                if let sleepData = try await HealthKitService.shared.fetchSleepData(for: Date()) {
                    await MainActor.run {
                        self.appleSleepData = sleepData
                        self.suggestedSleepQuality = sleepData.sleepQuality
                    }
                }
            } catch {
                print("⚠️ Failed to fetch Apple sleep data: \(error.localizedDescription)")
            }
        }
    }

    func fetchHealthKitSleepDataForInsights(relativeTo date: Date) async -> [Date: SleepData] {
        var result: [Date: SleepData] = [:]
        let calendar = Calendar.current
        for daysAgo in 0..<3 {
            guard let target = calendar.date(byAdding: .day, value: -daysAgo, to: date) else { continue }
            do {
                if let data = try await HealthKitService.shared.fetchSleepData(for: target) {
                    result[calendar.startOfDay(for: target)] = data
                }
            } catch {
                continue
            }
        }
        return result
    }
}
