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

            // TabView for day paging
            TabView(selection: Binding(
                get: { self.viewModel.selectedDayIndex },
                set: { self.viewModel.navigateToIndex($0) }
            )) {
                // Today (index 0) and past days (1...maxDaysBack)
                ForEach(0...MainViewModel.maxDaysBack, id: \.self) { dayIndex in
                    self.dayPage(for: dayIndex)
                        .tag(dayIndex)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: self.viewModel.selectedDayIndex)
        }
        .contentShape(Rectangle())
        #if canImport(UIKit)
            .onTapGesture { self.dismissKeyboard() }
        #endif
    }

    // MARK: - Date Header with Navigation

    private var dateHeaderWithNavigation: some View {
        HStack(spacing: 16) {
            // Previous day button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.viewModel.navigateToPreviousDay()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(self.viewModel.canNavigateToPreviousDay ? .primary : .secondary.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(!self.viewModel.canNavigateToPreviousDay)
            .accessibilityIdentifier("previous-day-button")
            .accessibilityLabel("Previous day")

            // Date display (tappable to return to today)
            VStack(spacing: 4) {
                Text(self.viewModel.formattedSelectedDate)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .accessibilityIdentifier("date-header")

                if !self.viewModel.isViewingToday {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.viewModel.navigateToToday()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Back to Today")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("today-button")
                    .accessibilityLabel("Back to Today")
                    .accessibilityHint("Return to today's view")
                }
            }
            .frame(maxWidth: .infinity)

            // Next day button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.viewModel.navigateToNextDay()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(self.viewModel.canNavigateToNextDay ? .primary : .secondary.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(!self.viewModel.canNavigateToNextDay)
            .accessibilityIdentifier("next-day-button")
            .accessibilityLabel("Next day")
        }
        .padding(.horizontal, 16)
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
            onUpdateMeal: { mealId, mealType, items in
                self.viewModel.updateMeal(mealId, mealType: mealType, items: items)
            },
            onUpdateTimestamp: { mealId, timestamp in
                self.viewModel.updateMealTimestamp(mealId, timestamp: timestamp)
            },
            onDeleteMeal: { mealId in
                withAnimation(.spring()) {
                    self.viewModel.deleteMeal(mealId)
                }
            }
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
            snapshot: snapshot
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
