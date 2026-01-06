import SwiftUI

/// A popup view showing details for a specific day's eating history.
struct DayMealPopupView: View {
    let snapshot: DailySmileySnapshot
    @Binding var selectedDetent: PresentationDetent

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
                // Adaptive height based on detent: 200pt at medium, unlimited at large
                .frame(maxHeight: self.selectedDetent == .medium ? 200 : nil)
            }

            // Reflection section (if available)
            if let reflection = self.snapshot.reflection {
                Divider()
                    .padding(.top, 8)

                self.reflectionSection(reflection)
            }
        }
        .padding()
        .frame(maxWidth: .infinity) // Responsive width instead of fixed 300pt
        .frame(minHeight: 100)
        #if canImport(UIKit)
            .background(Color(uiColor: .systemBackground))
        #elseif canImport(AppKit)
            .background(Color(nsColor: .controlBackgroundColor))
        #endif
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

    @ViewBuilder
    private func reflectionSection(_ reflection: DailyReflection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Reflection")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                if let feeling = reflection.feeling {
                    Text(feeling.emoji)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Felt \(feeling.displayName.lowercased())")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if let sleep = reflection.sleepQuality {
                            HStack(spacing: 4) {
                                Text(sleep.emoji)
                                    .font(.caption)
                                Text("Sleep: \(sleep.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else if let sleep = reflection.sleepQuality {
                    Text(sleep.emoji)
                        .font(.title2)

                    Text("Sleep: \(sleep.displayName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if let note = reflection.note, !note.isEmpty {
                Text("\"\(note)\"")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var detent: PresentationDetent = .medium

        var body: some View {
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
                ),
                selectedDetent: $detent
            )
        }
    }

    return PreviewWrapper()
}
