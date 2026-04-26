import SwiftUI

extension MainScreenView {
    /// Legacy today timeline content using DayTimelineView.
    /// Extracted to keep MainScreenView+Content.swift concise.
    var legacyTodayTimelineContent: some View {
        VStack(spacing: 12) {
            if let weeklyInsight = self.viewModel.currentWeeklyInsight {
                WeeklySummaryCardView(insight: weeklyInsight) {
                    self.showWeeklySummarySheet = true
                }
                .padding(.horizontal, 20)
            }

            DayTimelineView(
                meals: self.viewModel.meals,
                fastingPeriods: self.viewModel.fastingPeriods,
                isToday: true,
                smileyState: self.viewModel.smileyState,
                snapshot: self.viewModel.todaysSnapshot,
                onSmileyTap: {
                    self.viewModel.handleSmileyTap()
                },
                onSmileyLongPress: {
                    self.viewModel.handleSmileyLongPress()
                },
                hasInsightAvailable: self.viewModel.hasInsightAvailable,
                hasUnreadInsight: self.viewModel.hasUnreadInsight,
                reflectionData: TodayReflectionData(
                    sleepQuality: self.viewModel.todaysSleepQuality,
                    appleSleepData: self.viewModel.appleSleepData,
                    feeling: self.viewModel.todaysFeeling,
                    showEndOfDayPill: self.viewModel.showEndOfDayPill,
                    showMorningMindCheckPill: self.viewModel.showMorningMindCheckPill,
                    morningMindCheck: self.viewModel.todaysMorningMindCheck,
                    onEditSleep: {
                        self.viewModel.showSleepQualitySheet = true
                    },
                    onEditFeeling: {
                        self.viewModel.showOverallFeelingSheet = true
                    },
                    onEndOfDayTap: {
                        self.viewModel.handleEndOfDayPillTap()
                    },
                    onMorningMindCheckTap: {
                        if let entries = self.viewModel.todaysMorningMindCheck,
                           !entries.isEmpty
                        {
                            self.viewModel.editMorningMindCheck(entries)
                        } else {
                            self.viewModel.showMorningMindCheckSheet = true
                        }
                    }
                ),
                mealActions: MealUpdateActions(
                    onUpdate: { mealId, mealType, items in
                        self.viewModel.updateMeal(mealId, mealType: mealType, items: items)
                    },
                    onLocalUpdate: { mealId, _, items in
                        self.viewModel.updateMealItemsLocalOnly(mealId, items: items)
                    },
                    onUpdateTimestamp: { mealId, timestamp in
                        self.viewModel.updateMealTimestamp(mealId, timestamp: timestamp)
                    },
                    onDelete: { mealId in
                        withAnimation(.spring()) {
                            self.viewModel.deleteMeal(mealId)
                        }
                    },
                    onMicroReflection: { mealId, pre, post in
                        self.viewModel.saveMicroReflection(
                            mealId: mealId,
                            preHunger: pre,
                            postSatisfaction: post
                        )
                    }
                ),
                recentMeals: self.viewModel.getRecentUniqueMeals(),
                currentInsight: self.viewModel.currentInsight,
                onInsightDismiss: {
                    self.viewModel.dismissInsight()
                },
                dailyIntention: self.viewModel.todaysIntention,
                onFocusRate: { rating in
                    self.viewModel.saveFocusRating(rating)
                },
                hasFocusRating: self.viewModel.todaysFocusRating != nil,
                streak: self.viewModel.currentStreak
            )
        }
    }
}
