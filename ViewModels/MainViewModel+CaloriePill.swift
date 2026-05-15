import Foundation

// MARK: - Calorie Pill Computed Property

extension MainViewModel {
    /// Aggregated calorie data for the CaloriePillView (today's data).
    ///
    /// TDEE resolution order (highest fidelity first):
    /// 1. HealthKit basal + HealthKit active (most accurate — real resting + real exercise)
    /// 2. Profile BMR + HealthKit active (hybrid — real exercise, estimated rest)
    /// 3. Profile static TDEE (estimate only — no real-time data)
    /// 4. nil (no profile and no HealthKit data)
    ///
    /// Always returns a non-nil `CaloriePillData`; callers rely on `isVisible` to hide the pill.
    var caloriePillData: CaloriePillData {
        let consumed = self.totalConsumedCalories
        let tdee = self.resolvedTDEE()
        return CaloriePillData(consumed: consumed, tdee: tdee)
    }

    /// Fetches today's activity data from the injected provider and updates published properties.
    /// Call once on app foreground or on tab appear — not in tight loops.
    func loadTodayActivityData() async {
        async let active = self.activityProvider.fetchActiveCaloriesBurned(for: Date())
        async let basal = self.activityProvider.fetchBasalCaloriesBurned(for: Date())
        let (activeResult, basalResult) = await (active, basal)
        self.todayActiveCalories = activeResult
        self.todayBasalCalories = basalResult
    }

    // MARK: - Private

    /// Total estimated calories consumed today across all logged meals.
    /// Single source of truth — used by both `caloriePillData` and `calorieDetailData`.
    private var totalConsumedCalories: Int {
        self.meals.compactMap(\.estimatedCalories).reduce(0, +)
    }

    /// Resolves today's TDEE using the MFP approach: stable base + real exercise on top.
    ///
    /// Resolution order:
    /// 1. Profile TDEE + actual active calories (best: stable base, real exercise data)
    /// 2. Projected basal + actual active (HealthKit-only fallback, no profile)
    /// 3. nil (no data at all)
    private func resolvedTDEE() -> Int? {
        let profile = self.healthProfileService.getUserHealthProfile()
        let activeCalories = self.todayActiveCalories ?? 0.0

        // Tier 1: Profile TDEE is the stable full-day base; active calories stack on top
        // as the user exercises — exactly the MyFitnessPal model.
        if let profile {
            return Int((profile.tdee + activeCalories).rounded())
        }

        // Tier 2: No profile — project the partial basal reading to a full-day estimate,
        // then add whatever active calories HealthKit has recorded.
        if let basal = self.todayBasalCalories {
            let fraction = max(0.1, Self.fractionOfDayElapsed())
            let projectedBasal = basal / fraction
            return Int((projectedBasal + activeCalories).rounded())
        }

        return nil
    }

    private static func fractionOfDayElapsed() -> Double {
        let cal = Calendar.current
        let now = Date()
        return now.timeIntervalSince(cal.startOfDay(for: now)) / 86400
    }

    // MARK: - CalorieDetailData (R5)

    /// Full breakdown data for `CalorieDetailSheet`, including per-meal entries and activity calories.
    var calorieDetailData: CalorieDetailData {
        let consumed = self.totalConsumedCalories
        let tdee = self.resolvedTDEE()
        let profileBaseTdee = self.healthProfileService.getUserHealthProfile()
            .map { Int($0.tdee.rounded()) }
        return CalorieDetailData(
            consumed: consumed,
            tdee: tdee,
            profileBaseTdee: profileBaseTdee,
            meals: self.meals,
            basalCalories: self.todayBasalCalories,
            activeCalories: self.todayActiveCalories
        )
    }

    /// Calorie pill data for a historical day, derived from archived snapshot.
    ///
    /// Returns `nil` when no snapshot exists for the date, or when the snapshot has no
    /// calorie data (e.g. pre-feature data or a day with no AI-analyzed meals).
    func historicalCaloriePillData(for date: Date) -> CaloriePillData? {
        guard let snapshot = self.historicalService.getSnapshot(for: date),
              let consumed = snapshot.totalCalories else { return nil }

        let tdee: Int? = self.healthProfileService.getUserHealthProfile()
            .map { Int($0.tdee.rounded()) }

        var data = CaloriePillData(consumed: consumed, tdee: tdee)
        data.isPartial = !snapshot.hasCompleteCalorieData
        return data
    }
}
