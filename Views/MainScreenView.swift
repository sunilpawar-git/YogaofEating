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

                self.mainContent
                // Note: Peekaboo star removed - insights now accessed via smiley long-press
            }
            .toolbar { self.toolbarContent }
            .sheet(isPresented: self.$showingSettings) {
                SettingsView(mainViewModel: self.viewModel)
            }
            // Note: Legacy showReflectionSheet removed - now using user-initiated SleepQuality/OverallFeeling sheets
            .sheet(isPresented: self.$viewModel.showSleepQualitySheet) {
                SleepQualityInputView(
                    onSelect: { quality in
                        self.viewModel.completeSleepQualityInput(quality)
                    },
                    onDismiss: {
                        self.viewModel.dismissSleepQualityInput()
                    }
                )
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: self.$viewModel.showOverallFeelingSheet) {
                OverallFeelingInputView(
                    onSelect: { feeling in
                        self.viewModel.completeOverallFeelingInput(feeling)
                    },
                    onDismiss: {
                        self.viewModel.dismissOverallFeelingInput()
                    }
                )
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: self.$viewModel.showMorningMindCheckSheet) {
                MindCheckInputView(
                    existingEntries: self.viewModel.editingMorningEntries,
                    onSave: { entries in
                        self.viewModel.completeMorningMindCheckInput(entries)
                    },
                    onDismiss: {
                        self.viewModel.dismissMorningMindCheckInput()
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: self.$viewModel.showEveningMindCheckSheet) {
                EveningReviewView(
                    morningEntries: self.viewModel.todaysMorningMindCheck ?? [],
                    existingEveningEntries: self.viewModel.todaysEveningMindCheck,
                    showFeelingSelection: self.viewModel.isEndOfDayFlow,
                    onSave: { updatedMorning, evening, feeling in
                        self.viewModel.completeEveningReview(
                            updatedMorningEntries: updatedMorning,
                            eveningEntries: evening,
                            feeling: feeling
                        )
                    },
                    onDismiss: {
                        self.viewModel.dismissEveningMindCheckInput()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: self.$viewModel.showInsightSheet) {
                if let insight = self.viewModel.currentInsight {
                    InsightBottomSheet(
                        insight: insight,
                        onDismiss: {
                            self.viewModel.dismissInsight()
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            // Note: Auto-prompt removed - now using user-initiated reflections via smiley tap
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Date header with navigation
            self.dateHeaderWithNavigation
                .padding(.top, 60)
                .padding(.bottom, 20)

            // Day page content with gesture-based navigation
            // Note: Using plain view with drag gesture instead of TabView to control
            // navigation direction - only allow swiping to previous days, not forward
            self.dayPage(for: self.viewModel.selectedDayIndex)
                .gesture(
                    DragGesture(minimumDistance: 50, coordinateSpace: .local)
                        .onEnded { value in
                            let horizontalDrag = value.translation.width
                            let isSwipeLeft = horizontalDrag < -50
                            let isSwipeRight = horizontalDrag > 50

                            withAnimation(.easeInOut(duration: 0.3)) {
                                if isSwipeLeft, self.viewModel.canNavigateToPreviousDay {
                                    // Swipe left = go to previous day (higher index)
                                    self.viewModel.navigateToPreviousDay()
                                } else if isSwipeRight, self.viewModel.canNavigateToNextDay {
                                    // Swipe right = go towards today (lower index)
                                    self.viewModel.navigateToNextDay()
                                }
                            }
                        }
                )
                .animation(.easeInOut(duration: 0.3), value: self.viewModel.selectedDayIndex)
        }
        .contentShape(Rectangle())
        #if canImport(UIKit)
            .onTapGesture { self.dismissKeyboard() }
        #endif
    }

    // MARK: - Date Header with Navigation

    private var dateHeaderWithNavigation: some View {
        DateHeaderNavigationView(
            formattedDate: self.viewModel.formattedSelectedDate,
            isViewingToday: self.viewModel.isViewingToday,
            canNavigateToPreviousDay: self.viewModel.canNavigateToPreviousDay,
            onPreviousDay: { self.viewModel.navigateToPreviousDay() },
            onNavigateToToday: { self.viewModel.navigateToToday() }
        )
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
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                    } else {
                        // Historical day: read-only view
                        self.historicalDayContent(daysAgo: dayIndex)
                    }

                    // Bottom spacer
                    Color.clear.frame(width: 1, height: 100)
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
                // Use context-aware smiley tap handling (morning sleep only)
                self.viewModel.handleSmileyTap()
            },
            onSmileyLongPress: {
                // Show insight if available
                self.viewModel.handleSmileyLongPress()
            },
            hasInsightAvailable: self.viewModel.hasInsightAvailable,
            onEditSleep: {
                // Show sleep quality sheet for editing
                self.viewModel.showSleepQualitySheet = true
            },
            onEditFeeling: {
                // Show overall feeling sheet for editing
                self.viewModel.showOverallFeelingSheet = true
            },
            onEndOfDayTap: {
                // Handle End-of-Day pill tap
                self.viewModel.handleEndOfDayPillTap()
            },
            todaysSleepQuality: self.viewModel.todaysSleepQuality,
            todaysFeeling: self.viewModel.todaysFeeling,
            showEndOfDayPill: self.viewModel.showEndOfDayPill,
            showMorningMindCheckPill: self.viewModel.showMorningMindCheckPill,
            todaysMorningMindCheck: self.viewModel.todaysMorningMindCheck,
            onMorningMindCheckTap: {
                // Check if we're editing existing entries or creating new
                if let existingEntries = self.viewModel.todaysMorningMindCheck, !existingEntries.isEmpty {
                    self.viewModel.editMorningMindCheck(existingEntries)
                } else {
                    self.viewModel.showMorningMindCheckSheet = true
                }
            },
            mealActions: MealUpdateActions(
                onUpdate: { mealId, mealType, items in
                    // Full update - triggers AI analysis (called on "done" actions)
                    self.viewModel.updateMeal(mealId, mealType: mealType, items: items)
                },
                onLocalUpdate: { mealId, _, items in
                    // Local-only update - NO AI analysis (called during typing)
                    self.viewModel.updateMealItemsLocalOnly(mealId, items: items)
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
            recentMeals: self.viewModel.getRecentUniqueMeals()
        )
    }

    // MARK: - Historical Day Content (Read-Only)

    @ViewBuilder
    private func historicalDayContent(daysAgo: Int) -> some View {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))!
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
                onLocalUpdate: { _, _, _ in },
                onUpdateTimestamp: { _, _ in },
                onDelete: { _ in },
                onCopy: { meal in
                    // Copy meal to today and navigate to today
                    self.viewModel.copyMealToToday(meal)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.viewModel.navigateToToday()
                    }
                }
            )
        )
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
}

#Preview {
    MainScreenView()
        .environmentObject(MainViewModel())
}
