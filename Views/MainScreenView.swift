import SwiftUI
#if canImport(AppKit)
    import AppKit
#endif

@MainActor
struct MainScreenView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                self.backgroundGradient
                    .ignoresSafeArea()

                self.mainContent
                // Note: Peekaboo star removed - insights now accessed via smiley long-press
            }
            .toolbar { self.toolbarContent }
            .mainScreenSheets(viewModel: self.viewModel, showingSettings: self.$showingSettings)
            // Note: Auto-prompt removed - now using user-initiated reflections via smiley tap
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            self.dayPage(for: self.viewModel.selectedDayIndex)
                .animation(
                    .easeInOut(duration: AppTheme.Animation.standardDuration),
                    value: self.viewModel.selectedDayIndex
                )
        }
        .contentShape(Rectangle())
    }

    // MARK: - Day Page Content

    @ViewBuilder
    private func dayPage(for dayIndex: Int) -> some View {
        ScrollView(showsIndicators: false) {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    if dayIndex == 0 {
                        // Today: editable timeline
                        self.todayTimelineContent
                            .onChange(of: self.viewModel.meals.count) { _, _ in
                                withAnimation(.easeInOut(duration: AppTheme.Animation.standardDuration)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                    } else {
                        // Historical day: read-only view
                        self.historicalDayContent(daysAgo: dayIndex)
                    }

                    // Bottom spacer anchors scroll-to-bottom proxy
                    Color.clear.frame(width: 1, height: AppTheme.Layout.bottomScrollBuffer)
                        .id("bottom")
                }
            }
        }
    }

    // MARK: - Today Timeline (Editable)

    private var todayTimelineContent: some View {
        DayTimelineView(
            meals: self.viewModel.meals,
            fastingPeriods: self.viewModel.fastingPeriods,
            isToday: true,
            smileyState: self.viewModel.smileyState,
            snapshot: nil,
            onSmileyTap: {
                self.viewModel.createNewMeal()
            },
            onSmileyLongPress: {
                self.viewModel.handleSmileyLongPress()
            },
            hasInsightAvailable: self.viewModel.hasInsightAvailable,
            briefingCardData: self.viewModel.briefingCardData,
            briefingWeakDimensions: self.viewModel.briefingWeakDimensions,
            onBriefingTap: {
                self.viewModel.markBriefingViewed()
                self.viewModel.showBriefingSheet = true
            },
            mealActions: MealUpdateActions(
                onUpdate: { mealId, mealType, items in
                    self.viewModel.updateMeal(mealId, mealType: mealType, items: items)
                },
                onUpdateTimestamp: { mealId, timestamp in
                    self.viewModel.updateMealTimestamp(mealId, timestamp: timestamp)
                },
                onDelete: { mealId in
                    withAnimation(.spring()) {
                        self.viewModel.deleteMeal(mealId)
                    }
                }
            ),
            recentMeals: self.viewModel.getRecentUniqueMeals(),
            averageHealthScore: self.viewModel.averageHealthScoreToday,
            caloriePillData: self.viewModel.caloriePillData,
            calorieDetailData: self.viewModel.calorieDetailData
        )
    }

    // MARK: - Historical Day Content (Read-Only)

    @ViewBuilder
    private func historicalDayContent(daysAgo: Int) -> some View {
        let calendar = Calendar.current
        // Safe date computation — `date(byAdding:)` can return nil for unusual calendar configs.
        // Fall back to today's start of day rather than crashing.
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))
            ?? calendar.startOfDay(for: Date())
        let snapshot = self.viewModel.historicalService.getSnapshot(for: date)
        let meals = snapshot?.meals ?? []
        let fastingPeriods = FastingLogicService.calculateFastingPeriods(
            from: meals.sorted { $0.timestamp < $1.timestamp }
        )

        DayTimelineView(
            meals: meals,
            fastingPeriods: fastingPeriods,
            isToday: false,
            smileyState: snapshot?.smileyState ?? .neutral,
            snapshot: snapshot,
            mealActions: MealUpdateActions(
                onUpdate: { _, _, _ in },
                onUpdateTimestamp: { _, _ in },
                onDelete: { _ in },
                onCopy: { meal in
                    self.viewModel.copyMealToToday(meal)
                    withAnimation(.easeInOut(duration: AppTheme.Animation.standardDuration)) {
                        self.viewModel.navigateToToday()
                    }
                }
            ),
            caloriePillData: self.viewModel.historicalCaloriePillData(for: self.viewModel.selectedDate)
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if canImport(UIKit)
            ToolbarItem(placement: .navigationBarTrailing) {
                self.settingsButton
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
                .font(FontTheme.sectionHeader)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .accessibilityIdentifier("settings-button")
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            #if canImport(AppKit)
                Color(NSColor.controlBackgroundColor)
            #else
                Color(uiColor: .systemBackground)
            #endif

            Circle()
                .fill(Color.orange.opacity(AppTheme.Background.glowOpacity))
                .frame(
                    width: AppTheme.Background.glowSize,
                    height: AppTheme.Background.glowSize
                )
                .blur(radius: AppTheme.Background.glowBlurRadius)
                .offset(
                    x: AppTheme.Background.glowOffsetX,
                    y: AppTheme.Background.glowOffsetY
                )
        }
    }
}

#Preview {
    MainScreenView()
        .environmentObject(MainViewModel())
}
