import SwiftUI

// MARK: - Submission Methods

/// Green checkmark icon is shown when focused + has content.
/// Submission occurs via:
/// 1. Checkmark tap
/// 2. Return key (from keyboard)
/// 3. Focus loss (implicit)

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

    /// Maximum characters enforced by the limitedTextBinding.
    /// Sourced from AppTheme.TextEntry — single source of truth across the app.
    static let maxCharacterLimit: Int = AppTheme.TextEntry.maxCharacters

    /// Debounce delay for local updates during typing.
    /// Sourced from AppTheme.TextEntry — single source of truth across the app.
    static let localUpdateDebounceNanoseconds: UInt64 = AppTheme.TextEntry.debounceNanoseconds

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
    @State private var debounceTask: Task<Void, Never>?
    @State private var hasInitialized: Bool = false
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
        recentMeals: [Meal] = []
    ) {
        self.meal = meal
        self.isBreathing = isBreathing
        self.onUpdate = onUpdate
        self.onLocalUpdate = onLocalUpdate
        self.onTimestampUpdate = onTimestampUpdate
        self.onDelete = onDelete
        self.recentMeals = recentMeals
    }

    var body: some View {
        self.cardContent
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: 200, idealWidth: 300, maxWidth: 340, minHeight: 70, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("meal-block-\(self.meal.id)")
            .background {
                MealCardBackground(feedback: self.feedback, mealTypeColor: self.selectedMealType.displayColor)
            }
            .scaleEffect(self.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isPressed)
            .animation(.easeInOut(duration: 0.5), value: self.meal.healthScore)
            .onLongPressGesture(minimumDuration: 1.0) {
                SensoryService.shared.playNudge(style: .heavy)
                self.showDeleteAlert = true
            } onPressingChanged: { pressing in
                self.isPressed = pressing
            }
            .alert(Strings.Journal.deleteAlertTitle, isPresented: self.$showDeleteAlert) {
                Button(Strings.Common.cancel, role: .cancel) {}
                Button(Strings.Common.delete, role: .destructive) { self.onDelete() }
            } message: {
                Text(Strings.Journal.deleteAlertMessage)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .transition(.opacity)
            .onAppear { self.initializeState() }
            .sheet(isPresented: self.$showScoreBreakdown) {
                ScoreBreakdownSheet(meal: self.meal) {
                    self.showScoreBreakdown = false
                }
            }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if self.isBreathing {
                BreathingContentView()
            } else {
                self.cardHeader
                self.textInputSection
            }
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
            MealTypeTag(mealType: self.selectedMealType)
        }
        .animation(nil, value: self.selectedMealType)
    }

    // MARK: - Actions

    private func initializeState() {
        if !self.hasInitialized {
            self.rawText = self.meal.items.joined(separator: "\n")
            self.selectedMealType = self.meal.mealType
            self.lastSentItems = self.meal.items
            self.hasInitialized = true
        }
    }

    func handleTextChange(_ newValue: String) {
        self.debounceTask?.cancel()
        self.debounceTask = Task { @MainActor in
            // Short debounce for local updates - just enough to batch rapid keystrokes
            try? await Task.sleep(nanoseconds: Self.localUpdateDebounceNanoseconds)
            guard !Task.isCancelled else { return }
            let items = self.parseItems(from: newValue)
            self.lastSentItems = items
            // Use onLocalUpdate for typing - NO AI analysis triggered
            self.onLocalUpdate(self.selectedMealType, items)
        }
    }

    func handleFocusChange(_ focused: Bool) {
        if !focused {
            self.debounceTask?.cancel()

            // Skip if Done button already triggered the update
            if self.skipNextFocusLoss {
                self.skipNextFocusLoss = false
                return
            }

            let items = self.parseItems(from: self.rawText)
            self.lastSentItems = items
            // Use onUpdate for "done" action - triggers AI analysis
            self.onUpdate(self.selectedMealType, items)
        }
    }

    func handleSubmit() {
        self.debounceTask?.cancel()
        let items = self.parseItems(from: self.rawText)
        self.lastSentItems = items
        // Use onUpdate for "done" action - triggers AI analysis
        self.onUpdate(self.selectedMealType, items)
    }

    // MARK: - Helpers

    func parseItems(from text: String) -> [String] {
        text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var parsedItems: [String] {
        self.parseItems(from: self.rawText)
    }

    /// Visual feedback helper based on meal's health score
    private var feedback: MealCardFeedback {
        MealCardFeedback(score: self.meal.healthScore, mealTypeColor: self.selectedMealType.displayColor)
    }
}
