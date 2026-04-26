import SwiftUI

/// A simplified, non-editable meal card for historical views.
struct ReadOnlyMealCardView: View {
    let meal: Meal
    var onCopyMeal: ((Meal) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                MealTypeTag(mealType: self.meal.mealType, isSelected: true)
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
                }

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
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.4)))
        .background(RoundedRectangle(cornerRadius: 16).fill(self.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(self.borderColor, lineWidth: 2))
        .padding(.horizontal, 24)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    private var formattedTime: String { Self.timeFormatter.string(from: self.meal.timestamp) }
    private var scoreColor: Color {
        self.meal.healthScore >= 0.8 ? .green : (self.meal.healthScore >= 0.5 ? .blue : .orange)
    }

    private var cardBackground: Color {
        self.meal.healthScore >= 0.7 ? Color.green
            .opacity(0.08) : (self.meal.healthScore >= 0.4 ? Color.blue.opacity(0.05) : Color.orange.opacity(0.08))
    }

    private var borderColor: Color {
        self.meal.healthScore >= 0.7 ? Color.green
            .opacity(0.3) : (self.meal.healthScore >= 0.4 ? Color.blue.opacity(0.2) : Color.orange.opacity(0.3))
    }
}

#if DEBUG
    #Preview("Today Timeline") {
        ScrollView {
            DayTimelineView(
                meals: [
                    Meal(mealType: .breakfast, items: ["Oatmeal", "Berries"], healthScore: 0.9),
                    Meal(mealType: .lunch, items: ["Salad", "Chicken"], healthScore: 0.8)
                ],
                fastingPeriods: [],
                isToday: true,
                smileyState: .neutral,
                snapshot: nil,
                onSmileyTap: { print("Smiley tapped") },
                reflectionData: TodayReflectionData(sleepQuality: .good, feeling: .calm)
            )
        }
    }
#endif
