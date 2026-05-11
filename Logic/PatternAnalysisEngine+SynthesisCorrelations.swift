import Foundation

/// Five synthesis-aware correlation algorithms added in Phase 4.
/// Consumes `wellbeingDimensions` and `textSignals` stored in snapshots.
/// All methods operate on `[DailySmileySnapshot]` and return `[CorrelationCard]`.
extension PatternAnalysisEngine {
    // MARK: - 1. Sleep Recovery Carryover

    /// Detects two consecutive nights of poor subjective sleep (proxy for HealthKit efficiency).
    func analyzeSleepRecoveryCarryover(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let sorted = snapshots.sorted { $0.date > $1.date }
        let poorSleepDates = sorted.filter { snap in
            guard let q = snap.highlightData?.sleepQuality else { return false }
            return q == .poor || q == .terrible
        }

        guard poorSleepDates.count >= 2 else { return [] }

        let calendar = Calendar.current
        var consecutivePairs: [(DailySmileySnapshot, DailySmileySnapshot)] = []
        for i in 0..<(poorSleepDates.count - 1) {
            let a = poorSleepDates[i]
            let b = poorSleepDates[i + 1]
            if let diff = calendar.dateComponents([.day], from: b.date, to: a.date).day, diff == 1 {
                consecutivePairs.append((a, b))
            }
        }
        guard !consecutivePairs.isEmpty else { return [] }

        let refs = consecutivePairs.flatMap { a, b in [
            InsightReference(date: a.date, description: "Poor sleep", category: .sleep),
            InsightReference(date: b.date, description: "Poor sleep", category: .sleep)
        ] }.prefix(BriefingThresholds.maximumInsightReferences)

        let confidence = min(1.0, Double(consecutivePairs.count) / 3.0 + 0.6)
        return [CorrelationCard(
            category: .sleepRecoveryCarryover,
            observation: "Two consecutive poor-sleep nights — cognitive clarity may be reduced today",
            confidence: confidence,
            dataPoints: Array(refs)
        )]
    }

    // MARK: - 2. Intention-Followthrough Gap

    /// Detects days with many unaccomplished todos — a behavioural momentum leak signal.
    func analyzeIntentionFollowthrough(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let gapDays: [DailySmileySnapshot] = snapshots.filter { snap in
            guard let todos = snap.highlightData?.todos,
                  todos.count >= BriefingThresholds.minimumTodosForFollowthrough else { return false }
            let accomplishedCount = todos.count(where: { $0.isAccomplished == true })
            let rate = Double(accomplishedCount) / Double(todos.count)
            return rate < BriefingThresholds.lowFollowthroughRate
        }

        guard !gapDays.isEmpty else { return [] }

        let avgRate = gapDays.map { snap -> Double in
            let todos = snap.highlightData?.todos ?? []
            guard !todos.isEmpty else { return 0 }
            return Double(todos.count(where: { $0.isAccomplished == true })) / Double(todos.count)
        }.reduce(0, +) / Double(gapDays.count)

        let confidence = min(1.0, (BriefingThresholds.lowFollowthroughRate - avgRate) * 2.0 + 0.5)
        let refs = gapDays.prefix(BriefingThresholds.maximumInsightReferences).map {
            InsightReference(date: $0.date, description: "Low todo completion", category: .todo)
        }

        return [CorrelationCard(
            category: .intentionFollowthrough,
            observation: "Morning intentions are often unmet — consider setting fewer, more focused goals",
            confidence: max(0, min(1, confidence)),
            dataPoints: Array(refs)
        )]
    }

    // MARK: - 3. Journal Tone → Next-Day Wellbeing Prediction

    /// Detects negative evening signals followed by reduced wellbeing the next day.
    func analyzeJournalTonePrediction(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let sorted = snapshots.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return [] }

        let negativeTones: Set<TextSignal> = [.overwhelmed, .stressed]
        var matchCount = 0
        var totalPairs = 0
        var refs: [InsightReference] = []

        let calendar = Calendar.current
        for i in 0..<(sorted.count - 1) {
            let eve = sorted[i]
            let next = sorted[i + 1]
            guard calendar.dateComponents([.day], from: eve.date, to: next.date).day == 1 else { continue }

            let eveSignals = Set(eve.reflectData?.textSignals ?? [])
            guard eveSignals.intersection(negativeTones).count > 0 else { continue }

            totalPairs += 1
            let nextOverall = next.wellbeingDimensions?
                .overall ?? (next.averageHealthScore > 0 ? next.averageHealthScore : 0.5)
            if nextOverall < BriefingThresholds.carryOverLowThreshold {
                matchCount += 1
                if refs.count < BriefingThresholds.maximumInsightReferences {
                    refs.append(InsightReference(
                        date: eve.date,
                        description: "Negative journal tone",
                        category: .feeling
                    ))
                }
            }
        }

        guard totalPairs > 0 else { return [] }
        let confidence = Double(matchCount) / Double(totalPairs)
        guard confidence >= BriefingThresholds.confidenceThreshold else { return [] }

        return [CorrelationCard(
            category: .journalTonePrediction,
            observation: "Evenings with overwhelming feelings tend to lower next-day wellbeing",
            confidence: confidence,
            dataPoints: refs
        )]
    }

    // MARK: - 4. Subjective vs Objective Sleep Mismatch

    /// Detects days where the user rates sleep great but synthesis shows low cognitive clarity.
    func analyzeSleepMismatch(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let mismatchDays = snapshots.filter { snap in
            guard let quality = snap.highlightData?.sleepQuality, quality == .great else { return false }
            let clarity = snap.wellbeingDimensions?.cognitiveClarity ?? 0.5
            return clarity < BriefingThresholds.sleepMismatchClarityThreshold
        }

        guard !mismatchDays.isEmpty else { return [] }

        let refs = mismatchDays.prefix(BriefingThresholds.maximumInsightReferences).map {
            InsightReference(date: $0.date, description: "Sleep rating vs clarity gap", category: .sleep)
        }
        let confidence = min(1.0, Double(mismatchDays.count) / 3.0 + 0.55)

        return [CorrelationCard(
            category: .sleepMismatch,
            observation: "You rated sleep as great, but your clarity pattern suggests otherwise — check your sleep environment",
            confidence: confidence,
            dataPoints: Array(refs)
        )]
    }

    // MARK: - 5. Carry-Over Load

    /// Detects 3+ consecutive low-wellbeing days — a systemic pattern, not a bad day.
    func analyzeCarryOverLoad(from snapshots: [DailySmileySnapshot]) -> [CorrelationCard] {
        let lowDays = snapshots.filter { snap in
            if let dims = snap.wellbeingDimensions {
                return dims.overall < BriefingThresholds.carryOverLowThreshold
            }
            return snap.mealCount > 0 && snap.averageHealthScore < BriefingThresholds.carryOverLowThreshold
        }

        guard lowDays.count >= BriefingThresholds.carryOverLoadDays else { return [] }

        let refs = lowDays.prefix(BriefingThresholds.maximumInsightReferences).map {
            InsightReference(date: $0.date, description: "Low wellbeing day", category: .food)
        }
        let confidence = min(1.0, Double(lowDays.count) / 7.0 + 0.5)

        return [CorrelationCard(
            category: .carryOverLoad,
            observation: "You have had \(lowDays.count) low-wellbeing days recently — this is a pattern worth addressing",
            confidence: confidence,
            dataPoints: Array(refs)
        )]
    }
}
