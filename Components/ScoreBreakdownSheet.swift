import Combine
import OSLog
import SwiftUI

private let scoreLogger = Logger(subsystem: "com.yogaofeating", category: "Score")

// MARK: - ViewModel

/// ViewModel for the score breakdown sheet
@MainActor
class ScoreBreakdownViewModel: ObservableObject {
    let meal: Meal

    @Published var detailedInsight: DetailedMealInsight?
    @Published var isLoadingDetailedInsight: Bool = false
    @Published var detailedInsightError: String?

    /// Service for fetching detailed insights
    private var insightProvider: MealInsightProvider?

    init(meal: Meal, insightProvider: MealInsightProvider? = nil) {
        self.meal = meal
        // Use AILogicService as default if Firebase is available
        if let provider = insightProvider {
            self.insightProvider = provider
        } else {
            self.insightProvider = AILogicService()
        }
    }

    /// Formatted score as percentage string
    var formattedScore: String {
        "\(Int(self.meal.healthScore * 100))%"
    }

    /// Meal description from items
    var mealDescription: String {
        self.meal.items.isEmpty ? "No items logged" : self.meal.items.joined(separator: ", ")
    }

    /// Score category (excellent, good, moderate, poor)
    var category: ScoreCategory {
        ScoreReasoningGenerator.scoreCategory(for: self.meal.healthScore)
    }

    /// The insight to display - uses AI insight if available, falls back to template
    var displayInsight: String {
        // Priority 1: Detailed AI insight summary
        if let detailed = detailedInsight {
            return detailed.summary
        }
        // Priority 2: Basic AI insight stored in meal
        if let aiInsight = meal.aiInsight, !aiInsight.isEmpty {
            return aiInsight
        }
        // Priority 3: Template-based reasoning
        return ScoreReasoningGenerator.generateReasoning(for: self.meal)
    }

    /// Whether there's an insight to display
    var hasInsight: Bool {
        !self.displayInsight.isEmpty
    }

    /// Nutrition highlights from detailed insight
    var nutritionHighlights: [String] {
        self.detailedInsight?.nutritionHighlights ?? []
    }

    /// Health tip from detailed insight
    var healthTip: String? {
        self.detailedInsight?.tip
    }

    /// Whether we have detailed insight loaded
    var hasDetailedInsight: Bool {
        self.detailedInsight != nil
    }

    /// Fetches detailed insight from Gemini LLM
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
            scoreLogger.error("Failed to fetch detailed insight: \(error.localizedDescription, privacy: .public)")
            self.detailedInsightError = "Couldn't load detailed analysis"
        }

        self.isLoadingDetailedInsight = false
    }
}

// MARK: - View

/// Bottom sheet showing detailed score breakdown for a meal
struct ScoreBreakdownSheet: View {
    let meal: Meal
    let onDismiss: () -> Void

    @StateObject private var viewModel: ScoreBreakdownViewModel

    init(meal: Meal, onDismiss: @escaping () -> Void) {
        self.meal = meal
        self.onDismiss = onDismiss
        self._viewModel = StateObject(wrappedValue: ScoreBreakdownViewModel(meal: meal))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Score circle
                    self.scoreCircle

                    // Meal info
                    self.mealInfoSection

                    // AI Insight section
                    if self.viewModel.hasInsight {
                        self.insightSection
                    }

                    // Nutrition highlights (if detailed insight loaded)
                    if !self.viewModel.nutritionHighlights.isEmpty {
                        self.nutritionSection
                    }

                    // Health tip (if available)
                    if let tip = self.viewModel.healthTip {
                        self.tipSection(tip: tip)
                    }

                    // Load more details button
                    if !self.viewModel.hasDetailedInsight, self.meal.isAIAnalyzed {
                        self.loadDetailsButton
                    }

                    Spacer(minLength: 20)

                    // Dismiss button
                    self.dismissButton
                }
                .padding(24)
            }
            .navigationTitle("Score Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Subviews

    private var scoreCircle: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: self.meal.healthScore)
                    .stroke(self.scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Text(self.viewModel.formattedScore)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Health score \(self.viewModel.formattedScore)")

            HStack(spacing: 4) {
                Text(self.viewModel.category.emoji)
                Text(self.viewModel.category.rawValue)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Rating: \(self.viewModel.category.rawValue)")
        }
    }

    private var mealInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: self.meal.mealType.iconName)
                    .foregroundStyle(self.meal.mealType.displayColor)
                Text(self.meal.mealType.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text(self.viewModel.mealDescription)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("✨")
                Text("AI Analysis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Text(self.viewModel.displayInsight)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nutrition Highlights")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            ForEach(self.viewModel.nutritionHighlights, id: \.self) { highlight in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(self.scoreColor)
                    Text(highlight)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    private func tipSection(tip: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("💡")
                Text("Tip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Text(tip)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(self.scoreColor.opacity(0.1))
        )
    }

    private var loadDetailsButton: some View {
        Button {
            Task {
                await self.viewModel.fetchDetailedInsight()
            }
        } label: {
            HStack {
                if self.viewModel.isLoadingDetailedInsight {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(self.viewModel.isLoadingDetailedInsight ? "Loading..." : "Get Detailed Analysis")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(self.scoreColor)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(self.scoreColor, lineWidth: 1)
            )
        }
        .disabled(self.viewModel.isLoadingDetailedInsight)
        .buttonStyle(.plain)
    }

    private var dismissButton: some View {
        Button {
            self.onDismiss()
        } label: {
            Text("Got it")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(self.scoreColor)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dismiss score details")
    }

    // MARK: - Helpers

    private var scoreColor: Color {
        switch self.viewModel.category {
        case .excellent:
            AppTheme.ScoreColors.excellent
        case .good:
            AppTheme.ScoreColors.good
        case .moderate:
            AppTheme.ScoreColors.moderate
        case .poor:
            AppTheme.ScoreColors.poor
        }
    }
}

// MARK: - Previews

#Preview("High Score with AI Insight") {
    ScoreBreakdownSheet(
        meal: Meal(
            mealType: .lunch,
            items: ["Grilled salmon", "Steamed broccoli", "Brown rice"],
            healthScore: 0.9,
            isAIAnalyzed: true,
            aiInsight: "Excellent protein-rich meal with omega-3 fatty acids and fiber from vegetables."
        ),
        onDismiss: {}
    )
}

#Preview("Medium Score") {
    ScoreBreakdownSheet(
        meal: Meal(
            mealType: .dinner,
            items: ["Pasta with cream sauce", "Garlic bread"],
            healthScore: 0.55,
            isAIAnalyzed: true
        ),
        onDismiss: {}
    )
}

#Preview("Low Score") {
    ScoreBreakdownSheet(
        meal: Meal(
            mealType: .snacks,
            items: ["Chips", "Soda", "Candy bar"],
            healthScore: 0.2,
            isAIAnalyzed: true
        ),
        onDismiss: {}
    )
}
