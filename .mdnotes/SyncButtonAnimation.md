Overview

 This plan implements two UI/UX improvements following TDD principles with strict phase-wise testing. Each phase builds successfully and all tests pass before moving to the next phase.

 Requirements Summary

 Issue 1: Settings Screen

 1. Fix divider under "Sync with Cloud" button to be full-width
 2. Add button animation: loading indicator during sync → checkmark + "Synced!" on completion → auto-revert after 2 seconds

 Issue 2: Heatmap Meal Detail Sheet

 1. Remove 200pt maxHeight constraint when sheet is at .large detent (eliminate double-scrolling)
 2. Auto-expand sheet to .large for days with 3+ meals
 3. Keep current behavior (start at .medium) for days with <3 meals

 Architecture Decisions

 Settings Sync:

 - State Management: @State enum for sync status (idle/syncing/success/error)
 - Debouncing: Track sync task to prevent rapid taps
 - Animation: SwiftUI withAnimation + 2-second auto-revert
 - Divider: Custom full-width divider or modified listRowInsets

 Heatmap Sheet:

 - Detent Binding: Add @Binding var selectedDetent: PresentationDetent to DayMealPopupView
 - Adaptive Height: Conditional maxHeight - 200pt at .medium, nil at .large
 - Auto-Expansion: Set initial detent in .onAppear based on snapshot.mealCount >= 3
 - Responsive Width: Replace fixed 300pt with .infinity for better iPad support

 ---
 PHASE 1: Settings Sync - Loading State & Success Animation

 Objective

 Add visual feedback during sync: loading indicator → checkmark animation → auto-revert

 Files to Modify

 Views/SettingsView.swift
 - Add state variables:
 @State private var syncStatus: SyncStatus = .idle
 @State private var syncTask: Task<Void, Never>?

 enum SyncStatus {
     case idle
     case syncing
     case success
     case error(String)
 }
 - Update syncButton computed property (lines 89-101):
   - Show ProgressView() when syncing
   - Show checkmark.circle.fill icon when success
   - Change text: "Sync with Cloud" → "Syncing..." → "Synced!" → back to "Sync with Cloud"
   - Change background color: blue → lighter blue → green → back to blue
   - Add .animation(.easeInOut(duration: 0.3), value: syncStatus)
   - Add .disabled(syncStatus == .syncing)
 - Update performSync() method (lines 339-347):
 private func performSync() {
     syncTask?.cancel()
     syncTask = Task {
         syncStatus = .syncing
         do {
             try await viewModel.historicalService.syncToFirebase()
             syncStatus = .success
             try? await Task.sleep(nanoseconds: 2_000_000_000)
             if !Task.isCancelled {
                 syncStatus = .idle
             }
         } catch {
             if !Task.isCancelled {
                 syncStatus = .error(error.localizedDescription)
             }
         }
     }
 }

 New Test Files

 Yoga of EatingTests/SettingsViewSyncTests.swift
 - test_performSync_updatesStatusToSyncing_whenStarted()
 - test_performSync_updatesStatusToSuccess_whenCompleted()
 - test_performSync_updatesStatusToError_whenFailed()
 - test_performSync_ignoresRapidTaps_whenAlreadySyncing()
 - test_syncButton_revertsToIdle_afterTwoSeconds()
 - test_syncButton_showsCheckmark_whenStatusIsSuccess()

 Success Criteria

 - ✅ All 234 existing tests pass
 - ✅ 6 new unit tests pass
 - ✅ Build succeeds with zero warnings
 - ✅ Button shows loading spinner during sync
 - ✅ Button shows green checkmark on success for 2 seconds
 - ✅ Button disabled during sync (no double-tap)
 - ✅ Smooth animation transitions

 Tech Debt Cleanup

 - Remove print("❌ Cloud sync failed: \(error)") from performSync
 - Add accessibility labels: .accessibilityLabel() and .accessibilityHint() for each state
 - Extract constants: private let SYNC_SUCCESS_DISPLAY_DURATION: UInt64 = 2_000_000_000

 ---
 PHASE 2: Settings Sync - Full-Width Divider

 Objective

 Make divider below "Sync with Cloud" button extend full-width

 Files to Modify

 Views/SettingsView.swift
 - Wrap syncButton in VStack with custom divider:
 private var syncButton: some View {
     VStack(spacing: 0) {
         Button(action: { self.performSync() }) {
             // ... existing button content
         }
         .buttonStyle(.borderless)
         .disabled(syncStatus == .syncing)

         // Full-width divider
         Divider()
             .background(Color.secondary.opacity(0.3))
     }
     .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
 }

 Test Updates

 Yoga of EatingUITests/SettingsUITests.swift
 - test_syncButton_hasFulLWidthDivider()
 - test_syncButton_spansFullWidth_inUserDataSection()

 Success Criteria

 - ✅ All tests pass
 - ✅ Divider extends edge-to-edge
 - ✅ Button maintains proper vertical spacing
 - ✅ No visual regression in other sections

 Tech Debt Cleanup

 - Add code comment documenting SwiftUI Form divider override pattern
 - Ensure consistent divider styling across all Form sections

 ---
 PHASE 3: Heatmap Sheet - Adaptive Height Based on Detent

 Objective

 Remove 200pt maxHeight when sheet is at .large detent to eliminate double-scrolling

 Files to Modify

 Components/DayMealPopupView.swift
 - Add detent binding parameter:
 struct DayMealPopupView: View {
     let snapshot: DailySmileySnapshot
     @Binding var selectedDetent: PresentationDetent

     var body: some View {
         VStack(alignment: .leading, spacing: 16) {
             // ... header (unchanged)

             Divider()

             // Adaptive meals list
             if snapshot.meals.isEmpty {
                 // ... empty state
             } else {
                 ScrollView {
                     VStack(alignment: .leading, spacing: 12) {
                         ForEach(snapshot.meals) { meal in
                             // ... meal card
                         }
                     }
                 }
                 .frame(maxHeight: selectedDetent == .medium ? 200 : nil)
             }
         }
         .padding()
         .frame(maxWidth: .infinity)  // Replace fixed 300pt width
         .frame(minHeight: 100)
         .background(Color(uiColor: .systemBackground))
         .cornerRadius(12)
         .shadow(radius: 10)
     }
 }

 Views/YearlyCalendarView.swift
 - Add state variable (before .sheet modifier):
 @State private var sheetDetent: PresentationDetent = .medium
 - Update sheet presentation (lines 60-63):
 .sheet(item: $viewModel.selectedSnapshot) { snapshot in
     DayMealPopupView(snapshot: snapshot, selectedDetent: $sheetDetent)
         .presentationDetents([.medium, .large], selection: $sheetDetent)
 }

 New Test Files

 Yoga of EatingTests/DayMealPopupViewTests.swift
 - test_popup_hasMaxHeight200_whenDetentIsMedium()
 - test_popup_hasUnlimitedHeight_whenDetentIsLarge()
 - test_popup_usesFullWidth_notFixed300pt()

 Update: Yoga of EatingUITests/YearlyCalendarUITests.swift
 - test_expandedSheet_showsAllMeals_withoutDoubleScrolling()
 - test_mediumSheet_limitsHeight_forManyMeals()

 Success Criteria

 - ✅ All tests pass
 - ✅ No double-scrolling at full detent
 - ✅ Sheet height adapts when user drags to expand
 - ✅ Smooth transition between detents
 - ✅ Responsive width on iPad

 Tech Debt Cleanup

 - Document detent-based layout strategy in code comments
 - Remove hardcoded width constraint completely

 ---
 PHASE 4: Heatmap Sheet - Auto-Expand for 3+ Meals

 Objective

 Automatically open sheet at .large detent when day has 3+ meals

 Files to Modify

 Views/YearlyCalendarView.swift
 - Update sheet presentation (lines 60-63):
 .sheet(item: $viewModel.selectedSnapshot) { snapshot in
     DayMealPopupView(snapshot: snapshot, selectedDetent: $sheetDetent)
         .presentationDetents([.medium, .large], selection: $sheetDetent)
         .onAppear {
             // Auto-expand for 3+ meals
             sheetDetent = snapshot.mealCount >= 3 ? .large : .medium
         }
 }
 - Add constant at top of file:
 private let SHEET_AUTO_EXPAND_THRESHOLD = 3

 Test Updates

 Yoga of EatingTests/DayMealPopupViewTests.swift
 - test_sheet_startsAtLargeDetent_when3OrMoreMeals()
 - test_sheet_startsAtMediumDetent_whenLessThan3Meals()
 - test_sheet_startsAtMediumDetent_whenNoMeals()

 Yoga of EatingUITests/YearlyCalendarUITests.swift
 - test_tappingDayWith3Meals_opensSheetFullyExpanded()
 - test_tappingDayWith1Meal_opensSheetPartiallyExpanded()
 - test_userCanManuallyAdjustDetent_afterAutoExpansion()

 Success Criteria

 - ✅ All tests pass
 - ✅ Days with 3+ meals open fully expanded
 - ✅ Days with <3 meals open at medium detent
 - ✅ User can still manually adjust detent
 - ✅ No performance regression

 Tech Debt Cleanup

 - Extract meal count threshold to named constant
 - Add accessibility hint: .accessibilityHint("Swipe down to adjust sheet size")
 - Add code comment explaining auto-expansion logic

 ---
 PHASE 5: Integration Testing & Polish

 Objective

 Comprehensive edge case testing, accessibility improvements, and performance validation

 New Test Files

 Yoga of EatingTests/SettingsSyncIntegrationTests.swift
 // Edge cases
 - test_sync_handlesOfflineGracefully()
 - test_sync_handlesEmptyHistoricalData()
 - test_sync_handles100Snapshots_performantly()
 - test_sync_cancelsGracefully_whenViewDismissed()
 - test_sync_showsError_whenNetworkFails()

 // Accessibility
 - test_syncButton_announcesStateChanges_toVoiceOver()
 - test_syncButton_hasMinimum44ptTapTarget()

 Yoga of EatingTests/HeatmapSheetIntegrationTests.swift
 // Edge cases
 - test_sheet_handles20Meals_smoothly()
 - test_sheet_updatesHeight_whenRotatingDevice()
 - test_sheet_releasesMemory_whenDismissed()

 // Accessibility
 - test_sheet_announcesDetentChange_toVoiceOver()
 - test_mealList_scrollsCorrectly_withVoiceOver()

 Files to Enhance

 Views/SettingsView.swift
 - Add haptic feedback for success state:
 import UIKit

 // In performSync after success:
 UINotificationFeedbackGenerator().notificationOccurred(.success)
 - Add network reachability check (optional enhancement)

 Components/DayMealPopupView.swift
 - Add accessibility identifiers
 - Test with 20+ meals for performance

 Success Criteria

 - ✅ All ~280 tests pass (234 original + ~46 new)
 - ✅ Build with zero warnings
 - ✅ VoiceOver announces all state changes
 - ✅ Haptic feedback on sync success
 - ✅ Performance: Sync 100 snapshots in <10 seconds
 - ✅ Performance: Open sheet with 20 meals in <500ms
 - ✅ Memory: No leaks detected in Instruments
 - ✅ Tested on iPhone SE, iPhone 16, iPad

 Tech Debt Cleanup

 - Document all edge case handling
 - Add analytics events for sync success/failure tracking
 - Create user-facing error messages (replace print statements)
 - Add performance monitoring hooks

 ---
 Testing Summary

 Total New Tests: ~46

 - Unit Tests: ~31 tests
   - Phase 1: 6 tests (sync states)
   - Phase 2: 2 tests (divider)
   - Phase 3: 3 tests (adaptive height)
   - Phase 4: 3 tests (auto-expand)
   - Phase 5: 17+ tests (integration & edge cases)
 - UI Tests: ~15 tests
   - Phase 1: 2 tests (button animation)
   - Phase 2: 2 tests (divider width)
   - Phase 3: 2 tests (sheet expansion)
   - Phase 4: 3 tests (auto-expand behavior)
   - Phase 5: 6+ tests (accessibility & edge cases)

 Final Test Count

 - Original: 234 tests
 - After implementation: ~280 tests
 - Zero regressions tolerated

 ---
 Critical Files Reference

 | File Path                                       | Purpose                           | Phases  |
 |-------------------------------------------------|-----------------------------------|---------|
 | Views/SettingsView.swift                        | Sync button state & animation     | 1, 2, 5 |
 | Components/DayMealPopupView.swift               | Sheet content & adaptive height   | 3, 5    |
 | Views/YearlyCalendarView.swift                  | Sheet presentation & detent logic | 3, 4    |
 | Logic/HistoricalDataService.swift               | Sync service (reference only)     | -       |
 | Yoga of EatingTests/SettingsViewSyncTests.swift | New sync tests                    | 1, 2    |
 | Yoga of EatingTests/DayMealPopupViewTests.swift | New sheet tests                   | 3, 4    |
 | Yoga of EatingTests/*IntegrationTests.swift     | Integration tests                 | 5       |

 ---
 Risk Mitigation

 Risk: SwiftUI Form divider behavior varies by iOS version

 Mitigation: Test on iOS 16, 17, 18 simulators; have fallback custom divider

 Risk: Large dataset sync performance

 Mitigation: Implement batch syncing if >100 snapshots; add progress indicator

 Risk: Animation frame drops

 Mitigation: Profile with Instruments; optimize with .drawingGroup() if needed

 Risk: Sheet detent API compatibility

 Mitigation: Use @available(iOS 16, *) checks; graceful degradation for older iOS

 ---
 Definition of Done (Per Phase)

 - All code changes implemented
 - All new tests written and passing
 - All existing 234 tests still passing
 - Zero build warnings
 - Tech debt items completed
 - Accessibility verified with VoiceOver
 - Performance profiled (no regressions)
 - Code documented with comments
 - Tested on iPhone SE, iPhone 16, iPad

 ---
 Notes

 - TDD Approach: Write tests first, then implement to make them pass
 - No Breaking Changes: All existing APIs remain unchanged
 - Backward Compatibility: All @AppStorage keys and data models unchanged
 - Performance First: Profile each phase to ensure no regressions
 - Accessibility First: Every interactive element must work with VoiceOver