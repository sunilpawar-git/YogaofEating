import SwiftUI

/// Card body for the Energise module.
/// Shows meal summary (max 3), meal count, and log meal CTA.
struct EnergiseCardBody: View {
    let dataSource: ModuleCardDataSource

    private var visibleMeals: [Meal] {
        Array(self.dataSource.cardMeals.prefix(AppTheme.Card.maxVisibleMeals))
    }

    private var overflowCount: Int {
        max(0, self.dataSource.cardMeals.count - AppTheme.Card.maxVisibleMeals)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            if self.dataSource.shouldShowLogMealPrompt {
                self.logMealButton
            } else {
                self.mealList
                if self.overflowCount > 0 {
                    self.overflowLabel
                }
                self.mealCountLabel
            }
        }
    }
}

// MARK: - Subviews

private extension EnergiseCardBody {
    var mealList: some View {
        ForEach(self.visibleMeals) { meal in
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.ScoreColors.healthScoreColor(for: meal.healthScore))
                    .frame(width: 8, height: 8)
                Text(meal.description)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
        }
    }

    var overflowLabel: some View {
        Text("+\(self.overflowCount) more")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    var mealCountLabel: some View {
        Text(Strings.Home.mealsLoggedCount(self.dataSource.cardMeals.count))
            .font(.caption)
            .foregroundColor(.secondary)
    }

    var logMealButton: some View {
        Button {
            self.dataSource.triggerLogMeal()
        } label: {
            Label(Strings.Home.logMealPrompt, systemImage: "plus.circle")
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppTheme.ModuleColors.energise)
        }
    }
}
