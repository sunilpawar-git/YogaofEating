// swiftlint:disable file_length
import SwiftUI

extension DayTimelineView {
    /// Resolves the appropriate header: full day-ring + streak, streak-only, or empty.
    @ViewBuilder var headerView: some View {
        if let snap = self.snapshot {
            self.dayRingHeader(for: snap)
        } else if self.isToday,
                  self.streak.current >= Strings.Streak.minimumDisplay
        {
            HStack {
                Spacer()
                StreakPillView(streak: self.streak)
            }
            .padding(.horizontal, 4)
        }
    }

    func dayRingHeader(for snapshot: DailySmileySnapshot) -> some View {
        let progress = DayModuleProgress.compute(from: snapshot)
        return HStack(spacing: 12) {
            DayRingView(progress: progress, ringSize: 44, lineWidth: 4)
            DayRingLegend()
            Spacer()
            if self.streak.current >= Strings.Streak.minimumDisplay {
                StreakPillView(streak: self.streak)
            }
        }
        .padding(.horizontal, 4)
    }

    var timelineLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.primary.opacity(0.1), .primary.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2)
            .padding(.top, 20)
    }

    func sleepBadge(_ quality: SleepQuality) -> some View {
        ReflectionBadgeView(
            type: .sleep(quality),
            isTappable: true,
            onTap: { self.reflectionData.onEditSleep?() },
            sleepData: self.appleSleepData
        )
    }

    func feelingBadge(_ feeling: ReflectionFeeling) -> some View {
        ReflectionBadgeView(
            type: .feeling(feeling),
            isTappable: true,
            onTap: { self.reflectionData.onEditFeeling?() }
        )
    }

    var endOfDayPill: some View {
        Button(action: {
            self.reflectionData.onEndOfDayTap?()
            SensoryService.shared.playNudge(style: .light)
        }, label: {
            HStack(spacing: 6) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.purple.opacity(0.8))
                Text(Strings.Timeline.endOfDay)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.purple.opacity(0.1)))
            .overlay(Capsule().stroke(Color.purple.opacity(0.3), lineWidth: 1))
        })
        .buttonStyle(.plain)
        .accessibilityIdentifier("end-of-day-pill")
        .accessibilityLabel(Strings.Timeline.endOfDay)
        .accessibilityHint("Tap to log how you felt today")
    }

    var smileyAddButton: some View {
        VStack(spacing: 16) {
            SmileyView(state: self.smileyState)
                .frame(width: 120, height: 120)
                .overlay(alignment: .topTrailing) {
                    if self.hasUnreadInsight {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
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
                        withAnimation(.easeOut(duration: 0.2)) { self.showInsightCoachmark = false }
                    }
                    self.onSmileyTap?()
                    SensoryService.shared.playNudge(style: .medium)
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    if self.showInsightCoachmark {
                        withAnimation(.easeOut(duration: 0.2)) { self.showInsightCoachmark = false }
                    }
                    self.onSmileyLongPress?()
                }

            Text(self.hasInsightAvailable ? Strings.Timeline.tapToLogHoldForInsight : Strings.Timeline.tapToLog)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .kerning(self.hasInsightAvailable ? 1 : 2)
                .fixedSize()

            Text(QuoteService.getDailyQuote().text)
                .font(.system(size: 11, design: .serif))
                .italic()
                .foregroundColor(.secondary.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Daily mindful eating quote")
        }
        .accessibilityIdentifier("add-meal-button")
        .accessibilityLabel(self.hasInsightAvailable ? "Add Meal or Hold for Insight" : "Add Meal")
        .accessibilityHint(self.hasInsightAvailable ? "Tap to log meal, hold to view insight" : "Tap to log a new meal")
    }

    var historicalDaySummary: some View {
        VStack(spacing: 16) {
            if let snapshot = self.snapshot {
                SmileyView(state: snapshot.displayState).frame(width: 80, height: 80)
            } else {
                SmileyView(state: .neutral).frame(width: 80, height: 80)
            }

            if self.meals.isEmpty {
                Text(Strings.Timeline.noMealsLogged).font(.subheadline).foregroundColor(.secondary)
            } else {
                VStack(spacing: 4) {
                    Text("\(self.meals.count) meal\(self.meals.count == 1 ? "" : "s") logged")
                        .font(.subheadline).foregroundColor(.secondary)
                    if let avgScore = self.snapshot?.averageHealthScore {
                        Text("Avg. Health Score: \(Int(avgScore * 100))%")
                            .font(.caption)
                            .foregroundColor(self.scoreColor(avgScore))
                    }
                }
            }

            if let reflection = self.snapshot?.reflection {
                self.reflectionSummary(reflection)
            }
            if let snapshot = self.snapshot, snapshot.hasMorningMindCheck || snapshot.hasEveningMindCheck {
                self.historicalMindCheckSection(snapshot: snapshot)
            }
        }
        .padding(.vertical, 20)
    }

    @ViewBuilder
    func historicalMindCheckSection(snapshot: DailySmileySnapshot) -> some View {
        VStack(spacing: 12) {
            Divider().padding(.horizontal, 40)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { self.isMindCheckExpanded.toggle() }
            } label: {
                HStack {
                    Text(Strings.MindCheck.Historical.mindCheckSectionTitle)
                        .font(.subheadline).fontWeight(.medium).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: self.isMindCheckExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
            }
            .buttonStyle(.plain)

            if self.isMindCheckExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    if let morningEntries = snapshot.morningMindCheck, !morningEntries.isEmpty {
                        self.historicalEntriesGroup(
                            header: Strings.MindCheck.Historical.morningHeader,
                            entries: morningEntries,
                            showCompletionStatus: true
                        )
                    }
                    if let eveningEntries = snapshot.eveningMindCheck, !eveningEntries.isEmpty {
                        self.historicalEntriesGroup(
                            header: Strings.MindCheck.Historical.eveningHeader,
                            entries: eveningEntries,
                            showCompletionStatus: false
                        )
                    }
                }
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    func historicalEntriesGroup(
        header: String,
        entries: [MindCheckEntry],
        showCompletionStatus: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            ForEach(entries) { entry in
                HStack(spacing: 8) {
                    Text(entry.category.emoji).font(.system(size: 14))
                    Text(entry.text).font(.callout).foregroundColor(.primary).lineLimit(2)
                    Spacer()
                    if showCompletionStatus, entry.category == .todo {
                        if entry.isAccomplished == true {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                Text(Strings.MindCheck.Historical.completed).font(.caption2).foregroundColor(.green)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "circle").foregroundColor(.secondary.opacity(0.5))
                                Text(Strings.MindCheck.Historical.notCompleted).font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.03)))
            }
        }
    }

    func reflectionSummary(_ reflection: DailyReflection) -> some View {
        VStack(spacing: 8) {
            Divider().padding(.horizontal, 40)
            HStack(spacing: 12) {
                if let feeling = reflection.feeling {
                    Text(feeling.emoji).font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Felt \(feeling.displayName.lowercased())")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let sleep = reflection.sleepQuality {
                            Text("Sleep: \(sleep.displayName)").font(.caption).foregroundColor(.secondary)
                        }
                    }
                } else if let sleep = reflection.sleepQuality {
                    Text(sleep.emoji).font(.title2)
                    Text("Sleep: \(sleep.displayName)").font(.subheadline).fontWeight(.medium)
                }
            }
            if let note = reflection.note, !note.isEmpty {
                Text("\"\(note)\"")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        if score >= 0.5 { return .blue }
        return .orange
    }

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
        .background(Capsule().fill(Color.black.opacity(0.75)))
    }

    func updateInsightCoachmark() {
        guard self.isToday, self.hasUnreadInsight, !self.insightCoachmarkSeen else { return }
        self.insightCoachmarkSeen = true
        withAnimation(.easeOut(duration: 0.2)) { self.showInsightCoachmark = true }
        self.coachmarkDismissTask?.cancel()
        self.coachmarkDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { self.showInsightCoachmark = false }
        }
    }
}
