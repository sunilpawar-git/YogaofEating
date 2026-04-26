import SwiftUI
import WidgetKit

// MARK: - Widget String Constants

// These mirror Strings.Widget in the main app target.
// NOTE: Keep in sync with Strings+Extensions.swift Strings.Widget.
private enum WidgetStrings {
    static let configurationTitle = "Yoga of Eating"
    static let configurationDescription =
        "Today's body intelligence at a glance."
    static let minStreakForDisplay = 2

    static func bisLabel(_ score: Int) -> String { "BIS \(score)" }
    static func streakLabel(_ count: Int) -> String { "\(count)d" }
}

// MARK: - Timeline

struct YogaWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct YogaWidgetTimelineProvider: TimelineProvider {
    func placeholder(in _: Context) -> YogaWidgetEntry {
        YogaWidgetEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(
        in _: Context,
        completion: @escaping (YogaWidgetEntry) -> Void
    ) {
        let data = WidgetDataProvider.load()
        completion(YogaWidgetEntry(date: Date(), snapshot: data))
    }

    func getTimeline(
        in _: Context,
        completion: @escaping (Timeline<YogaWidgetEntry>) -> Void
    ) {
        let data = WidgetDataProvider.load()
        let entry = YogaWidgetEntry(date: Date(), snapshot: data)

        let nextRefresh = Calendar.current.date(
            byAdding: .hour, value: 1, to: Date()
        ) ?? Date()

        completion(Timeline(
            entries: [entry], policy: .after(nextRefresh)
        ))
    }
}

// MARK: - Entry View

struct YogaOfEatingWidgetEntryView: View {
    var entry: YogaWidgetEntry

    var body: some View {
        VStack(spacing: 6) {
            self.progressRing
            self.bisLabel
            self.streakLabel
        }
        .padding(12)
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                .frame(width: 60, height: 60)

            Circle()
                .trim(from: 0, to: self.entry.snapshot.overallProgress)
                .stroke(
                    Color.green,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 60, height: 60)

            Text("\(Int(self.entry.snapshot.overallProgress * 100))")
                .font(.system(
                    size: 16, weight: .semibold, design: .rounded
                ))
                .foregroundColor(.primary)
        }
    }

    private var bisLabel: some View {
        Text(WidgetStrings.bisLabel(Int(self.entry.snapshot.bisScore)))
            .font(.caption2)
            .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var streakLabel: some View {
        if self.entry.snapshot.streak >= WidgetStrings.minStreakForDisplay {
            Text(WidgetStrings.streakLabel(self.entry.snapshot.streak))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
    }
}

// MARK: - Widget

struct YogaOfEatingWidget: Widget {
    let kind: String = "YogaOfEatingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: self.kind,
            provider: YogaWidgetTimelineProvider()
        ) { entry in
            YogaOfEatingWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(WidgetStrings.configurationTitle)
        .description(WidgetStrings.configurationDescription)
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    YogaOfEatingWidget()
} timeline: {
    YogaWidgetEntry(
        date: Date(),
        snapshot: WidgetSnapshot(
            overallProgress: 0.75,
            bisScore: 82,
            streak: 5,
            date: Date()
        )
    )
}
