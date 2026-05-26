import SwiftUI

// MARK: - DayTimelineView: Smiley Section

/// Smiley add button, historical day summary, insight coachmark, and related helpers.
/// Extracted to keep DayTimelineView.swift under the 300-line file limit.
extension DayTimelineView {
    // MARK: - Smiley Add Button (Today Only)

    var smileyAddButton: some View {
        VStack(spacing: 16) {
            SmileyView(state: self.smileyState)
                .frame(width: AppTheme.Layout.smileyButtonSize, height: AppTheme.Layout.smileyButtonSize)
                .scaleEffect(self.isSmileyPulsing ? AppTheme.Animation.breathingScale : 1.0)
                .animation(
                    self.isSmileyPulsing ? AppTheme.Animation.breathingPulse : .default,
                    value: self.isSmileyPulsing
                )
                .overlay(alignment: .topTrailing) {
                    if self.hasInsightAvailable {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                            .offset(x: 4, y: -4)
                    }
                }
                .overlay(alignment: .top) {
                    if self.showInsightCoachmark {
                        self.insightCoachmark
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .offset(y: -44)
                    }
                }
                .onTapGesture {
                    if self.showInsightCoachmark {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.showInsightCoachmark = false
                        }
                    }
                    self.onSmileyTap?()
                    SensoryService.shared.playNudge(style: .medium)
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    if self.showInsightCoachmark {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.showInsightCoachmark = false
                        }
                    }
                    self.onSmileyLongPress?()
                }
                .onAppear {
                    self.updateSmileyPulse()
                }
                .onChange(of: self.meals.count) { _, _ in
                    self.updateSmileyPulse()
                }

            Text(self.hasInsightAvailable ? Strings.Timeline.tapToLogWithInsight : Strings.Timeline.tapToLog)
                .font(FontTheme.caption)
                .foregroundColor(.secondary)
                .fixedSize()

            if let pillData = self.caloriePillData, pillData.isVisible {
                CaloriePillView(data: pillData, detailData: self.calorieDetailData)
            }

            if let summary = self.daySummaryText {
                Text(summary)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("day-summary-line")
            }

            if TimelineAnimationState.shouldShowEmptyStateGreeting(
                mealCount: self.meals.count, isToday: self.isToday
            ) {
                Text(Strings.Timeline.emptyStateGreeting)
                    .font(.system(size: 12, design: .default))
                    .italic()
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("empty-state-greeting")
            }

            if TimelineAnimationState.shouldShowQuote(
                mealCount: self.meals.count, isToday: self.isToday
            ) {
                Text(QuoteService.getDailyQuote().text)
                    .font(.system(size: 11, design: .rounded))
                    .italic()
                    .foregroundColor(.secondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(Strings.Timeline.quoteAccessibility)
            }
        }
        .accessibilityIdentifier("add-meal-button")
        .accessibilityLabel(self.hasInsightAvailable ? Strings.Accessibility.addMealWithInsight : Strings.Accessibility
            .addMealButton)
        .accessibilityHint(self.hasInsightAvailable ? Strings.Accessibility.addMealWithInsightHint : Strings
            .Accessibility.addMealHint)
    }

    /// Updates the smiley pulse state based on current meal count and day context.
    /// Called on appear and whenever meal count changes.
    func updateSmileyPulse() {
        let shouldPulse = TimelineAnimationState.shouldPulse(
            mealCount: self.meals.count, isToday: self.isToday
        )
        if self.isSmileyPulsing != shouldPulse {
            self.isSmileyPulsing = shouldPulse
        }
    }

    /// One-line ambient summary shown above the smiley when the ViewModel provides an average score.
    /// Uses the pre-computed `averageHealthScore` parameter to keep averaging logic in one place (SSOT).
    var daySummaryText: String? {
        guard self.isToday, let avg = self.averageHealthScore, self.meals.count >= 2 else { return nil }
        return Strings.Timeline.daySummary(avgScore: Int(avg * 100), mealCount: self.meals.count)
    }

    // MARK: - Historical Day Summary

    var historicalDaySummary: some View {
        VStack(spacing: 16) {
            // Smiley showing that day's state
            if let snapshot = self.snapshot {
                SmileyView(state: snapshot.displayState)
                    .frame(width: 80, height: 80)
            } else {
                SmileyView(state: .neutral)
                    .frame(width: 80, height: 80)
            }

            // Summary text
            if self.meals.isEmpty {
                Text("No meals logged")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 4) {
                    Text("\(self.meals.count) meal\(self.meals.count == 1 ? "" : "s") logged")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let avgScore = self.snapshot?.averageHealthScore {
                        Text("Avg. Health Score: \(Int(avgScore * 100))%")
                            .font(.caption)
                            .foregroundColor(self.scoreColor(avgScore))
                    }
                }
            }

            if let pillData = self.caloriePillData, pillData.isVisible {
                CaloriePillView(data: pillData, isTappable: false)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 20)
    }

    func scoreColor(_ score: Double) -> Color {
        if score >= ScoringThresholds.healthy { return .green }
        if score >= ScoringThresholds.neutral { return .blue }
        return .orange
    }

    // MARK: - Insight Coachmark

    var insightCoachmark: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.tap")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            Text("Hold to view insight")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.75))
        )
        .accessibilityLabel("Hold the smiley to view insight")
    }

    func updateInsightCoachmark() {
        guard self.isToday, self.hasInsightAvailable, !self.insightCoachmarkSeen else { return }
        self.insightCoachmarkSeen = true
        withAnimation(.easeOut(duration: 0.2)) {
            self.showInsightCoachmark = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.showInsightCoachmark = false
            }
        }
    }
}
