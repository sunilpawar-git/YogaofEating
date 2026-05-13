import Foundation

extension DailySmileySnapshot {
    // MARK: - Factory

    static func create(
        date: Date,
        smileyState: SmileyState,
        meals: [Meal],
        reflection: DailyReflection? = nil,
        morningMindCheck: [MindCheckEntry]? = nil,
        eveningMindCheck: [MindCheckEntry]? = nil,
        highlightData: HighlightData? = nil,
        reflectData: ReflectData? = nil,
        briefing: DailyBriefing? = nil
    ) -> DailySmileySnapshot {
        let count = meals.count
        let avg = meals.isEmpty ? 0.5 : meals.map(\.healthScore).reduce(0.0, +) / Double(count)
        return DailySmileySnapshot(
            id: UUID(), date: date, smileyState: smileyState,
            meals: meals, mealCount: count, averageHealthScore: avg,
            reflection: reflection, morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck, highlightData: highlightData,
            reflectData: reflectData, briefing: briefing
        )
    }

    // MARK: - Immutable Updaters

    func withMindChecks(
        morningMindCheck: [MindCheckEntry]? = nil,
        eveningMindCheck: [MindCheckEntry]? = nil
    ) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: id, date: date, smileyState: smileyState, meals: meals,
            mealCount: mealCount, averageHealthScore: averageHealthScore,
            reflection: reflection,
            morningMindCheck: morningMindCheck ?? self.morningMindCheck,
            eveningMindCheck: eveningMindCheck ?? self.eveningMindCheck,
            highlightData: highlightData, reflectData: reflectData,
            briefing: briefing, insight: insight,
            totalCalories: totalCalories, hasCompleteCalorieData: hasCompleteCalorieData,
            wellbeingDimensions: wellbeingDimensions, textSignals: textSignals,
            enrichedInsight: enrichedInsight
        )
    }

    func withReflection(_ reflection: DailyReflection) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: id, date: date, smileyState: smileyState, meals: meals,
            mealCount: mealCount, averageHealthScore: averageHealthScore,
            reflection: reflection, morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck, highlightData: highlightData,
            reflectData: reflectData, briefing: briefing, insight: insight,
            totalCalories: totalCalories, hasCompleteCalorieData: hasCompleteCalorieData,
            wellbeingDimensions: wellbeingDimensions, textSignals: textSignals,
            enrichedInsight: enrichedInsight
        )
    }

    func withHighlightData(_ highlightData: HighlightData) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: id, date: date, smileyState: smileyState, meals: meals,
            mealCount: mealCount, averageHealthScore: averageHealthScore,
            reflection: reflection, morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck, highlightData: highlightData,
            reflectData: reflectData, briefing: briefing, insight: insight,
            totalCalories: totalCalories, hasCompleteCalorieData: hasCompleteCalorieData,
            wellbeingDimensions: wellbeingDimensions, textSignals: textSignals,
            enrichedInsight: enrichedInsight
        )
    }

    func withReflectData(_ reflectData: ReflectData) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: id, date: date, smileyState: smileyState, meals: meals,
            mealCount: mealCount, averageHealthScore: averageHealthScore,
            reflection: reflection, morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck, highlightData: highlightData,
            reflectData: reflectData, briefing: briefing, insight: insight,
            totalCalories: totalCalories, hasCompleteCalorieData: hasCompleteCalorieData,
            wellbeingDimensions: wellbeingDimensions, textSignals: textSignals,
            enrichedInsight: enrichedInsight
        )
    }

    func withBriefing(_ briefing: DailyBriefing) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: id, date: date, smileyState: smileyState, meals: meals,
            mealCount: mealCount, averageHealthScore: averageHealthScore,
            reflection: reflection, morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck, highlightData: highlightData,
            reflectData: reflectData, briefing: briefing, insight: insight,
            totalCalories: totalCalories, hasCompleteCalorieData: hasCompleteCalorieData,
            wellbeingDimensions: wellbeingDimensions, textSignals: textSignals,
            enrichedInsight: enrichedInsight
        )
    }

    func withInsight(_ insight: LegacyDailyInsight) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: id, date: date, smileyState: smileyState, meals: meals,
            mealCount: mealCount, averageHealthScore: averageHealthScore,
            reflection: reflection, morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck, highlightData: highlightData,
            reflectData: reflectData, briefing: briefing, insight: insight,
            totalCalories: totalCalories, hasCompleteCalorieData: hasCompleteCalorieData,
            wellbeingDimensions: wellbeingDimensions, textSignals: textSignals,
            enrichedInsight: enrichedInsight
        )
    }

    func withTotalCalories(_ calories: Int, hasCompleteCalorieData: Bool) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: id, date: date, smileyState: smileyState, meals: meals,
            mealCount: mealCount, averageHealthScore: averageHealthScore,
            reflection: reflection, morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck, highlightData: highlightData,
            reflectData: reflectData, briefing: briefing, insight: insight,
            totalCalories: calories, hasCompleteCalorieData: hasCompleteCalorieData,
            wellbeingDimensions: wellbeingDimensions, textSignals: textSignals,
            enrichedInsight: enrichedInsight
        )
    }

    func withWellbeingDimensions(_ dimensions: WellbeingDimensions) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: id, date: date, smileyState: smileyState, meals: meals,
            mealCount: mealCount, averageHealthScore: averageHealthScore,
            reflection: reflection, morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck, highlightData: highlightData,
            reflectData: reflectData, briefing: briefing, insight: insight,
            totalCalories: totalCalories, hasCompleteCalorieData: hasCompleteCalorieData,
            wellbeingDimensions: dimensions, textSignals: textSignals,
            enrichedInsight: enrichedInsight
        )
    }

    func withTextSignals(_ signals: [TextSignal]) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: id, date: date, smileyState: smileyState, meals: meals,
            mealCount: mealCount, averageHealthScore: averageHealthScore,
            reflection: reflection, morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck, highlightData: highlightData,
            reflectData: reflectData, briefing: briefing, insight: insight,
            totalCalories: totalCalories, hasCompleteCalorieData: hasCompleteCalorieData,
            wellbeingDimensions: wellbeingDimensions, textSignals: signals,
            enrichedInsight: enrichedInsight
        )
    }

    func withEnrichedInsight(_ enrichedInsight: EnrichedDailyInsight) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: id, date: date, smileyState: smileyState, meals: meals,
            mealCount: mealCount, averageHealthScore: averageHealthScore,
            reflection: reflection, morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck, highlightData: highlightData,
            reflectData: reflectData, briefing: briefing, insight: insight,
            totalCalories: totalCalories, hasCompleteCalorieData: hasCompleteCalorieData,
            wellbeingDimensions: wellbeingDimensions, textSignals: textSignals,
            enrichedInsight: enrichedInsight
        )
    }
}
