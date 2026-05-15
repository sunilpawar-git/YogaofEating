import Foundation

/// Snapshot update mutations for HistoricalDataService.
/// Extracted from HistoricalDataService to respect the 300-line file limit.
/// All methods follow the same pattern: update an existing snapshot or create
/// a minimal placeholder snapshot for dates that have no meal data yet.
extension HistoricalDataService {
    func updateReflection(for date: Date, reflection: DailyReflection) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withReflection(reflection))
        } else {
            self.historicalData.addOrUpdate(snapshot: Self.emptySnapshot(for: normalizedDate, reflection: reflection))
        }
        self.saveHistoricalData()
    }

    func updateMorningMindCheck(for date: Date, entries: [MindCheckEntry]) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withMindChecks(morningMindCheck: entries))
        } else {
            self.historicalData.addOrUpdate(
                snapshot: Self.emptySnapshot(for: normalizedDate, morningMindCheck: entries)
            )
        }
        self.saveHistoricalData()
    }

    func updateEveningMindCheck(for date: Date, entries: [MindCheckEntry]) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withMindChecks(eveningMindCheck: entries))
        } else {
            self.historicalData.addOrUpdate(
                snapshot: Self.emptySnapshot(for: normalizedDate, eveningMindCheck: entries)
            )
        }
        self.saveHistoricalData()
    }

    func updateHighlightData(for date: Date, data: HighlightData) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withHighlightData(data))
        } else {
            self.historicalData.addOrUpdate(snapshot: Self.emptySnapshot(for: normalizedDate, highlightData: data))
        }
        self.saveHistoricalData()
    }

    func updateReflectData(for date: Date, data: ReflectData) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withReflectData(data))
        } else {
            self.historicalData.addOrUpdate(snapshot: Self.emptySnapshot(for: normalizedDate, reflectData: data))
        }
        self.saveHistoricalData()
    }

    func updateInsight(for date: Date, insight: DailyInsight) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(snapshot: existing.withInsight(insight))
        } else {
            self.historicalData.addOrUpdate(snapshot: Self.emptySnapshot(for: normalizedDate, insight: insight))
        }
        self.saveHistoricalData()
    }

    func updateWellbeingDimensions(for date: Date, dimensions: WellbeingDimensions, textSignals: [TextSignal]) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if let existing = self.historicalData.snapshot(for: normalizedDate) {
            self.historicalData.addOrUpdate(
                snapshot: existing.withWellbeingDimensions(dimensions).withTextSignals(textSignals)
            )
        } else {
            self.historicalData.addOrUpdate(
                snapshot: Self.emptySnapshot(
                    for: normalizedDate,
                    wellbeingDimensions: dimensions,
                    textSignals: textSignals
                )
            )
        }
        self.saveHistoricalData()
    }

    // MARK: - Private factory helper

    static func emptySnapshot(
        for date: Date,
        reflection: DailyReflection? = nil,
        morningMindCheck: [MindCheckEntry]? = nil,
        eveningMindCheck: [MindCheckEntry]? = nil,
        highlightData: HighlightData? = nil,
        reflectData: ReflectData? = nil,
        insight: DailyInsight? = nil,
        wellbeingDimensions: WellbeingDimensions? = nil,
        textSignals: [TextSignal]? = nil
    ) -> DailySmileySnapshot {
        DailySmileySnapshot(
            id: UUID(),
            date: date,
            smileyState: .neutral,
            meals: [],
            mealCount: 0,
            averageHealthScore: 0.5,
            reflection: reflection,
            morningMindCheck: morningMindCheck,
            eveningMindCheck: eveningMindCheck,
            highlightData: highlightData,
            reflectData: reflectData,
            wellbeingDimensions: wellbeingDimensions,
            textSignals: textSignals,
            insight: insight
        )
    }
}
