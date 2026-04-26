import SwiftUI

// MARK: - Done Button Visibility Configuration

/// Controls when the Done button appears in JournalBlockView.
/// This allows easy adjustment based on UX feedback without code changes.
enum DoneButtonVisibility {
    /// Always show when text field is focused (default, most discoverable)
    case whenFocused

    /// Show only when there's content in the text field
    case whenHasContent

    /// Never show (rely on focus loss and return key only)
    case never
}

struct JournalBlockView: View {
    let meal: Meal
    let isBreathing: Bool

    /// Called on "done" actions (focus loss, Return key, Done button) - triggers AI analysis
    let onUpdate: (MealType, [String]) -> Void

    /// Called during typing for local-only updates - NO AI analysis
    /// Use this for real-time feedback while user types
    let onLocalUpdate: (MealType, [String]) -> Void

    let onTimestampUpdate: (Date) -> Void
    let onDelete: () -> Void

    /// Recent meals from past 3 days for quick-add feature
    var recentMeals: [Meal] = []

    /// Today's daily intention for showing alignment hints
    var dailyIntention: String?

    /// Called when user rates pre-hunger or post-satisfaction
    var onMicroReflection: ((UUID, Int?, Int?) -> Void)?

    /// Controls when the Done button is visible. Configurable for UX refinement.
    static var doneButtonVisibility: DoneButtonVisibility = .whenFocused

    let maxCharacterLimit: Int = 1000

    /// Debounce delay in nanoseconds for local updates during typing.
    /// 500ms (500_000_000 ns) balances responsiveness with reducing excessive updates.
    /// Note: This is for LOCAL updates only - AI analysis is triggered on "done" actions.
    static let localUpdateDebounceNanoseconds: UInt64 = 500_000_000

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    @State var rawText: String = ""
    @State var selectedMealType: MealType = .lunch
    @State private var isPressed: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State var showTimePicker: Bool = false
    @State var showRecentMealsSheet: Bool = false
    @State var editedTimestamp: Date = .init()
    @FocusState var isFocused: Bool
    @State var debounceTask: Task<Void, Never>?
    @State var hasInitialized: Bool = false
    /// Track the last items we sent to prevent external sync from overwriting during typing
    @State var lastSentItems: [String] = []
    /// Controls visibility of score breakdown sheet
    @State private var showScoreBreakdown: Bool = false
    /// Prevents duplicate AI triggers when Done button dismisses focus
    @State var skipNextFocusLoss: Bool = false

    init(
        meal: Meal,
        isBreathing: Bool,
        onUpdate: @escaping (MealType, [String]) -> Void,
        onLocalUpdate: @escaping (MealType, [String]) -> Void = { _, _ in },
        onTimestampUpdate: @escaping (Date) -> Void = { _ in },
        onDelete: @escaping () -> Void,
        recentMeals: [Meal] = [],
        dailyIntention: String? = nil,
        onMicroReflection: ((UUID, Int?, Int?) -> Void)? = nil
    ) {
        self.meal = meal
        self.isBreathing = isBreathing
        self.onUpdate = onUpdate
        self.onLocalUpdate = onLocalUpdate
        self.onTimestampUpdate = onTimestampUpdate
        self.onDelete = onDelete
        self.recentMeals = recentMeals
        self.dailyIntention = dailyIntention
        self.onMicroReflection = onMicroReflection
    }

    var body: some View {
        self.cardContent
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: 200, idealWidth: 300, maxWidth: 340, minHeight: 70, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("meal-block-\(self.meal.id)")
            .background { MealCardBackground(feedback: self.feedback) }
            .scaleEffect(self.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isPressed)
            .animation(.easeInOut(duration: 0.5), value: self.meal.healthScore)
            .onLongPressGesture(minimumDuration: 1.0) {
                SensoryService.shared.playNudge(style: .heavy)
                self.showDeleteAlert = true
            } onPressingChanged: { pressing in
                self.isPressed = pressing
            }
            .alert("Delete this meal?", isPresented: self.$showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { self.onDelete() }
            } message: {
                Text("This action cannot be undone.")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .transition(.opacity)
            .onAppear { self.initializeState() }
            .onDisappear { self.debounceTask?.cancel() }
            .sheet(isPresented: self.$showScoreBreakdown) {
                ScoreBreakdownSheet(meal: self.meal) {
                    self.showScoreBreakdown = false
                }
            }
    }

    // MARK: - Subviews

    @ViewBuilder private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if self.isBreathing {
                BreathingContentView()
            } else {
                self.cardHeader
                self.textInputSection
                self.microReflectionRow
                self.alignmentHintView
            }
        }
    }

    /// Shows an alignment hint if a daily intention is set and the meal matches/conflicts.
    @ViewBuilder private var alignmentHintView: some View {
        if let intention = dailyIntention,
           !meal.items.isEmpty,
           let hint = IntentAlignmentService.alignmentHint(
               intention: intention, mealItems: meal.items
           )
        {
            HStack(spacing: 6) {
                Image(systemName: hint.contains("nudge") ? "exclamationmark.circle" : "checkmark.circle")
                    .font(.caption2)
                    .foregroundColor(hint.contains("nudge") ? .orange : .green)

                Text(hint)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.top, 4)
            .transition(.opacity)
        }
    }

    /// Header row with meal type tag (left) and score badge (right)
    private var cardHeader: some View {
        HStack {
            self.mealTypeMenu
            Spacer()
            MealScoreBadge(score: self.meal.healthScore) {
                self.showScoreBreakdown = true
            }
        }
    }

    private var mealTypeMenu: some View {
        Menu {
            ForEach(MealType.allCases, id: \.self) { type in
                Button {
                    self.selectedMealType = type
                    let items = self.parsedItems
                    self.lastSentItems = items
                    self.onUpdate(type, items)
                    SensoryService.shared.playNudge(style: .light)
                } label: {
                    Label(type.displayName, systemImage: type.iconName)
                }
            }
        } label: {
            MealTypeTag(mealType: self.selectedMealType, isSelected: true)
        }
        .animation(nil, value: self.selectedMealType)
    }

    /// Visual feedback helper based on meal's health score
    private var feedback: MealCardFeedback {
        MealCardFeedback(score: self.meal.healthScore, mealTypeColor: self.selectedMealType.displayColor)
    }
}
