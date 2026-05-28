import SwiftUI

/// Full-screen detail sheet for the morning briefing.
/// Receives the DailyBriefing via parameter (data-contract pattern).
struct BriefingDetailView: View {
    let insight: DailyInsight
    var liveBreakdown: WellbeingBreakdownSheetContract?
    var isLikelyStale: Bool = false
    var onDismiss: (() -> Void)?
    var onRefresh: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if self.isLikelyStale {
                        self.staleBanner
                    }
                    self.headlineSection
                    if self.liveBreakdown != nil {
                        Divider().padding(.vertical, 24)
                        self.moodHeroSection
                        self.wellbeingBreakdownSection
                    }
                    Divider().padding(.vertical, 24)
                    self.correlationCardsSection
                    Divider().padding(.vertical, 24)
                    self.nudgeSection
                    if self.insight.weeklyTrend != nil {
                        Divider().padding(.vertical, 16)
                        self.weeklyTrendSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        self.onRefresh?()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel(Strings.Briefing.refreshButton)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Briefing.doneButton) { self.onDismiss?() }
                }
            }
        }
    }

    // MARK: - Headline

    @ViewBuilder
    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sun.and.horizon.fill")
                    .foregroundStyle(AppTheme.Briefing.sunAccent)
                Text(self.formattedDate)
                    .font(FontTheme.caption)
                    .foregroundStyle(.secondary)
            }

            Text(String(format: Strings.Briefing.shortHeadlineFmt, self.shortDayName))
                .font(FontTheme.briefingHeadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Stale Banner

    private var staleBanner: some View {
        Button(action: { self.onRefresh?() }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.clockwise")
                    .font(FontTheme.caption.weight(.medium))
                Text(Strings.Insight.staleInsightBanner)
                    .font(FontTheme.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .padding(.bottom, AppTheme.Spacing.small)
    }

    // MARK: - Helpers

    private static let dayNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    private static let headlineDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d"
        return f
    }()

    private var shortDayName: String {
        Self.dayNameFormatter.string(from: self.insight.date).lowercased()
    }

    static func insightsTitle(for date: Date) -> String {
        String(format: Strings.Briefing.insightsTitleFormat, self.dayNameFormatter.string(from: date))
    }

    private var formattedDate: String {
        Self.headlineDateFormatter.string(from: self.insight.date)
    }

    func trendIcon(_ direction: TrendDirection) -> String {
        switch direction {
        case .improving: "arrow.up.right"
        case .declining: "arrow.down.right"
        case .steady: "arrow.right"
        }
    }
}

private let _previewInsight = DailyInsight(
    date: Date(),
    headline: "Protein lunches power your best afternoons",
    dimensions: .neutral,
    dominantInsight: "Your eating patterns are improving your energy.",
    correlationCards: [
        CorrelationCard(
            category: .foodToMood,
            observation: "Days with healthier meals end with better mood",
            confidence: 0.85, dataPoints: []
        ),
        CorrelationCard(
            category: .timingPattern,
            observation: "Regular meal timing improves your sleep quality",
            confidence: 0.72, dataPoints: []
        )
    ],
    nudge: ActionableNudge(
        suggestion: "Try repeating Tuesday's grilled chicken salad",
        reasoning: "It correlated with your best afternoon this week"
    ),
    weeklyTrend: WeeklyTrendSnippet(
        averageFoodScore: 0.72,
        averageSleepQuality: 0.68,
        daysLogged: 6,
        trendDirection: .improving
    ),
    causalExplanation: "Physical load is the driver.",
    textSignals: [],
    confidence: 0.8
)

#Preview("No dimension bars") {
    BriefingDetailView(insight: _previewInsight)
}

#Preview("With dimension bars") {
    BriefingDetailView(
        insight: _previewInsight,
        liveBreakdown: WellbeingBreakdownSheetContract(
            dimensions: WellbeingDimensions(
                physicalLoad: 0.85,
                emotionalTone: 0.5,
                cognitiveClarity: 0.31,
                behavioralMomentum: 0.1
            ),
            dominantDimension: .physicalLoad,
            causalNarrative: "Physical load is driving your wellbeing today.",
            weakDimensions: [.behavioralMomentum],
            mealCount: 3,
            currentMood: .neutral,
            overallScore: 0.62
        )
    )
}
