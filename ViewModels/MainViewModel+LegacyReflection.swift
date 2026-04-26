import Foundation

extension MainViewModel {
    /// Determines if the user should be prompted for an end-of-day reflection.
    /// Returns true if: it's after the prompt hour, user has logged meals, and no reflection exists for today.
    /// - Parameter date: The current date/time to check against (defaults to now)
    /// - Returns: Whether to show the reflection prompt
    @available(*, deprecated, message: "Use isMorningSleepContext() and isEveningFeelingContext() instead")
    func shouldPromptReflection(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        guard hour >= Self.reflectionPromptHour else { return false }

        guard !self.meals.isEmpty else { return false }

        guard self.todaysReflection == nil else { return false }

        return true
    }

    /// Saves the user's end-of-day reflection and dismisses the sheet.
    /// - Parameter reflection: The reflection to save
    func saveReflection(_ reflection: DailyReflection) {
        let today = Date()
        self.historicalService.updateReflection(for: today, reflection: reflection)
        self.showReflectionSheet = false
    }

    /// Dismisses the reflection sheet without saving.
    func skipReflection() {
        self.showReflectionSheet = false
    }

    /// Triggers the reflection prompt if conditions are met.
    /// Call this when the view appears to check if reflection should be shown.
    /// - Parameter date: The current date/time to check against (defaults to now)
    @available(*, deprecated, message: "Use handleSmileyTap() for user-initiated reflections instead")
    func triggerReflectionPromptIfNeeded(at date: Date = Date()) {
        if self.shouldPromptReflection(at: date) {
            self.showReflectionSheet = true
        }
    }

    /// Returns today's reflection if one has been saved.
    var todaysReflection: DailyReflection? {
        let today = Date()
        return self.historicalService.getSnapshot(for: today)?.reflection
    }

    /// Returns today's snapshot for display (e.g. smiley state, meals for history).
    var todaysSnapshot: DailySmileySnapshot? {
        self.historicalService.getSnapshot(for: Date())
    }

    /// Returns the snapshot for a given historical date.
    func snapshot(for date: Date) -> DailySmileySnapshot? {
        self.historicalService.getSnapshot(for: date)
    }

    /// Returns today's sleep quality if logged.
    var todaysSleepQuality: SleepQuality? {
        self.todaysReflection?.sleepQuality
    }

    /// Returns today's overall feeling if logged.
    var todaysFeeling: ReflectionFeeling? {
        self.todaysReflection?.feeling
    }

    /// Returns today's daily intention if set.
    var todaysIntention: String? {
        self.todaysReflection?.dailyIntention
    }

    /// Returns today's morning energy level if logged.
    var todaysEnergyLevel: Int? {
        self.todaysReflection?.morningEnergyLevel
    }

    var todaysFocusRating: Int? {
        self.todaysReflection?.focusRating
    }

    /// Saves a mid-day focus rating (1-3), merging with existing reflection.
    func saveFocusRating(_ rating: Int) {
        let clamped = min(3, max(1, rating))
        let date = Date()
        let focusReflection = DailyReflection(focusRating: clamped, timestamp: date)

        if let existing = self.todaysReflection {
            let merged = focusReflection.merging(with: existing)
            self.historicalService.updateReflection(for: date, reflection: merged)
        } else {
            self.historicalService.updateReflection(for: date, reflection: focusReflection)
        }

        self.saveData()
    }
}
