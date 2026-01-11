import SwiftUI

/// A reusable sheet view for displaying and selecting from recent meals.
/// Extracted from JournalBlockView to reduce file size and improve reusability.
struct RecentMealsSheetView: View {
    /// The list of recent meals to display
    let recentMeals: [Meal]

    /// Callback when a meal is selected
    let onSelectMeal: (Meal) -> Void

    /// Callback when the sheet is dismissed
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if self.recentMeals.isEmpty {
                    self.emptyStateView
                } else {
                    ForEach(self.recentMeals) { meal in
                        self.mealRow(for: meal)
                    }
                }
            }
            .navigationTitle("Recent Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        self.onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        Text("No recent meals")
            .foregroundColor(.secondary)
            .italic()
    }

    private func mealRow(for meal: Meal) -> some View {
        Button {
            self.onSelectMeal(meal)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.items.joined(separator: ", "))
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack {
                    Text(meal.mealType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(Self.relativeDateString(from: meal.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    /// Returns a relative date string like "Yesterday" or "2 days ago"
    static func relativeDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let mealDay = calendar.startOfDay(for: date)

        let daysDiff = calendar.dateComponents([.day], from: mealDay, to: today).day ?? 0

        switch daysDiff {
        case 0: return "Today"
        case 1: return "Yesterday"
        default: return "\(daysDiff) days ago"
        }
    }
}

// MARK: - Preview

#Preview("With Meals") {
    RecentMealsSheetView(
        recentMeals: [
            Meal(mealType: .breakfast, items: ["Oatmeal", "Banana"], healthScore: 0.85),
            Meal(mealType: .lunch, items: ["Salad", "Chicken"], healthScore: 0.9)
        ],
        onSelectMeal: { _ in },
        onDismiss: {}
    )
}

#Preview("Empty") {
    RecentMealsSheetView(
        recentMeals: [],
        onSelectMeal: { _ in },
        onDismiss: {}
    )
}
