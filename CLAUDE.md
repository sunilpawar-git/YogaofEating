# Yoga of Eating — Claude Code Guide

## Project overview

SwiftUI iOS app for mindful eating. Users log meals via a journal-style interface; an AI-backed service (Firebase Cloud Functions) scores each meal and drives a reactive "smiley" character that grows or shrinks based on eating quality. Sleep data from HealthKit informs daily insights.

## Architecture

```
YogaOfEatingApp (entry point)
  └── MainViewModel (@StateObject, @MainActor)
        ├── logicService: MealLogicProvider   ← AILogicService in production
        ├── persistenceService                ← PersistenceService (JSON on disk)
        ├── historicalService                 ← HistoricalDataService + Firestore sync
        ├── insightService                    ← InsightGenerationService (Claude API)
        └── healthProfileService              ← HealthProfileService (UserDefaults)
```

**Key protocols — always inject via protocol, never concrete type:**
- `MealLogicProvider` — synchronous scoring + smiley state transitions
- `AIAnalysisProvider: MealLogicProvider` — adds async `analyzeMealQuality`
- `PersistenceServiceProtocol` — load/save app data
- `HistoricalDataServiceProtocol` — daily snapshots + Firestore sync
- `InsightGenerationServiceProtocol` — AI daily insight generation

**Default logicService must be `AILogicService`** (not `MealLogicService`). See regression below.

## TDD rules — non-negotiable

### Before writing any feature code, write the failing test first.

1. **Red** — write the smallest test that describes the behaviour. Run it; confirm it fails.
2. **Green** — write the minimum production code to pass the test.
3. **Refactor** — clean up without breaking tests.

### Test file per feature, not per class

Each behaviour area gets its own test file:
- `MainViewModelAIAnalysisTests.swift` — ViewModel AI analysis logic (unit)
- `AILogicServiceTests.swift` — AILogicService unit tests (nil-functions paths + protocol conformance)
- `AIAnalysisIntegrationTests.swift` — full pipeline: typing → done → AI score → smiley state
- `PersistenceServiceTests.swift` — JSON encode/decode round-trips
- `HistoricalDataSyncTests.swift` — Firestore sync with mock cloud service
- `E2ETests.swift` — UI-level smoke tests (launch, basic meal log, app restart)

### What to mock vs. what to test real

| Layer | Mock in unit tests | Real in integration tests |
|---|---|---|
| Firebase Functions (`AILogicService`) | `MockAILogicService` (conforms to `AIAnalysisProvider`) | Firebase Emulator (separate target, not CI) |
| Persistence | `MockPersistenceService` | Real `PersistenceService` in `PersistenceServiceTests` |
| HistoricalData | `MockHistoricalDataService` | Real `HistoricalDataService` in `HistoricalDataServiceTests` |
| Auth | `MockAuthService` / `MockAuthCoreProvider` | Manual / TestFlight only |

Never let a test touch the real filesystem, Firebase, or HealthKit. Use mocks at those boundaries.

### Mocks live in `Mocks.swift`

Shared mocks (`MockAILogicService`, `MockPersistenceService`, `MockHistoricalDataService`, etc.) are in `Yoga of EatingTests/Mocks.swift`. Add new shared mocks there. Test-local mocks (e.g. `SlowMockAILogicService`) can live inline in the test file.

## Critical regression tests — must stay green

These tests exist specifically because a production bug was discovered in the wild. Do not delete or skip them.

### AI analysis wiring regression

**Bug**: `MainViewModel()` defaulted to `MealLogicService` instead of `AILogicService`. The `performDeepAnalysis` guard `logicService as? AIAnalysisProvider` always failed. Firebase was never called. Meals silently received the 0.5 stub score.

**Guard tests** (in `AIAnalysisIntegrationTests.swift`):
```
test_defaultInit_logicServiceIsAIAnalysisProvider
test_defaultInit_performDeepAnalysis_reachesAIProvider
```
and in `MainViewModelAIAnalysisTests.swift`:
```
test_defaultMainViewModel_usesAIAnalysisProvider
test_defaultMainViewModel_aiAnalysisGuardPasses
```

**Rule**: `MainViewModel.init` must default `logicService` to `AILogicService()`. If you change this default for any reason, these four tests will fail and the PR must not merge.

## Firebase setup

- `FirebaseApp.configure()` runs in `YogaOfEatingApp.init()` before `@StateObject` renders.
- `AILogicService(functions: nil)` is safe in tests — it returns 0.5 fallbacks, does not throw.
- Do not call `FirebaseApp.configure()` in tests. The guard `NSClassFromString("XCTestCase") != nil` skips Firebase init in `YogaOfEatingApp.init()`.

## AI meal analysis flow

```
User types          → updateMealItemsLocalOnly  → local score (0.5 stub), no AI
User hits "done"    → updateMeal                → if !isAIAnalyzed: triggerAIAnalysisForMeal
                    → performDeepAnalysis        → guard AIAnalysisProvider cast
                    → AILogicService.analyzeMealQuality → Firebase "analyzeMeal" function
                    → result: score, mood, insight → meals[i].healthScore updated
                    → isAIAnalyzed = true        → reanalyzeAllMealsForSmileyState
```

**Guards in `performDeepAnalysis`** (in order):
1. Meal must exist by ID
2. `!isAIAnalyzed` — skip if already analyzed
3. `!analysisInProgress.contains(mealId)` — prevent concurrent duplicates
4. Description must be ≥ 5 characters
5. `logicService as? AIAnalysisProvider` — skip if not AI-capable (must never fire in prod)

## Scoring thresholds (`ScoringThresholds` — single source of truth)

```swift
healthy:   0.65   // above → .serene smiley, shrink scale
unhealthy: 0.35   // below → .overwhelmed smiley, grow scale
```

Do not duplicate these thresholds. Always import from `ScoringThresholds`.

## Sleep / HealthKit

- Query window: yesterday 18:00 → today 12:00
- Preferred source: device `com.apple.health.*` — filters out third-party apps
- Sleep score (0–100) feeds the daily insight pipeline
- HealthKit data is never mocked in unit tests — sleep-dependent features use mock historical data

## Common pitfalls

- **Never instantiate `MainViewModel()` without `skipDataLoading: true` in tests** — the real init loads from disk and launches async HealthKit queries.
- **`@MainActor` on all ViewModel tests** — `MainViewModel` is `@MainActor`; XCTest classes must match.
- **`Task {}` in `updateMeal` is fire-and-forget** — integration tests must `await Task.sleep` or use `await triggerAIAnalysisForMeal` directly to observe the async result.
- **`isAIAnalyzed` is reset by `updateMealItemsLocalOnly` when content changes** — this is intentional; tests that check score after local updates must account for it.
- **OSLog `.debug` messages do not appear in the Xcode console by default** — use `.info` for messages you need to see during debugging sessions.

## Tab Implementation Guidelines

When implementing a new tab view (e.g., Highlight, Reflect), follow this secure pattern to prevent data leakage:

### DO ✅
- **Accept data via parameters, never @EnvironmentObject**
  ```swift
  struct MyTabView: View {
      let data: (mealsCount: Int, averageScore: Double)?
      // Only receives what it needs
  }
  ```
- **Define minimal data contracts in MainViewModel via computed properties**
  ```swift
  var myTabData: (mealsCount: Int, averageScore: Double)? {
      guard self.isViewingToday else { return nil }
      guard !self.meals.isEmpty else { return nil }
      let avg = self.meals.map { $0.healthScore }.reduce(0, +) / Double(self.meals.count)
      return (mealsCount: self.meals.count, averageScore: avg)
  }
  ```
- **Use mock data in previews**
  ```swift
  #Preview {
      MyTabView(data: (mealsCount: 3, averageScore: 0.75))
  }
  ```
- **Write data isolation unit tests**
  ```swift
  func test_myTabView_cannotAccessMeals() { ... }
  func test_myTabView_cannotAccessSleepData() { ... }
  ```

### DON'T ❌
- **Never use @EnvironmentObject to access MainViewModel in tab views**
  ```swift
  // WRONG ❌
  struct MyTabView: View {
      @EnvironmentObject var viewModel: MainViewModel
      // Now has access to ALL user data
  }
  ```
- **Never hardcode mock data in non-preview code**
- **Never access global state without explicit parameters**
- **Never skip data isolation tests**

### Security Principle: Principle of Least Privilege
Each tab view receives ONLY the data it needs. This prevents:
- Accidental data leakage through UI bugs
- Malicious code access to sensitive user information
- Future developers making mistakes with data access

### Code Review Checklist for Tab PRs
- ✓ Tab view accepts data via parameters, not @EnvironmentObject
- ✓ No direct references to `MainViewModel` in tab view code
- ✓ Previews use mock data, not `MainViewModel()`
- ✓ Computed properties on MainViewModel are minimal and documented
- ✓ Unit tests verify data isolation (tab cannot access unintended data)

## Build warnings policy

Zero warnings on merge to `main`. Current known clean state:
- No `var` where `let` suffices
- `AppStore.requestReview(in:)` — not the deprecated `SKStoreReviewController` variant
- No unused imports

Run `xcodebuild -scheme "Yoga of Eating" -destination "platform=iOS Simulator,name=iPhone 16" clean build 2>&1 | grep -E "warning:|error:"` to check before committing.

## Branch and commit conventions

- Feature branches: `feature/<short-description>`
- Fix branches: `fix/<short-description>`
- Commit subject: `<type>: <what changed>` where type is `feat`, `fix`, `refactor`, `test`, `docs`
- Co-author all Claude-assisted commits with `Co-Authored-By: Claude <noreply@anthropic.com>`
