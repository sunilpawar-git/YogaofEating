import Foundation

/// Composite daily intelligence score derived from key wellness dimensions.
struct BodyIntelligenceScore: Equatable, Codable {
    /// Final score, clamped to [0, 100].
    let value: Double

    /// Day-ring module contribution in [0, 100].
    let moduleContribution: Double

    /// Sleep contribution in [0, 100].
    let sleepContribution: Double

    /// Meal quality contribution in [0, 100].
    let nutritionContribution: Double

    /// Todo execution contribution in [0, 100].
    let executionContribution: Double

    init(
        value: Double,
        moduleContribution: Double,
        sleepContribution: Double,
        nutritionContribution: Double,
        executionContribution: Double
    ) {
        self.value = Self.clamp(value)
        self.moduleContribution = Self.clamp(moduleContribution)
        self.sleepContribution = Self.clamp(sleepContribution)
        self.nutritionContribution = Self.clamp(nutritionContribution)
        self.executionContribution = Self.clamp(executionContribution)
    }

    static let zero = BodyIntelligenceScore(
        value: 0,
        moduleContribution: 0,
        sleepContribution: 0,
        nutritionContribution: 0,
        executionContribution: 0
    )

    private static func clamp(_ value: Double) -> Double {
        min(100, max(0, value))
    }
}
