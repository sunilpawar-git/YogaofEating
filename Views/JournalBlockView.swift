import SwiftUI

// MARK: - JournalBlockView

//
// Submission contract: green checkmark tap is the ONLY path that saves a meal.
// Focus loss and Return key are no-ops — text lives in rawText (@State) until confirmed.

struct JournalBlockView: View {
    let meal: Meal
    let isBreathing: Bool

    /// Called only on green checkmark tap — triggers save + AI analysis.
    let onUpdate: (MealType, [String]) -> Void

    let onTimestampUpdate: (Date) -> Void
    let onDelete: () -> Void

    /// Recent meals from past 3 days for quick-add feature
    var recentMeals: [Meal] = []

    /// Maximum characters enforced by limitedTextBinding (security boundary).
    static let maxCharacterLimit: Int = InputValidator.mealDescriptionMaxLength

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
    @State private var hasInitialized: Bool = false
    @State private var showScoreBreakdown: Bool = false

    init(
        meal: Meal,
        isBreathing: Bool,
        onUpdate: @escaping (MealType, [String]) -> Void,
        onTimestampUpdate: @escaping (Date) -> Void = { _ in },
        onDelete: @escaping () -> Void,
        recentMeals: [Meal] = []
    ) {
        self.meal = meal
        self.isBreathing = isBreathing
        self.onUpdate = onUpdate
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
                    .animation(.easeInOut(duration: 0.5), value: self.meal.healthScore)
            }
            .scaleEffect(self.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isPressed)
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

    private var cardHeader: some View {
        HStack {
            self.mealTypeMenu
            Spacer()
            MealScoreBadge(
                score: self.meal.isAIAnalyzed ? self.meal.healthScore : nil,
                mealType: self.selectedMealType
            ) {
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
                    guard !items.isEmpty else { return }
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
        guard !self.hasInitialized else { return }
        self.rawText = self.meal.items.joined(separator: "\n")
        self.selectedMealType = self.meal.mealType
        self.hasInitialized = true
    }

    func handleCheckmarkTap() {
        self.isFocused = false
        self.handleSubmit()
        SensoryService.shared.playNudge(style: .light)
    }

    func handleSubmit() {
        let items = self.parseItems(from: self.rawText)
        guard !items.isEmpty else { return }
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

    private var feedback: MealCardFeedback {
        MealCardFeedback(score: self.meal.healthScore, mealTypeColor: self.selectedMealType.displayColor)
    }
}
