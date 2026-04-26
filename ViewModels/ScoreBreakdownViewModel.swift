import Combine
import Foundation

@MainActor
class ScoreBreakdownViewModel: ObservableObject {
    let meal: Meal

    @Published var detailedInsight: DetailedMealInsight?
    @Published var isLoadingDetailedInsight: Bool = false
    @Published var detailedInsightError: String?

    private var insightProvider: MealInsightProvider?

    init(meal: Meal, insightProvider: MealInsightProvider? = nil) {
        self.meal = meal
        if let provider = insightProvider {
            self.insightProvider = provider
        } else {
            self.insightProvider = AILogicService()
        }
    }

    var formattedScore: String {
        "\(Int(self.meal.healthScore * 100))%"
    }

    var mealDescription: String {
        self.meal.items.isEmpty ? "No items logged" : self.meal.items.joined(separator: ", ")
    }

    var category: ScoreCategory {
        ScoreReasoningGenerator.scoreCategory(for: self.meal.healthScore)
    }

    var displayInsight: String {
        if let detailed = detailedInsight {
            return detailed.summary
        }
        if let aiInsight = meal.aiInsight, !aiInsight.isEmpty {
            return aiInsight
        }
        return ScoreReasoningGenerator.generateReasoning(for: self.meal)
    }

    var hasInsight: Bool {
        !self.displayInsight.isEmpty
    }

    var nutritionHighlights: [String] {
        self.detailedInsight?.nutritionHighlights ?? []
    }

    var healthTip: String? {
        self.detailedInsight?.tip
    }

    var hasDetailedInsight: Bool {
        self.detailedInsight != nil
    }

    func fetchDetailedInsight() async {
        guard !self.isLoadingDetailedInsight, self.detailedInsight == nil else { return }

        self.isLoadingDetailedInsight = true
        self.detailedInsightError = nil

        do {
            if let provider = insightProvider {
                let insight = try await provider.getDetailedInsight(for: self.meal)
                self.detailedInsight = insight
            }
        } catch {
            print("❌ Failed to fetch detailed insight: \(error)")
            self.detailedInsightError = "Couldn't load detailed analysis"
        }

        self.isLoadingDetailedInsight = false
    }
}
