import SwiftUI
#if canImport(AppKit)
    import AppKit
#endif

@MainActor
struct MainScreenView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var premiumManager: PremiumManager
    @State var showingSettings = false
    @State var showWeeklySummarySheet = false
    @State var showTrendsSheet = false
    @State var showPaywallSheet = false
    @AppStorage(StorageKeys.useRadialHome) private var useRadialHome = false

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
            .sheet(isPresented: self.$viewModel.showSleepQualitySheet) {
                SleepQualityInputView(
                    onSelect: { quality in
                        self.viewModel.completeSleepQualityInput(quality)
                    },
                    onDismiss: {
                        self.viewModel.dismissSleepQualityInput()
                    },
                    suggestedQuality: self.viewModel.suggestedSleepQuality,
                    sleepData: self.viewModel.appleSleepData
                )
                .presentationDetents([.height(320)])
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
                    existingFeeling: self.viewModel.todaysFeeling,
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
            .sheet(isPresented: self.$viewModel.showReflectSheet) {
                ReflectInputView(
                    onSave: { energy, intention in
                        self.viewModel.completeReflectInput(energy: energy, intention: intention)
                    },
                    onDismiss: {
                        self.viewModel.dismissReflectInput()
                    }
                )
                .presentationDetents([.height(440)])
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
            .sheet(isPresented: self.$showWeeklySummarySheet) {
                if let weeklyInsight = self.viewModel.currentWeeklyInsight {
                    WeeklySummaryView(
                        insight: weeklyInsight,
                        archetype: self.premiumManager.isPremium
                            ? self.viewModel.currentArchetype
                            : nil,
                        isPremium: self.premiumManager.isPremium,
                        bisAverage: self.averageBIS,
                        onExport: {
                            self.viewModel.exportWeeklyPDF(
                                insight: weeklyInsight,
                                archetype: self.premiumManager.isPremium ? self.viewModel.currentArchetype : nil,
                                bisAverage: self.averageBIS
                            )
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: self.$showTrendsSheet) {
                TrendChartView(points: self.viewModel.trendPoints(days: 14))
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: self.$showPaywallSheet) {
                PaywallView()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            self.dateHeaderWithNavigation
                .padding(.top, 60)
                .padding(.bottom, 20)

            self.dayPage(for: self.viewModel.selectedDayIndex)
                .gesture(
                    DragGesture(minimumDistance: 50, coordinateSpace: .local)
                        .onEnded { value in
                            let horizontalDrag = value.translation.width
                            let isSwipeLeft = horizontalDrag < -50
                            let isSwipeRight = horizontalDrag > 50

                            withAnimation(.easeInOut(duration: 0.3)) {
                                if isSwipeLeft, self.viewModel.canNavigateToPreviousDay {
                                    self.viewModel.navigateToPreviousDay()
                                } else if isSwipeRight, self.viewModel.canNavigateToNextDay {
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
                        self.todayTimelineContent
                            .onChange(of: self.viewModel.meals.count) { _, _ in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                    } else {
                        self.historicalDayContent(daysAgo: dayIndex)
                    }

                    Color.clear.frame(width: 1, height: 100)
                        .id("bottom")
                }
            }
        }
    }
}

#Preview {
    MainScreenView()
        .environmentObject(MainViewModel())
}
