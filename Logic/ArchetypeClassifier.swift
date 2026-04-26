import Foundation

enum ArchetypeClassifier {
    private static let windowDays = 14

    static func classify(snapshots: [DailySmileySnapshot]) -> EnergyArchetype {
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.windowDays, to: Date()) ?? Date()
        let recent = snapshots
            .filter { $0.date >= Calendar.current.startOfDay(for: cutoff) }
            .sorted { $0.date < $1.date }

        guard recent.count >= 5 else { return .inconsistent }

        let mealHours = recent.flatMap { $0.meals.map { Calendar.current.component(.hour, from: $0.timestamp) } }
        let avgMealHour = mealHours.isEmpty ? 12 : Double(mealHours.reduce(0, +)) / Double(mealHours.count)
        let mealVariance = variance(of: mealHours.map(Double.init))

        let focusValues = recent.compactMap { $0.reflection?.focusRating.map(Double.init) }
        let focusVariance = variance(of: focusValues)
        let focusMean = focusValues.isEmpty ? 0 : focusValues.reduce(0, +) / Double(focusValues.count)

        if focusVariance > 0.5 {
            return .spikeDip
        }
        if avgMealHour >= 20 {
            return .nocturnalOwl
        }
        if avgMealHour <= 13 {
            return .earlyBird
        }
        if mealVariance < 4, focusVariance < 0.3, focusMean >= 2 {
            return .steadyState
        }
        return .inconsistent
    }
}

private extension ArchetypeClassifier {
    static func variance(of values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squared = values.map { pow($0 - mean, 2) }.reduce(0, +)
        return squared / Double(values.count)
    }
}
