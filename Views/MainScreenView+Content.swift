import SwiftUI
#if canImport(AppKit)
    import AppKit
#endif

extension MainScreenView {
    // MARK: - Today Timeline (Editable)

    var todayTimelineContent: some View {
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
                        if let existingEntries = self.viewModel.todaysMorningMindCheck, !existingEntries.isEmpty {
                            self.viewModel.editMorningMindCheck(existingEntries)
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

    // MARK: - Historical Day Content (Read-Only)

    @ViewBuilder
    func historicalDayContent(daysAgo: Int) -> some View {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date())) ?? calendar
            .startOfDay(for: Date())
        let snapshot = self.viewModel.snapshot(for: date)
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
                    self.viewModel.copyMealToToday(meal)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.viewModel.navigateToToday()
                    }
                }
            )
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        #if canImport(UIKit)
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if self.premiumManager.isPremium {
                        self.showTrendsSheet = true
                    } else {
                        self.showPaywallSheet = true
                    }
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.75))
                }
                .accessibilityIdentifier("trends-button")
            }
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

    var settingsButton: some View {
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
        var keyboardDoneButton: some View {
            Button("Done") {
                self.dismissKeyboard()
            }
            .fontWeight(.semibold)
            .accessibilityIdentifier("keyboard-done-button")
        }

        func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    #endif

    // MARK: - Background

    var backgroundGradient: some View {
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

    var averageBIS: Double {
        let points = self.viewModel.trendPoints(days: 14)
        guard !points.isEmpty else { return 0 }
        return points.map(\.bis).reduce(0, +) / Double(points.count)
    }
}
