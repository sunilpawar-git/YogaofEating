import SwiftUI

// MARK: - Read-Only Meal Card

/// A simplified, non-editable meal card for historical views.
struct ReadOnlyMealCardView: View {
    // MARK: - Constants

    /// Base fill color — uses semantically adaptive background for light/dark mode
    static let cardFillColor: Color = AppTheme.MealCard.background

    // MARK: - Properties

    let meal: Meal

    /// Callback when user taps the copy button to duplicate meal to today
    var onCopyMeal: ((Meal) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                MealTypeTag(mealType: self.meal.mealType)

                Spacer()

                Text(self.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !self.meal.items.isEmpty {
                Text(self.meal.items.joined(separator: ", "))
                    .font(.body)
                    .foregroundColor(.primary)
            } else {
                Text("No items logged")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }

            HStack {
                Text("\(self.meal.items.count) item\(self.meal.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Copy to today button (only if meal has items)
                if !self.meal.items.isEmpty, self.onCopyMeal != nil {
                    Button {
                        SensoryService.shared.playNudge(style: .medium)
                        self.onCopyMeal?(self.meal)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("copy-meal-button-\(self.meal.id)")
                    .accessibilityLabel("Copy meal to today")
                    .accessibilityHint("Duplicates this meal to today's log")
                }

                // Health score indicator
                Circle()
                    .fill(self.scoreColor)
                    .frame(width: 8, height: 8)

                Text("\(Int(self.meal.healthScore * 100))%")
                    .font(.caption)
                    .foregroundColor(self.scoreColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Self.cardFillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(self.cardBackground)
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(self.borderColor, lineWidth: 2)
        )
        .padding(.horizontal, 24)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self.meal.timestamp)
    }

    private var scoreColor: Color {
        if self.meal.healthScore >= ScoringThresholds.healthy { return .green }
        if self.meal.healthScore >= ScoringThresholds.neutral { return .blue }
        return .orange
    }

    private var cardBackground: Color {
        if self.meal.healthScore >= ScoringThresholds.high {
            Color.green.opacity(0.08)
        } else if self.meal.healthScore >= ScoringThresholds.unhealthy {
            Color.blue.opacity(0.05)
        } else {
            Color.orange.opacity(0.08)
        }
    }

    private var borderColor: Color {
        if self.meal.healthScore >= ScoringThresholds.high {
            Color.green.opacity(0.3)
        } else if self.meal.healthScore >= ScoringThresholds.unhealthy {
            Color.blue.opacity(0.2)
        } else {
            Color.orange.opacity(0.3)
        }
    }
}
