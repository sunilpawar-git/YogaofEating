import SwiftUI

/// Compact card displayed at the top of DayTimelineView when a briefing is available.
/// Follows the data-contract pattern — receives only pre-computed display values.
struct MorningBriefingCard: View {
    let headline: String
    let topCorrelation: String?
    let nudge: String
    let isViewed: Bool
    /// Time-of-day greeting from the ViewModel (e.g. "Good morning").
    var greeting: String = Strings.Briefing.cardTitle
    /// Up to 2 weakest wellbeing dimensions — shown as a 1-line subtext below the headline.
    var weakDimensions: [WellbeingDimension] = []
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { self.onTap?() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sun.and.horizon.fill")
                        .foregroundStyle(AppTheme.Briefing.sunAccent)
                        .font(.caption)

                    // Monospaced design is intentional — not a FontTheme violation.
                    Text(self.greeting)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .kerning(1)

                    Spacer()

                    if !self.isViewed {
                        Circle()
                            .fill(AppTheme.Briefing.sunAccent)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(self.headline)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !self.weakDimensions.isEmpty {
                    Text(
                        Strings.WellbeingBreakdown.worthNurturing + " "
                            + self.weakDimensions.map(\.displayName).joined(separator: ", ")
                    )
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
                }

                if let correlation = self.topCorrelation {
                    Text(correlation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.Briefing.nudgeAccent)
                    Text(self.nudge)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("morning-briefing-card")
        .accessibilityLabel("\(Strings.Briefing.cardTitle): \(self.headline)")
        .accessibilityHint(self.isViewed ? "Tap to review your briefing" : "Tap to read your new briefing")
    }
}

#Preview("Unread") {
    MorningBriefingCard(
        headline: "Protein lunch powered your afternoon focus",
        topCorrelation: "Healthy meals correlate with better evening mood",
        nudge: "Try repeating Tuesday's lunch today",
        isViewed: false,
        greeting: "Good morning"
    )
    .padding()
}

#Preview("Viewed") {
    MorningBriefingCard(
        headline: "A steady week — small shifts are adding up",
        topCorrelation: nil,
        nudge: "Log your meals to unlock deeper patterns",
        isViewed: true,
        greeting: "Good afternoon"
    )
    .padding()
}
