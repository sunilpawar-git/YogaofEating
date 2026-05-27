import Foundation

// MARK: - Protocol

protocol DailySynthesizing {
    func synthesize(
        meals: [Meal],
        highlightData: HighlightData?,
        reflectData: ReflectData?,
        appleSleepData: SleepData?,
        yesterday: DailySmileySnapshot?,
        activeCaloriesBurned: Double?
    ) -> DailySynthesis
}

// MARK: - Backward-compat shim (omits activeCaloriesBurned → nil)

extension DailySynthesizing {
    func synthesize(
        meals: [Meal],
        highlightData: HighlightData?,
        reflectData: ReflectData?,
        appleSleepData: SleepData?,
        yesterday: DailySmileySnapshot?
    ) -> DailySynthesis {
        self.synthesize(
            meals: meals,
            highlightData: highlightData,
            reflectData: reflectData,
            appleSleepData: appleSleepData,
            yesterday: yesterday,
            activeCaloriesBurned: nil
        )
    }
}

// MARK: - Implementation

final class DailySynthesisEngine: DailySynthesizing {
    func synthesize(
        meals: [Meal],
        highlightData: HighlightData?,
        reflectData: ReflectData?,
        appleSleepData: SleepData?,
        yesterday _: DailySmileySnapshot?,
        activeCaloriesBurned: Double? = nil
    ) -> DailySynthesis {
        let physical = self.computePhysicalLoad(from: meals, activeCaloriesBurned: activeCaloriesBurned)
        let emotional = self.computeEmotionalTone(from: reflectData)
        let cognitive = self.computeCognitiveClarity(from: highlightData, appleSleepData: appleSleepData)
        let behavioral = self.computeBehavioralMomentum(from: highlightData)

        let hasSleepData = highlightData?.sleepQuality != nil || appleSleepData != nil
        let hasFeelingData = reflectData?.feeling != nil
            || (reflectData?.textSignals?.isEmpty == false && reflectData?.textSignals != [.neutral])
        let hasTodoData = !(highlightData?.todos.isEmpty ?? true)
        let hasMealData = !meals.isEmpty

        let overall = self.weightedOverall(
            physical: physical, emotional: emotional,
            cognitive: cognitive, behavioral: behavioral,
            hasMealData: hasMealData, hasSleepData: hasSleepData,
            hasFeelingData: hasFeelingData, hasTodoData: hasTodoData
        )

        let dimensions = WellbeingDimensions(
            physicalLoad: physical,
            emotionalTone: emotional,
            cognitiveClarity: cognitive,
            behavioralMomentum: behavioral
        )

        let dominant = self.dominantDimension(
            physical: physical, emotional: emotional,
            cognitive: cognitive, behavioral: behavioral,
            hasMealData: hasMealData, hasSleepData: hasSleepData,
            hasFeelingData: hasFeelingData, hasTodoData: hasTodoData
        )

        var completeness = Set<WellbeingDimension>()
        if hasMealData { completeness.insert(.physicalLoad) }
        if hasSleepData { completeness.insert(.cognitiveClarity) }
        if hasFeelingData { completeness.insert(.emotionalTone) }
        if hasTodoData { completeness.insert(.behavioralMomentum) }

        let signals = self.collectSignals(from: highlightData, reflectData: reflectData)
        let smiley = self.smileySuggestion(overall: overall)
        let dominantScore = dominant.value(in: dimensions)
        let context = NarrativeContext(mealCount: meals.count, avgMealScore: physical)
        let narrative = completeness.isEmpty
            ? Strings.Synthesis.CausalNarrative.noData
            : self.causalNarrative(for: dominant, score: dominantScore, context: context)

        return DailySynthesis(
            dimensions: dimensions,
            dataCompleteness: completeness,
            textSignals: signals,
            smileySuggestion: smiley,
            dominantDimension: dominant,
            causalNarrative: narrative
        )
    }

    // MARK: - Dimension Computations

    private func computePhysicalLoad(from meals: [Meal], activeCaloriesBurned: Double?) -> Double {
        let base: Double = meals.isEmpty
            ? 0.5
            : meals.map(\.healthScore).reduce(0.0, +) / Double(meals.count)
        return min(base + self.computeExerciseBonus(activeCaloriesBurned), 1.0)
    }

    private func computeExerciseBonus(_ activeCalories: Double?) -> Double {
        guard let kcal = activeCalories else { return 0.0 }
        switch kcal {
        case ..<ExerciseBonusTiers.tier1Threshold: return 0.0
        case ..<ExerciseBonusTiers.tier2Threshold: return ExerciseBonusTiers.tier1Bonus
        case ..<ExerciseBonusTiers.tier3Threshold: return ExerciseBonusTiers.tier2Bonus
        default: return ExerciseBonusTiers.max
        }
    }

    private func computeEmotionalTone(from reflectData: ReflectData?) -> Double {
        var score = 0.5
        var components = 0

        if let feeling = reflectData?.feeling {
            score += self.feelingScore(feeling) - 0.5
            components += 1
        }
        if let signals = reflectData?.textSignals, signals != [.neutral] {
            let signalScore = self.sentimentFromSignals(signals)
            score += signalScore - 0.5
            components += 1
        }

        return components > 0 ? min(max(score, 0), 1) : 0.5
    }

    private func computeCognitiveClarity(from highlightData: HighlightData?, appleSleepData: SleepData?) -> Double {
        var scores: [Double] = []

        if let quality = highlightData?.sleepQuality {
            scores.append(self.sleepQualityScore(quality))
        }
        if let healthKitScore = appleSleepData?.sleepScore {
            scores.append(Double(healthKitScore) / 100.0)
        }

        guard !scores.isEmpty else { return 0.5 }
        return scores.reduce(0.0, +) / Double(scores.count)
    }

    private func computeBehavioralMomentum(from highlightData: HighlightData?) -> Double {
        guard let todos = highlightData?.todos, !todos.isEmpty else { return 0.5 }
        let accomplished = todos.count(where: { $0.isAccomplished == true })
        return accomplished > 0 ? Double(accomplished) / Double(todos.count) : 0.1
    }

    // MARK: - Weighted Overall (only counts streams with real data)

    private func weightedOverall(
        physical: Double, emotional: Double, cognitive: Double, behavioral: Double,
        hasMealData: Bool, hasSleepData: Bool, hasFeelingData: Bool, hasTodoData: Bool
    ) -> Double {
        var total = 0.0
        var weight = 0.0

        if hasMealData {
            total += physical * SynthesisWeights.physicalLoad
            weight += SynthesisWeights.physicalLoad
        }
        if hasSleepData {
            total += cognitive * SynthesisWeights.cognitiveClarity
            weight += SynthesisWeights.cognitiveClarity
        }
        if hasFeelingData {
            total += emotional * SynthesisWeights.emotionalTone
            weight += SynthesisWeights.emotionalTone
        }
        if hasTodoData {
            total += behavioral * SynthesisWeights.behavioralMomentum
            weight += SynthesisWeights.behavioralMomentum
        }

        return weight > 0 ? total / weight : 0.5
    }

    // MARK: - Dominant Dimension

    private func dominantDimension(
        physical: Double, emotional: Double, cognitive: Double, behavioral: Double,
        hasMealData: Bool, hasSleepData: Bool, hasFeelingData: Bool, hasTodoData: Bool
    ) -> WellbeingDimension {
        var candidates: [(WellbeingDimension, Double)] = []
        if hasMealData { candidates.append((.physicalLoad, abs(physical - 0.5))) }
        if hasSleepData { candidates.append((.cognitiveClarity, abs(cognitive - 0.5))) }
        if hasFeelingData { candidates.append((.emotionalTone, abs(emotional - 0.5))) }
        if hasTodoData { candidates.append((.behavioralMomentum, abs(behavioral - 0.5))) }

        return candidates.max(by: { $0.1 < $1.1 })?.0 ?? .physicalLoad
    }

    // MARK: - Smiley Suggestion

    private func smileySuggestion(overall: Double) -> SmileyState {
        let (mood, scale): (SmileyMood, Double) = if overall > SynthesisThresholds.overallHealthy {
            (.serene, SynthesisScaleTargets.serene)
        } else if overall > SynthesisThresholds.overallNeutral {
            (.neutral, SynthesisScaleTargets.neutral)
        } else if overall > SynthesisThresholds.overallThoughtful {
            (.thoughtful, SynthesisScaleTargets.thoughtful)
        } else {
            (.overwhelmed, SynthesisScaleTargets.overwhelmed)
        }
        return SmileyState(scale: scale, mood: mood)
    }

    // MARK: - Causal Narrative

    private func causalNarrative(for dominant: WellbeingDimension, score: Double, context: NarrativeContext) -> String {
        CausalNarrativeResolver.resolve(dimension: dominant, score: score, context: context)
    }

    // MARK: - Private Helpers

    private func collectSignals(from highlightData: HighlightData?, reflectData: ReflectData?) -> [TextSignal] {
        let morning = highlightData?.textSignals ?? []
        let evening = reflectData?.textSignals ?? []
        // Use Set for deduplication, then sort by rawValue for deterministic ordering.
        let combined = Set(morning + evening)
        return combined.isEmpty ? [.neutral] : combined.sorted { $0.rawValue < $1.rawValue }
    }

    private func feelingScore(_ feeling: ReflectionFeeling) -> Double {
        feeling.synthesisScore
    }

    private func sleepQualityScore(_ quality: SleepQuality) -> Double {
        quality.synthesisScore
    }

    private func sentimentFromSignals(_ signals: [TextSignal]) -> Double {
        let positives: Set<TextSignal> = [.grateful, .clear, .agentive, .selfCompassionate]
        let negatives: Set<TextSignal> = [.stressed, .overwhelmed]
        let posCount = Double(signals.count(where: { positives.contains($0) }))
        let negCount = Double(signals.count(where: { negatives.contains($0) }))
        let total = posCount + negCount
        guard total > 0 else { return 0.5 }
        return min(max((posCount - negCount) / total * 0.5 + 0.5, 0), 1)
    }
}
