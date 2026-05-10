# Plan: Calorie / TDEE Pill — 6-Phase TDD Implementation

**TL;DR** — Six self-contained phases, each one green-builds and all tests pass before the next begins. Calories per meal come from the existing Gemini AI (adds `estimatedCalories` to the `analyzeMeal` Cloud Function). TDEE is dynamic: HealthKit `basalEnergyBurned` + `activeEnergyBurned` from Apple Watch, with a clean fallback chain. Uses "Cal" throughout. World-class pill UI with liquid fill + detail sheet.

---

## Design Intent

### Screen anatomy (Energise tab — below smiley)

```
              │
              │
             🙂                  ← SmileyView 120×120 (breathing animation)
              │
   ╭────────────────────────╮    ← CaloriePillView (~220pt wide, 34pt tall)
   │▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░│      liquid fill from left (green/amber/coral)
   │ 🔥  1,250  /  2,250 Cal  ›│   ultraThinMaterial capsule, FontTheme fonts
   ╰────────────────────────╯
              │
    TAP  TO  LOG               ← existing monospaced caption
    Avg. 69% · 2 meals         ← existing daySummaryText
```

### Pill states

```
Normal (56% consumed):
╭──────────────────────────────────────╮
│▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░│  ← AppTheme.CaloriePill.fillOnTrack
│  🔥   1,250  /  2,250 Cal          ›  │
╰──────────────────────────────────────╯

Approaching (85% consumed):
╭──────────────────────────────────────╮
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░│  ← AppTheme.CaloriePill.fillApproaching
│  🔥   1,900  /  2,250 Cal          ›  │
╰──────────────────────────────────────╯

Over goal (107%):
╭──────────────────────────────────────╮
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│  ← AppTheme.CaloriePill.fillOver (coral, full)
│  🔥   2,410  /  2,250 Cal          ›  │
╰──────────────────────────────────────╯

No profile (TDEE unknown):
╭──────────────────────────────────────╮
│                                      │  ← no fill
│  🔥  1,250 Cal  ·  Set up profile →  │  ← amber text, tappable → Settings
╰──────────────────────────────────────╯

Hidden: consumed == 0 AND tdee == nil (empty-day Zen state preserved)
```

### Tap → CalorieDetailSheet (bottom sheet — matches ScoreBreakdownSheet pattern)

```
╭─────────────────────────────────────────╮
│  ▬                                      │  ← drag handle
│   Daily Energy                          │
│   ╭──────────────────────────────╮      │
│   │  Consumed   ████████░  1,250 │      │
│   │  Goal       ████████████ 2,250│     │
│   │  Remaining             1,000 │      │
│   ╰──────────────────────────────╯      │
│   By meal                               │
│   🌅 Breakfast (08:30)    ~620 Cal      │
│   ☀️  Lunch (13:00)        ~630 Cal     │
│   Today's activity (Apple Watch)        │
│   🏃 Active    +340 Cal                 │
│   💤 Basal     +1,910 Cal               │
│   Total TDEE   2,250 Cal                │
╰─────────────────────────────────────────╯
```

---

## Phase 0 — Foundation: Types · Strings · AppTheme Colors
*Pure additive. No behavior changes. Establishes SSOT for everything downstream.*

### TDD — write FIRST in `Yoga of EatingTests/CaloriePillTests.swift` (Red)

- `test_caloriePillData_init_setsConsumedAndTDEE`
- `test_caloriePillData_equality_sameValues`
- `test_caloriePillData_progressFraction_clampedAt1WhenOverGoal` (consumed 2500, tdee 2000 → 1.0)
- `test_caloriePillData_progressFraction_zeroWhenTDEENil`
- `test_caloriePillData_fillColor_greenBelow70Percent`
- `test_caloriePillData_fillColor_amberAt85Percent`
- `test_caloriePillData_fillColor_coralWhenOver100Percent`
- `test_caloriePillData_formattedConsumed_usesLocaleGroupingSeparator`
- `test_caloriePillData_isVisible_falseWhenConsumedZeroAndTDEENil`

### Implementation (Green)

- **NEW** `Models/CaloriePillData.swift`
  - `struct CaloriePillData: Equatable`
  - Properties: `consumed: Int`, `tdee: Int?`
  - Computed: `progressFraction: Double` (clamped 0–1), `fillColor: Color`, `isVisible: Bool`
  - Formatting helpers: `formattedConsumed`, `formattedTDEE`, `formattedFraction`
  - `isVisible: Bool` — `false` only when `consumed == 0 && tdee == nil`; `true` when `consumed == 0 && tdee != nil` (shows "0 / 2,250 Cal" so user sees daily target on first load of the day)
  - All colors via `AppTheme.CaloriePill.*` — no hardcoded Color values

- **NEW** `Logic/ThemeCaloriePill.swift`
  - `extension AppTheme { enum CaloriePill { ... } }` (keeps `Theme.swift` under 300 lines)
  - Named tokens: `fillOnTrack` (green), `fillApproaching` (amber), `fillOver` (coral), `pillBackground`, `pillHeight: CGFloat = 34`, `pillCornerRadius: CGFloat = 17`

- **MODIFY** `Logic/Strings.swift`
  - Add `enum CaloriePill` at bottom
  - `static let calUnit = "Cal"`
  - `static func consumedOfTarget(consumed: Int, target: Int) -> String` — "1,250 / 2,250 Cal"
  - `static func consumedOnly(_ kcal: Int) -> String` — "1,250 Cal"
  - `static let setupProfile = "Set up profile"`
  - `static func accessibilityLabel(consumed: Int, tdee: Int?) -> String`
  - If `Strings.swift` exceeds 300 lines after addition → split into `Strings+CaloriePill.swift` extension immediately (enforce SSOT, not duplication)

### Tech Debt Resolution
None introduced. All new files. SwiftLint file-length check enforced before moving on.

---

## Phase 1 — Model Layer: `Meal.estimatedCalories` + `DailySmileySnapshot.totalCalories`
*Backward-compatible Codable additions. Zero runtime behavior change.*

### TDD — add to `CaloriePillTests.swift` (Red)

- `test_meal_encodeDecode_preservesEstimatedCalories`
- `test_meal_decodeLegacyJSON_estimatedCaloriesDefaultsToNil`
- `test_snapshot_encodeDecode_preservesTotalCalories`
- `test_snapshot_decodeLegacyJSON_totalCaloriesDefaultsToNil`
- `test_snapshot_withTotalCalories_returnsUpdatedSnapshot`

### Implementation (Green)

- **MODIFY** `Models/Meal.swift`
  - Add `var estimatedCalories: Int? = nil`
  - Add `.estimatedCalories` to `CodingKeys` (if Meal uses explicit keys)
  - In `init(from decoder:)` use `decodeIfPresent` — matching the established backward-compat pattern in `DailySmileySnapshot`

- **MODIFY** `Models/DailySmileySnapshot.swift`
  - Add `let totalCalories: Int?` (optional, nil in legacy data)
  - Add `func withTotalCalories(_ calories: Int) -> DailySmileySnapshot` builder (follows `withReflection`, `withHighlightData` pattern)
  - Update `init`, `init(from:)`, `CodingKeys`

### Tech Debt Resolution
`DailySmileySnapshot` init has 11+ parameters — pre-existing debt, not introduced here. Builder pattern (`withX()`) mitigates call-site burden. Document in code comment: `// NOTE: Long init is pre-existing; use withX() builders at call sites.`

---

## Phase 2 — AI Protocol & Pipeline: `estimatedCalories` end-to-end
*Breaking protocol change — atomic commit across all conformances.*

### TDD — update mocks FIRST, then add tests (Red → compile errors = Red)

**In `Yoga of EatingTests/Mocks.swift`:** add `stubbedCalories: Int? = 500` to `MockAILogicService`

**New tests in `CaloriePillTests.swift`:**
- `test_mainViewModel_storesEstimatedCalories_afterAIAnalysis`
- `test_mainViewModel_estimatedCalories_notOverwrittenOnReanalysis`
- `test_mainViewModel_estimatedCaloriesNil_onAnalysisFailure`

### Implementation (Green — one atomic set of changes)

**Backend:**
- `functions/index.js` — add rule 5 to Gemini prompt: `"estimatedCalories": integer total calories for this meal`. Add to example JSON. Return: `estimatedCalories: typeof data.estimatedCalories === 'number' ? Math.round(data.estimatedCalories) : null`

**Protocol — introduce `MealAnalysisResult` struct (eliminates tech debt proactively):**
- `Logic/MealLogicService.swift`
  - Add `struct MealAnalysisResult` with `score: Double`, `mood: SmileyMood`, `sound: String`, `insight: String?`, `estimatedCalories: Int?`
  - Update `AIAnalysisProvider.analyzeMealQuality` to return `MealAnalysisResult` (replaces 4-tuple, prevents future tuple growth)

**All conformances updated in same commit (no orphan conformances):**
- `Logic/AILogicService.swift` — parse `data["estimatedCalories"] as? Int`, return `MealAnalysisResult`
- `ViewModels/MainViewModel+AIAnalysis.swift` — store `result.estimatedCalories` (only if non-nil, do not overwrite with nil on retry failure)
- `Yoga of EatingTests/Mocks.swift` — `MockAILogicService`
- `Yoga of EatingTests/MainViewModelTests.swift` — `RegressionTestAIMock` + inline mock at line 592
- `Yoga of EatingTests/BlankTextRegressionTests.swift` — `InstantMockAILogicService`
- `Yoga of EatingTests/ConcurrentAnalysisTests.swift` — `TrackingMockAILogicService`
- `Yoga of EatingTests/MainViewModelAIAnalysisTests.swift` — `SlowMockAILogicService` + both inline mocks
- `Yoga of EatingTests/AIAnalysisCoordinatorTests.swift` — both inline mocks

### Tech Debt Resolution
Tuple-as-return eliminated by introducing `MealAnalysisResult` in the same phase. No forward debt. All 8+ conformances updated atomically.

---

## Phase 3 — HealthKit Activity Layer + TDEE Resolution
*Introduces `ActivityDataProvider` protocol (ISP) — all new code testable without real HealthKit.*

### TDD — add to `CaloriePillTests.swift` (Red)

- `test_caloriePillData_tdeeFromHealthKit_basalPlusActive`
- `test_caloriePillData_tdeeHybrid_profileBMRPlusActiveWhenBasalMissing`
- `test_caloriePillData_tdeeFallback_profileStaticTDEEWhenNoHealthKit`
- `test_caloriePillData_tdeeNil_whenNoProfileAndNoHealthKit`
- `test_caloriePillData_consumed_sumOfAnalyzedMealsOnly`
- `test_caloriePillData_consumed_zeroWhenNoCalorieDataOnAnyMeal`

### Implementation (Green)

- **NEW** `Logic/ActivityDataProvider.swift`
  - `protocol ActivityDataProvider` — ISP-compliant, two methods only
  - `func fetchActiveCaloriesBurned(for date: Date) async -> Double?`
  - `func fetchBasalCaloriesBurned(for date: Date) async -> Double?`

- **MODIFY** `Logic/HealthKitService.swift`
  - `extension HealthKitService: ActivityDataProvider`
  - Add `.activeEnergyBurned`, `.basalEnergyBurned` to `requestAuthorization()` typesToRead
  - Private `fetchDailyEnergySum(type: HKQuantityTypeIdentifier, for date: Date) async -> Double?` (shared helper — DRY)
  - Both public methods call helper with appropriate identifier

- **MODIFY** `Yoga of EatingTests/Mocks.swift`
  - Add `MockActivityDataProvider: ActivityDataProvider` with `stubbedActiveCalories: Double?`, `stubbedBasalCalories: Double?`

- **MODIFY** `ViewModels/MainViewModel.swift`
  - Inject `activityProvider: ActivityDataProvider = HealthKitService.shared`
  - Add `@Published var todayActiveCalories: Double?`, `@Published var todayBasalCalories: Double?`
  - Add `func loadTodayActivityData() async` (called at startup, parallel with sleep fetch via `async let`)

- **NEW** `ViewModels/MainViewModel+CaloriePill.swift`
  - Computed `var caloriePillData: CaloriePillData?`
  - TDEE resolution order:
    1. `basalCalories + activeCalories` (both present — Apple Watch)
    2. `profile.bmr + activeCalories` (hybrid — no basal from HealthKit)
    3. `profile.tdee` (static BMR × 1.2 — no HealthKit activity at all)
    4. `nil` (no profile set up)
  - `consumed = meals.compactMap(\.estimatedCalories).reduce(0, +)`
  - Returns `nil` when `consumed == 0 && tdee == nil` (hides pill — Zen empty state preserved)

### Tech Debt Resolution
Pre-existing: sleep fetches use `HealthKitService.shared` directly (not protocolized). Not introduced here. Documented with `// FIXME: Sleep fetch bypasses ActivityDataProvider — future refactor`. No regression. Zero new debt.

---

## Phase 4 — `CaloriePillView` UI Component
*Pure UI. No ViewModel changes. Fully isolated and previewable.*

### TDD — add to `CaloriePillTests.swift` (Red)

- `test_caloriePillView_showsPillWhenDataIsVisible`
- `test_caloriePillView_hidesWhenDataIsNil`
- `test_caloriePillView_showsSetupPromptWhenTDEENil`
- `test_caloriePillView_accessibilityLabel_includesConsumedAndTDEE`
- `test_caloriePillView_accessibilityLabel_setupPromptWhenNoTDEE`

### Implementation (Green)

- **NEW** `Components/CaloriePillView.swift` (target < 200 lines)
  - `GeometryReader` measures available width → fill width = `progressFraction × totalWidth`
  - Background: fill `Capsule` in `AppTheme.CaloriePill.fillColor` + overlay `Capsule` in `.ultraThinMaterial`
  - Content HStack: `Image(systemName: "flame.fill")` (amber tint) + text + optional `Image(systemName: "chevron.right")`
  - Three content states driven by `CaloriePillData?`:
    - `nil` → `EmptyView` (hidden, no hit testing)
    - `isVisible && tdee != nil` → full fraction text
    - `isVisible && tdee == nil` → consumed + setup prompt (amber text)
  - `var onTap: (() -> Void)? = nil` — caller owns navigation state (MVVM clean); omitting it suppresses the chevron and disables tap handling (used for historical read-only pill)
  - Spring animation on `consumed` change via `.onChange(of: data?.consumed)`
  - Fonts: `FontTheme.*` — no hardcoded sizes
  - Colors: `AppTheme.CaloriePill.*` — no hardcoded Color values
  - Strings: `Strings.CaloriePill.*` — no hardcoded text
  - `.accessibilityElement(children: .combine)` + `.accessibilityLabel(...)`
  - `#Preview` blocks for all 3 states + nil state

### Tech Debt Resolution
None. File under 200 lines. All values from SSOT. Preview coverage for all states ensures visual regression detection.

---

## Phase 5 — Wire: `DayTimelineView` + `MainScreenView` + Snapshot Persistence
*Connects all pieces. Integration tests validate end-to-end.*

### TDD — integration tests in `CaloriePillTests.swift` (Red)

- `test_integration_mealAnalyzed_pillDataUpdates` — full pipeline: VM + mock AI → `caloriePillData.consumed > 0`
- `test_integration_snapshotPreservesTotalCalories` — save snapshot with analyzed meals → reload → `totalCalories` matches
- `test_integration_historicalPill_showsStoredCalories` — snapshot with `totalCalories = 1400` → historical view receives pill data

### Implementation (Green)

- **MODIFY** `Components/DayTimelineView.swift`
  - Add parameter: `var caloriePillData: CaloriePillData? = nil`
  - Add `@State private var showCalorieDetail = false` (local UI state — sheet presentation is a View concern, not a domain concern; belongs here, not in ViewModel)
  - In `smileyAddButton` VStack: insert `CaloriePillView(data: caloriePillData, onTap: { showCalorieDetail = true })` between `SmileyView(...)` and `Text(tapToLog...)`, with `spacing: 12`
  - In `historicalDaySummary` VStack: insert `CaloriePillView(data: caloriePillData)` below meal count text (no `onTap` → no chevron, read-only)
  - Present `.sheet(isPresented: $showCalorieDetail) { ... }` on root VStack (wired in Phase 6)
  - Update both `#Preview` blocks with sample `CaloriePillData`
  - **Enforce file length**: if > 300 lines after edit, extract `smileyAddButton` + `historicalDaySummary` into `DayTimelineView+SmileySection.swift`

- **MODIFY** `Views/MainScreenView.swift`
  - Today timeline: add `caloriePillData: viewModel.caloriePillData` (no `onCaloriePillTap` parameter — sheet state is owned by `DayTimelineView` internally; see Phase 6)
  - Historical: inline `CaloriePillData(consumed: snapshot?.totalCalories ?? 0, tdee: viewModel.healthProfileService.getUserHealthProfile().map { Int($0.tdee) })` — `profile` is resolved via the injected `healthProfileService` already accessible through `viewModel`; no new abstraction needed

- **MODIFY** `Logic/HistoricalDataService.swift` or `HistoricalDataService+Updates.swift`
  - When building/updating snapshot: `let total = meals.compactMap(\.estimatedCalories).reduce(0, +)`, call `.withTotalCalories(total)` if `total > 0`

### Tech Debt Resolution
`DayTimelineView` parameter count increases by one (`caloriePillData`). Verify SwiftLint file-length. If breached, split extension file immediately. No parameter-object refactor — pre-existing `MealUpdateActions` pattern is already the grouping approach for that concern. `@State` sheet flag is local View state — correct MVVM placement.

---

## Phase 6 — `CalorieDetailSheet` + Final Polish
*Depth layer. Matches existing `ScoreBreakdownSheet` + `InsightBottomSheet` pattern exactly.*

### TDD — add to `CaloriePillTests.swift` (Red)

- `test_calorieDetailData_perMealBreakdown_matchesMeals`
- `test_calorieDetailData_remainingCalories_tdeeMinusConsumed`
- `test_calorieDetailData_remainingCalories_nilWhenTDEENil`
- `test_calorieDetailData_activityBreakdown_showsBasalAndActive`

### Implementation (Green)

- **NEW** `Models/CalorieDetailData.swift`
  - `struct CalorieDetailData: Equatable`
  - `consumed: Int`, `tdee: Int?`, `basalCalories: Double?`, `activeCalories: Double?`
  - `mealBreakdown: [MealCalorieEntry]` — define `struct MealCalorieEntry: Equatable { let label: String; let calories: Int }` in the same file; avoids tuple array which cannot auto-conform to `Equatable` and would require a custom `==` implementation
  - Computed: `remaining: Int?` — `tdee.map { $0 - consumed }`

- **MODIFY** `ViewModels/MainViewModel+CaloriePill.swift`
  - Add `var calorieDetailData: CalorieDetailData` computed from current meals + activity data

- **NEW** `Components/CalorieDetailSheet.swift` (target < 250 lines)
  - Drag handle + "Daily Energy" heading
  - Consumed / Goal / Remaining rows with inline mini progress bar
  - Per-meal list with meal type emoji + time + "~N Cal"
  - Apple Watch activity section (basal + active rows); hidden if both nil
  - All strings from `Strings.CaloriePill.*`; all colors from `AppTheme.CaloriePill.*`; all fonts from `FontTheme.*`
  - If approaching 250 lines → extract meal list to `CalorieDetailSheet+MealBreakdown.swift`

- **MODIFY** `Components/DayTimelineView.swift`
  - Populate the `.sheet(isPresented: $showCalorieDetail) { CalorieDetailSheet(data: calorieDetailData) }` stub added in Phase 5 with the real sheet content now that `CalorieDetailSheet` exists

### Final Audit (before marking Phase 6 complete)
- `swiftlint lint "Yoga of Eating"` — zero warnings
- `swiftformat "Yoga of Eating" --config .swiftformat` — no changes needed
- `xcodebuild clean build ... 2>&1 | grep -E "warning:|error:"` — zero output
- All `CaloriePillTests` pass
- All pre-existing tests pass (regression green)
- Search codebase for `"Cal"` literal string — must only appear in `Strings.CaloriePill.calUnit`
- Search for `Color.green`, `Color.orange`, `Color.red` in new files — must be zero (all via `AppTheme.CaloriePill.*`)
- Search for `.system(size:` in new files — must be zero (all via `FontTheme.*`)

---

## Cybersecurity Checklist (applied across all phases)

- `estimatedCalories` is personal health data — never logged via OSLog in production builds; only non-sensitive meal IDs use `.public` privacy
- Firebase response parsing uses `as?` with safe defaults — no force-unwrap, no crash path, no internal error exposed to user
- `ActivityDataProvider.fetch*` methods return `nil` gracefully on HealthKit authorization denial — no error message, no crash
- HealthKit `typesToRead` follows principle of least privilege — only `activeEnergyBurned` and `basalEnergyBurned` added; no write access requested
- `CalorieDetailSheet` shows no raw HealthKit source bundle IDs or internal identifiers to the user
- All user-displayed calorie numbers are rounded integers — no floating point precision leaks (e.g., `1249.9999...` → `1250`)

---

## New Files Summary

| File | Phase | Purpose |
|------|-------|---------|
| `Yoga of EatingTests/CaloriePillTests.swift` | 0–6 | All TDD tests |
| `Models/CaloriePillData.swift` | 0 | Core data model + computed properties |
| `Logic/ThemeCaloriePill.swift` | 0 | AppTheme.CaloriePill color/dimension tokens |
| `Logic/ActivityDataProvider.swift` | 3 | ISP protocol for HealthKit activity |
| `Models/CalorieDetailData.swift` | 6 | Detail sheet data model |
| `Components/CaloriePillView.swift` | 4 | Pill UI component |
| `Components/CalorieDetailSheet.swift` | 6 | Detail bottom sheet |
| `ViewModels/MainViewModel+CaloriePill.swift` | 3 | caloriePillData + calorieDetailData computed props |

## Modified Files Summary

| File | Phase | Change |
|------|-------|--------|
| `Logic/Strings.swift` | 0 | Add `enum CaloriePill` |
| `Logic/MealLogicService.swift` | 2 | `MealAnalysisResult` struct; update `AIAnalysisProvider` |
| `Logic/AILogicService.swift` | 2 | Parse + return `estimatedCalories` in `MealAnalysisResult` |
| `Logic/HealthKitService.swift` | 3 | `ActivityDataProvider` conformance + 2 public + 1 private method |
| `Models/Meal.swift` | 1 | `estimatedCalories: Int?` + Codable backward-compat |
| `Models/DailySmileySnapshot.swift` | 1 | `totalCalories: Int?` + `withTotalCalories()` builder |
| `ViewModels/MainViewModel.swift` | 3 | `activityProvider`, activity `@Published` props |
| `ViewModels/MainViewModel+AIAnalysis.swift` | 2 | Store `estimatedCalories` after analysis |
| `Components/DayTimelineView.swift` | 5, 6 | Pill param, insertion in both today + historical, sheet state |
| `Views/MainScreenView.swift` | 5 | Pass `caloriePillData` + tap handler in today + historical |
| `functions/index.js` | 2 | Gemini prompt rule 5 + parse + return `estimatedCalories` |
| `Yoga of EatingTests/Mocks.swift` | 2, 3 | Update `MockAILogicService`; add `MockActivityDataProvider` |
| 6× test files with mock conformances | 2 | Update `analyzeMealQuality` to return `MealAnalysisResult` |

---

## Build + Test Commands (run after each phase)

```bash
# Build check
xcodebuild clean build \
  -project "Yoga of Eating.xcodeproj" \
  -scheme "Yoga of Eating" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  2>&1 | grep -E "warning:|error:|BUILD"

# All tests
xcodebuild test \
  -project "Yoga of Eating.xcodeproj" \
  -scheme "Yoga of Eating" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:"Yoga of EatingTests" \
  2>&1 | tail -30

# Calorie pill tests only (fast feedback loop)
xcodebuild test \
  -project "Yoga of Eating.xcodeproj" \
  -scheme "Yoga of Eating" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:"Yoga of EatingTests/CaloriePillTests" \
  2>&1 | tail -20

# Code quality
swiftlint lint "Yoga of Eating"
swiftformat "Yoga of Eating" --config .swiftformat
```
