import SwiftUI

/// A popup view showing details for a specific day's eating history.
struct DayMealPopupView: View {
    let snapshot: DailySmileySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(self.formattedDate)
                        .font(.headline)
                    Text("\(self.snapshot.mealCount) meals logged")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                SmileyView(state: self.snapshot.displayState)
                    .frame(width: 40, height: 40)
            }
            .padding(.bottom, 8)

            Divider()

            // Meals List
            if self.snapshot.meals.isEmpty {
                Text("No meals logged for this day.")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(self.snapshot.meals) { meal in
                            HStack(alignment: .top) {
                                Text(meal.mealType.rawValue.capitalized)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(4)
                                    .background(Color.primary.opacity(0.1))
                                    .cornerRadius(4)

                                VStack(alignment: .leading) {
                                    Text(meal.items.joined(separator: ", "))
                                        .font(.body)
                                    Text("Health Score: \(Int(meal.healthScore * 100))%")
                                        .font(.caption)
                                        .foregroundColor(self.scoreColor(meal.healthScore))
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .frame(width: 300)
        .frame(minHeight: 100)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: self.snapshot.date)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        if score >= 0.5 { return .blue }
        return .orange
    }
}

#Preview {
    DayMealPopupView(
        snapshot: DailySmileySnapshot(
            id: UUID(),
            date: Date(),
            smileyState: SmileyState(scale: 1.0, mood: .serene),
            meals: [
                Meal(id: UUID(), timestamp: Date(), mealType: .breakfast, items: ["Oatmeal"], healthScore: 0.9),
                Meal(id: UUID(), timestamp: Date(), mealType: .lunch, items: ["Pizza"], healthScore: 0.4)
            ],
            mealCount: 2,
            averageHealthScore: 0.65
        )
    )
}
