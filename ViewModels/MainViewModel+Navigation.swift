import Foundation

// MARK: - Day Navigation & Data Contracts

extension MainViewModel {
    /// Returns true if the selected date is today.
    var isViewingToday: Bool {
        Calendar.current.isDateInToday(self.selectedDate)
    }

    /// Returns true if the user can navigate to the previous day (within maxDaysBack limit).
    var canNavigateToPreviousDay: Bool {
        self.selectedDayIndex < Self.maxDaysBack
    }

    /// Returns true if the user can navigate to the next day (not beyond today).
    var canNavigateToNextDay: Bool {
        !self.isViewingToday
    }

    /// Returns the number of days between the selected date and today (0 = today).
    var selectedDayIndex: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: self.selectedDate)
        let components = calendar.dateComponents([.day], from: selected, to: today)
        return max(0, components.day ?? 0)
    }

    /// Formatted string for the selected date (e.g., "Mon, 5 Jan 2026").
    /// Uses the cached `selectedDateFormatter` to avoid allocating a new formatter per call.
    var formattedSelectedDate: String {
        self.selectedDateFormatter.string(from: self.selectedDate)
    }

    // MARK: - Minimal Data Contracts for Tab Views

    /// Returns the current HighlightData for the selected date from the snapshot.
    var currentHighlightData: HighlightData? {
        self.historicalService.getSnapshot(for: self.selectedDate)?.highlightData
    }

    /// Returns the current ReflectData for the selected date from the snapshot.
    var currentReflectData: ReflectData? {
        self.historicalService.getSnapshot(for: self.selectedDate)?.reflectData
    }

    /// Minimal data contract for HighlightView.
    /// Includes highlight content + HealthKit sleep data. No meals, no smiley state.
    var highlightViewData: HighlightViewContract {
        let snapshot = self.historicalService.getSnapshot(for: self.selectedDate)
        let data = snapshot?.highlightData
        return HighlightViewContract(
            sleepQuality: data?.sleepQuality,
            sleepNotes: data?.sleepNotes,
            todos: data?.todos ?? [],
            morningThoughts: data?.morningThoughts,
            healthKitSleepData: self.isViewingToday ? self.appleSleepData : nil,
            isToday: self.isViewingToday,
            date: Calendar.current.startOfDay(for: self.selectedDate)
        )
    }

    /// Minimal data contract for ReflectView.
    /// Includes reflect content + morning todos for review. No meals, no sleep data.
    var reflectViewData: ReflectViewContract {
        let snapshot = self.historicalService.getSnapshot(for: self.selectedDate)
        let data = snapshot?.reflectData
        let highlightTodos = snapshot?.highlightData?.todos ?? []
        return ReflectViewContract(
            journalText: data?.journalText,
            feeling: data?.feeling,
            morningTodos: highlightTodos,
            isToday: self.isViewingToday,
            detectedSignals: data?.textSignals ?? [],
            date: Calendar.current.startOfDay(for: self.selectedDate)
        )
    }

    // MARK: - Wellbeing Breakdown Contract

    /// Minimal data contract for `WellbeingBreakdownSheet`.
    /// Returns nil when viewing a past day.
    var wellbeingBreakdownContract: WellbeingBreakdownSheetContract? {
        guard self.isViewingToday else { return nil }
        let snapshot = self.historicalService.getSnapshot(for: self.selectedDate)
        let synthesis = self.synthesisEngine.synthesize(
            meals: self.meals,
            highlightData: snapshot?.highlightData,
            reflectData: snapshot?.reflectData,
            appleSleepData: self.appleSleepData,
            yesterday: nil
        )
        let weakDims: [WellbeingDimension] = WellbeingDimension.allCases
            .map { dim in (dim, dim.value(in: synthesis.dimensions)) }
            .filter { _, score in score < SynthesisThresholds.weakDimension }
            .sorted { $0.1 < $1.1 }
            .prefix(2)
            .map(\.0)
        return WellbeingBreakdownSheetContract(
            dimensions: synthesis.dimensions,
            dominantDimension: synthesis.dominantDimension,
            causalNarrative: synthesis.causalNarrative,
            weakDimensions: weakDims,
            mealCount: self.meals.count,
            currentMood: synthesis.smileySuggestion.mood,
            overallScore: synthesis.overall
        )
    }

    /// Up to 2 weakest dimensions for the MorningBriefingCard subtext.
    /// Derived from `wellbeingBreakdownContract` to share synthesis computation.
    var briefingWeakDimensions: [WellbeingDimension] {
        self.wellbeingBreakdownContract?.weakDimensions ?? []
    }

    // MARK: - Navigation Actions

    /// Navigates to a specific date. Future dates are clamped to today.
    func navigateToDate(_ date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)

        if targetDay > today {
            self.selectedDate = today
        } else {
            self.selectedDate = targetDay
        }
    }

    /// Navigates to the previous day.
    func navigateToPreviousDay() {
        guard self.canNavigateToPreviousDay else { return }
        let calendar = Calendar.current
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: self.selectedDate) {
            self.navigateToDate(previousDay)
        }
    }

    /// Navigates to the next day (towards today).
    func navigateToNextDay() {
        guard self.canNavigateToNextDay else { return }
        let calendar = Calendar.current
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: self.selectedDate) {
            self.navigateToDate(nextDay)
        }
    }

    /// Navigates back to today.
    func navigateToToday() {
        self.selectedDate = Calendar.current.startOfDay(for: Date())
    }

    /// Navigates to a day by index (0 = today, 1 = yesterday, etc.).
    func navigateToIndex(_ index: Int) {
        let calendar = Calendar.current
        let clampedIndex = max(0, min(index, Self.maxDaysBack))
        let today = calendar.startOfDay(for: Date())
        if let targetDate = calendar.date(byAdding: .day, value: -clampedIndex, to: today) {
            self.selectedDate = targetDate
        }
    }

    // MARK: - Selected Date Queries

    /// Returns the meals for the currently selected date.
    /// For today, returns current meals. For past days, returns historical meals.
    func mealsForSelectedDate() -> [Meal] {
        if self.isViewingToday {
            self.meals
        } else {
            self.snapshotForSelectedDate()?.meals ?? []
        }
    }

    /// Returns the snapshot for the currently selected date, if available.
    func snapshotForSelectedDate() -> DailySmileySnapshot? {
        self.historicalService.getSnapshot(for: self.selectedDate)
    }
}
