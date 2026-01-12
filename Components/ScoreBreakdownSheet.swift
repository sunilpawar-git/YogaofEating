import SwiftUI

// MARK: - ViewModel

/// ViewModel for the score breakdown sheet
struct ScoreBreakdownViewModel {
    let meal: Meal

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

    /// Human-readable reasoning for the score
    var reasoning: String {
        ScoreReasoningGenerator.generateReasoning(for: self.meal)
    }

    /// Whether there's reasoning to display
    var hasReasoning: Bool {
        !self.reasoning.isEmpty
    }
}

// MARK: - View

/// Bottom sheet showing detailed score breakdown for a meal
struct ScoreBreakdownSheet: View {
    let meal: Meal
    let onDismiss: () -> Void

    private var viewModel: ScoreBreakdownViewModel {
        ScoreBreakdownViewModel(meal: self.meal)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Score circle
                self.scoreCircle

                // Meal info
                self.mealInfoSection

                // Reasoning section
                if self.viewModel.hasReasoning {
                    self.reasoningSection
                }

                Spacer()

                // Dismiss button
                self.dismissButton
            }
            .padding(24)
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
        .presentationDetents([.medium])
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
                .font(.system(size: 16, weight: .regular, design: .serif))
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

    private var reasoningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why this score?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(self.viewModel.reasoning)
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

#Preview("High Score") {
    ScoreBreakdownSheet(
        meal: Meal(
            mealType: .lunch,
            items: ["Grilled salmon", "Steamed broccoli", "Brown rice"],
            healthScore: 0.9,
            isAIAnalyzed: true
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
