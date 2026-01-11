import SwiftUI

/// A single cell in the heatmap representing one day.
/// Colored based on the health score and smiley state of that day.
struct DayCell: View {
    let date: Date
    let snapshot: DailySmileySnapshot?

    /// The size of the cell. Defaults to 32pt for thumb-friendly tapping.
    var cellSize: CGFloat = 32

    /// The corner radius of the cell. Defaults to 4pt.
    var cornerRadius: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: self.cornerRadius)
            .fill(self.backgroundColor)
            .frame(width: self.cellSize, height: self.cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: self.cornerRadius)
                    .stroke(
                        self.borderColor,
                        lineWidth: self.borderWidth
                    )
            )
            .contentShape(Rectangle()) // Ensure entire area is tappable
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(self.isToday ? "heatmap-cell-today" : "heatmap-cell")
            .accessibilityLabel(self.accessibilityLabelText)
            .accessibilityAddTraits(.isButton)
            .help(self.accessibilityLabelText)
    }

    // MARK: - Visual Styling

    private var borderColor: Color {
        if self.isToday {
            Color.primary
        } else if self.hasData {
            Color.primary.opacity(0.2)
        } else {
            Color.primary.opacity(0.08)
        }
    }

    private var borderWidth: CGFloat {
        self.isToday ? 2.0 : 0.5
    }

    private var hasData: Bool {
        guard let snapshot else { return false }
        return !snapshot.isEmpty
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(self.date)
    }

    private var backgroundColor: Color {
        guard let snapshot else {
            return Color.primary.opacity(0.03) // Empty day - more subtle
        }

        if snapshot.isEmpty {
            return Color.primary.opacity(0.03)
        }

        // Intensity based on health score (0.0 to 1.0)
        // Clamp score to valid range to prevent invalid opacity values
        let rawScore = snapshot.averageHealthScore
        let score = rawScore.isFinite ? min(1.0, max(0.0, rawScore)) : 0.5

        // Mood-based coloring with improved contrast
        // Base opacity 0.25, max opacity 0.85 for better visibility
        let baseOpacity = 0.25
        let opacityRange = 0.6

        switch snapshot.smileyState.mood {
        case .serene:
            return Color.green.opacity(baseOpacity + (score * opacityRange))
        case .neutral:
            return Color.blue.opacity(baseOpacity + (score * opacityRange))
        case .overwhelmed:
            return Color.orange.opacity(baseOpacity + (score * opacityRange))
        }
    }

    private var accessibilityLabelText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: self.date)

        if let snapshot, !snapshot.isEmpty {
            return "\(dateString): \(snapshot.mealCount) meals, score \(Int(snapshot.averageHealthScore * 100))%"
        } else {
            return "\(dateString): No data"
        }
    }
}

#Preview("Cell Sizes") {
    HStack(spacing: 12) {
        // Empty cell
        DayCell(date: Date(), snapshot: nil)

        // Cell with serene mood
        DayCell(
            date: Date(),
            snapshot: DailySmileySnapshot(
                id: UUID(),
                date: Date(),
                smileyState: SmileyState(scale: 1.0, mood: .serene),
                meals: [Meal(id: UUID(), timestamp: Date(), mealType: .lunch, items: ["Salad"], healthScore: 0.9)],
                mealCount: 1,
                averageHealthScore: 0.9
            )
        )

        // Cell with neutral mood
        DayCell(
            date: Date(),
            snapshot: DailySmileySnapshot(
                id: UUID(),
                date: Date(),
                smileyState: SmileyState(scale: 0.5, mood: .neutral),
                meals: [Meal(id: UUID(), timestamp: Date(), mealType: .dinner, items: ["Pizza"], healthScore: 0.5)],
                mealCount: 1,
                averageHealthScore: 0.5
            )
        )

        // Cell with overwhelmed mood
        DayCell(
            date: Date(),
            snapshot: DailySmileySnapshot(
                id: UUID(),
                date: Date(),
                smileyState: SmileyState(scale: 0.2, mood: .overwhelmed),
                meals: [Meal(id: UUID(), timestamp: Date(), mealType: .snacks, items: ["Chips"], healthScore: 0.3)],
                mealCount: 1,
                averageHealthScore: 0.3
            )
        )
    }
    .padding()
}

#Preview("Large Cells") {
    HStack(spacing: 12) {
        DayCell(date: Date(), snapshot: nil, cellSize: 44, cornerRadius: 6)
        DayCell(
            date: Date(),
            snapshot: DailySmileySnapshot(
                id: UUID(),
                date: Date(),
                smileyState: SmileyState(scale: 1.0, mood: .serene),
                meals: [],
                mealCount: 3,
                averageHealthScore: 0.85
            ),
            cellSize: 44,
            cornerRadius: 6
        )
    }
    .padding()
}
