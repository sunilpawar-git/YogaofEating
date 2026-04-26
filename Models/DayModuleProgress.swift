import Foundation

/// Tracks completion progress for each of the four daily modules.
/// Used as the data backbone for the Day Ring UI.
///
/// Modules:
/// - **Reflect**: Morning planning (sleep quality, energy, intention)
/// - **Laser**: Daytime execution (meals logged, todos reviewed, focus rating)
/// - **Highlight**: Evening reflection (feeling, evening entries, observation)
/// - **Energise**: Recovery wellness (sleep quality, nutrition data)
struct DayModuleProgress: Equatable {
    /// Morning planning completeness (0.0 - 1.0)
    let reflectProgress: Double

    /// Daytime execution tracking (0.0 - 1.0)
    let laserProgress: Double

    /// Evening reflection completeness (0.0 - 1.0)
    let highlightProgress: Double

    /// Recovery and wellness data (0.0 - 1.0)
    let energiseProgress: Double

    /// Average of all four module progresses (0.0 - 1.0)
    var overallProgress: Double {
        (self.reflectProgress + self.laserProgress +
            self.highlightProgress + self.energiseProgress) / 4.0
    }

    // MARK: - Initialization

    init(
        reflectProgress: Double,
        laserProgress: Double,
        highlightProgress: Double,
        energiseProgress: Double
    ) {
        self.reflectProgress = min(1.0, max(0.0, reflectProgress))
        self.laserProgress = min(1.0, max(0.0, laserProgress))
        self.highlightProgress = min(1.0, max(0.0, highlightProgress))
        self.energiseProgress = min(1.0, max(0.0, energiseProgress))
    }

    // MARK: - Factory

    /// Computes module progress from a day's snapshot data.
    static func compute(from snapshot: DailySmileySnapshot) -> DayModuleProgress {
        DayModuleProgress(
            reflectProgress: computeReflect(from: snapshot),
            laserProgress: computeLaser(from: snapshot),
            highlightProgress: computeHighlight(from: snapshot),
            energiseProgress: computeEnergise(from: snapshot)
        )
    }

    /// Empty progress (all zeros)
    static let empty = DayModuleProgress(
        reflectProgress: 0,
        laserProgress: 0,
        highlightProgress: 0,
        energiseProgress: 0
    )
}

// MARK: - Module Computation

extension DayModuleProgress {
    /// Reflect: sleep quality (+0.33) + energy level (+0.33) + intention (+0.34)
    private static func computeReflect(from snapshot: DailySmileySnapshot) -> Double {
        var score = 0.0
        if let reflection = snapshot.reflection {
            if reflection.sleepQuality != nil { score += 0.33 }
            if reflection.morningEnergyLevel != nil { score += 0.33 }
            if reflection.dailyIntention != nil { score += 0.34 }
        }
        return score
    }

    /// Laser: meals logged (+0.34) + todos reviewed (+0.33) + focus rating (+0.33)
    private static func computeLaser(from snapshot: DailySmileySnapshot) -> Double {
        var score = 0.0
        if !snapshot.meals.isEmpty { score += 0.34 }
        if Self.hasTodosReviewed(snapshot) { score += 0.33 }
        if snapshot.reflection?.focusRating != nil { score += 0.33 }
        return score
    }

    /// Highlight: evening feeling (+0.34) + evening entries (+0.33) + observation (+0.33)
    private static func computeHighlight(from snapshot: DailySmileySnapshot) -> Double {
        var score = 0.0
        if snapshot.reflection?.feeling != nil { score += 0.34 }
        if snapshot.hasEveningMindCheck { score += 0.33 }
        if Self.hasObservation(snapshot) { score += 0.33 }
        return score
    }

    private static func hasObservation(_ snapshot: DailySmileySnapshot) -> Bool {
        snapshot.eveningMindCheck?.contains { $0.category == .observation } ?? false
    }

    /// Energise: sleep quality (+0.5) + meals/nutrition logged (+0.5)
    private static func computeEnergise(from snapshot: DailySmileySnapshot) -> Double {
        var score = 0.0
        if snapshot.reflection?.sleepQuality != nil { score += 0.5 }
        if !snapshot.meals.isEmpty { score += 0.5 }
        return score
    }

    /// Returns true if at least one todo has been reviewed (isAccomplished is non-nil).
    private static func hasTodosReviewed(_ snapshot: DailySmileySnapshot) -> Bool {
        guard let entries = snapshot.morningMindCheck else { return false }
        let todos = entries.filter { $0.category == .todo }
        guard !todos.isEmpty else { return false }
        return todos.contains { $0.isAccomplished != nil }
    }
}
