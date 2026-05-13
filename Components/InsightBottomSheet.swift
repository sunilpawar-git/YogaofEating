import SwiftUI

/// A bottom sheet that displays the daily insight with references.
/// Appears when user taps the peekaboo star button.
struct InsightBottomSheet: View {
    // MARK: - Properties

    /// The insight to display
    let insight: LegacyDailyInsight

    /// Callback when user dismisses the sheet
    let onDismiss: () -> Void

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Private

    private var accentGradient: LinearGradient {
        switch self.insight.insightType {
        case .foodSleep:
            LinearGradient(
                colors: [.indigo.opacity(0.15), .purple.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mindsetFeeling:
            LinearGradient(
                colors: [.teal.opacity(0.15), .cyan.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pattern:
            LinearGradient(
                colors: [.orange.opacity(0.15), .yellow.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .encouragement:
            LinearGradient(
                colors: [.green.opacity(0.15), .mint.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    self.headerSection

                    // Main insight text
                    self.insightTextSection

                    // References (if any)
                    if !self.insight.references.isEmpty {
                        self.referencesSection
                    }

                    // Confidence indicator
                    if self.insight.confidence > ScoringThresholds.high {
                        self.confidenceSection
                    }

                    // Got it button
                    self.gotItButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(self.colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(self.accentGradient)
                )
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: self.insight.insightType.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)

                Text(Strings.Insight.dailyTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Spacer()

            // Insight type badge
            Text(self.insight.insightType.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                )
        }
    }

    // MARK: - Insight Text Section

    private var insightTextSection: some View {
        Text(self.insight.insightText)
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .foregroundColor(.primary)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - References Section

    private var referencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Based on:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ForEach(self.insight.references) { reference in
                HStack(spacing: 8) {
                    Text(reference.category.emoji)
                        .font(.system(size: 14))

                    Text(reference.formattedReference)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
    }

    // MARK: - Confidence Section

    private var confidenceSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle")
                .font(.system(size: 12))
            Text(Strings.Insight.basedOnPatterns)
                .font(.caption)
        }
        .foregroundColor(.secondary.opacity(0.8))
    }

    // MARK: - Got It Button

    private var gotItButton: some View {
        Button(action: {
            SensoryService.shared.playNudge(style: .light)
            self.onDismiss()
        }) {
            Text(Strings.Insight.gotIt)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentColor)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("Food & Sleep") {
        InsightBottomSheet(
            insight: LegacyDailyInsight(
                date: Date(),
                insightText: "On 12 Jan, late evening coffee may have disturbed your sleep. On 14 Jan, three todo completions and good overall diet led to good 'End of Day' feeling and good sleep. Consider finishing dinner earlier for better sleep.",
                insightType: .foodSleep,
                confidence: 0.85,
                references: [
                    InsightReference(
                        date: Date(),
                        description: "Late evening coffee",
                        category: .food
                    ),
                    InsightReference(
                        date: Date().addingTimeInterval(-86400 * 2),
                        description: "3 todos completed",
                        category: .todo
                    )
                ]
            ),
            onDismiss: { print("Dismissed") }
        )
        .padding()
    }

    #Preview("Encouragement") {
        InsightBottomSheet(
            insight: LegacyDailyInsight(
                date: Date(),
                insightText: "Great job! Your healthy eating choices over the past week are likely contributing to better energy and sleep. Keep it up!",
                insightType: .encouragement,
                confidence: 0.9
            ),
            onDismiss: { print("Dismissed") }
        )
        .padding()
    }
#endif
