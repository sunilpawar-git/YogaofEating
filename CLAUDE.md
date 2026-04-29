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
