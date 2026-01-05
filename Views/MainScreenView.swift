import SwiftUI
#if canImport(AppKit)
    import AppKit
#endif

@MainActor
struct MainScreenView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var breathingMeals: Set<UUID> = []
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                self.backgroundGradient
                    .ignoresSafeArea()

                self.mainScrollContent
            }
            .toolbar { self.toolbarContent }
            .sheet(isPresented: self.$showingSettings) {
                SettingsView(mainViewModel: self.viewModel)
            }
        }
    }

    // MARK: - Main Content

    private var mainScrollContent: some View {
        ScrollView(showsIndicators: false) {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    self.dateHeader
                    self.timelineContent
                    // Use explicit dimensions for the spacer to prevent layout issues
                    Color.clear.frame(width: 1, height: 100)
                }
                .onChange(of: self.viewModel.meals.count) { _, _ in
                    // Use a gentler animation to avoid layout race conditions
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        #if canImport(UIKit)
            .onTapGesture { self.dismissKeyboard() }
        #endif
    }

    private var dateHeader: some View {
        Text(self.formattedDate)
            .font(.system(.title, design: .rounded))
            .fontWeight(.bold)
            .padding(.top, 60)
            .padding(.bottom, 40)
    }

    private var timelineContent: some View {
        VStack(spacing: 0) {
            // Use cached sorted meals and fasting periods from ViewModel
            let sortedMeals = self.viewModel.sortedMeals
            let fastingPeriods = self.viewModel.fastingPeriods

            ForEach(Array(sortedMeals.enumerated()), id: \.element.id) { index, meal in
                self.mealBlockView(for: meal)
                    .id(meal.id)

                // Show fasting connector after each meal (except the last one)
                if index < sortedMeals.count - 1,
                   let period = fastingPeriods.first(where: { $0.startMealId == meal.id })
                {
                    self.fastingConnector(for: period)
                } else if index < sortedMeals.count - 1 {
                    // Fallback spacing if no period found
                    Spacer().frame(height: 30)
                }
            }

            self.smileyAddButton
                .padding(.top, sortedMeals.isEmpty ? 20 : 30)
                .id("bottom")
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .center) { self.timelineLine }
    }

    /// Fasting connector with proportional spacing and optional badge
    private func fastingConnector(for period: FastingPeriod) -> some View {
        let spacing = FastingLogicService.calculateSpacing(for: period)
        let showBadge = FastingLogicService.shouldShowBadge(for: period)

        return ZStack {
            // Vertical connector line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: period.isSignificant
                            ? [.green.opacity(0.2), .green.opacity(0.1)]
                            : [.primary.opacity(0.08), .primary.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: period.isSignificant ? 3 : 2, height: spacing)
                .shadow(
                    color: period.isSignificant ? .green.opacity(0.3 * period.glowIntensity) : .clear,
                    radius: 4,
                    x: 0,
                    y: 0
                )

            // Fasting badge centered on connector
            if showBadge {
                FastingBadgeView(fastingPeriod: period)
            }
        }
        .frame(height: spacing)
    }

    private func mealBlockView(for meal: Meal) -> some View {
        JournalBlockView(
            meal: meal,
            isBreathing: self.breathingMeals.contains(meal.id),
            onUpdate: { mealType, newItems in
                self.viewModel.updateMeal(meal.id, mealType: mealType, items: newItems)
            },
            onTimestampUpdate: { newTimestamp in
                self.viewModel.updateMealTimestamp(meal.id, timestamp: newTimestamp)
            },
            onDelete: {
                withAnimation(.spring()) {
                    self.viewModel.deleteMeal(meal.id)
                }
            }
        )
    }

    private var timelineLine: some View {
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

    // MARK: - Smiley Button

    private var smileyAddButton: some View {
        Button(action: {
            self.viewModel.createNewMeal()
            SensoryService.shared.playNudge(style: .medium)
        }) {
            VStack(spacing: 16) {
                SmileyView(state: self.viewModel.smileyState)
                    .frame(width: 120, height: 120)

                Text("TAP TO LOG")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .kerning(2)
                    .fixedSize()

                self.dailyQuote
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("add-meal-button")
        .accessibilityLabel("Add Meal")
    }

    /// Daily mindful eating quote displayed below smiley
    private var dailyQuote: some View {
        Text(QuoteService.getDailyQuote().text)
            .font(.system(size: 11, design: .serif))
            .italic()
            .foregroundColor(.secondary.opacity(0.6))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 280)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Daily mindful eating quote")
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if canImport(UIKit)
            ToolbarItem(placement: .navigationBarTrailing) {
                self.settingsButton
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                self.keyboardDoneButton
            }
        #elseif canImport(AppKit)
            ToolbarItem(placement: .automatic) {
                self.settingsButton
            }
        #endif
    }

    private var settingsButton: some View {
        Button {
            self.showingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .accessibilityIdentifier("settings-button")
    }

    #if canImport(UIKit)
        private var keyboardDoneButton: some View {
            Button("Done") {
                self.dismissKeyboard()
            }
            .fontWeight(.semibold)
            .accessibilityIdentifier("keyboard-done-button")
        }

        private func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    #endif

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            #if canImport(AppKit)
                Color(NSColor.controlBackgroundColor)
            #else
                Color(uiColor: .systemBackground)
            #endif

            LinearGradient(
                colors: [
                    Color.orange.opacity(0.05),
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -200)
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter.string(from: Date())
    }
}

#Preview {
    MainScreenView()
        .environmentObject(MainViewModel())
}
