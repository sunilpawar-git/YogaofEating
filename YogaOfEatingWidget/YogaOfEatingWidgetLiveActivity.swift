import ActivityKit
import SwiftUI
import WidgetKit

struct YogaOfEatingWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct YogaOfEatingWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: YogaOfEatingWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

private extension YogaOfEatingWidgetAttributes {
    static var preview: YogaOfEatingWidgetAttributes {
        YogaOfEatingWidgetAttributes(name: "World")
    }
}

private extension YogaOfEatingWidgetAttributes.ContentState {
    static var smiley: YogaOfEatingWidgetAttributes.ContentState {
        YogaOfEatingWidgetAttributes.ContentState(emoji: "😀")
    }

    static var starEyes: YogaOfEatingWidgetAttributes.ContentState {
        YogaOfEatingWidgetAttributes.ContentState(emoji: "🤩")
    }
}

#Preview("Notification", as: .content, using: YogaOfEatingWidgetAttributes.preview) {
    YogaOfEatingWidgetLiveActivity()
} contentStates: {
    YogaOfEatingWidgetAttributes.ContentState.smiley
    YogaOfEatingWidgetAttributes.ContentState.starEyes
}
