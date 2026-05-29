# Yoga of Eating — Claude Code Guide

SwiftUI iOS app for mindful eating. Meals logged via a journal UI; Firebase Cloud Functions score each meal and drive a reactive "smiley" character. Sleep data from HealthKit informs daily insights.

## Architecture

```
YogaOfEatingApp (entry point)
  └── MainViewModel (@StateObject, @MainActor)
        ├── logicService: MealLogicProvider              ← AILogicService in production
        ├── persistenceService                            ← PersistenceService (JSON on disk)
        ├── historicalService                             ← HistoricalDataService + Firestore sync
        ├── aiCoordinator: AIAnalysisCoordinating         ← AIAnalysisCoordinator
        ├── activityProvider: ActivityDataProvider        ← HealthKitService.shared
        ├── textSignalExtractor: TextSignalExtracting     ← TextSignalExtractor
        ├── synthesisEngine: DailySynthesizing            ← DailySynthesisEngine
        ├── insightLifecycleService: InsightLifecycling   ← InsightLifecycleService
        ├── synthesisScheduler: SynthesisScheduling       ← SynthesisScheduler
        ├── healthProfileService: HealthProfileServiceProtocol
        └── authService: AuthServiceProtocol?             ← nil in tests
```

**Always inject via protocol, never concrete type. Default `logicService` must be `AILogicService`.** See regression tests below.

Sub-folder CLAUDE.md files: [ViewModels/](ViewModels/CLAUDE.md) · [Views/](Views/CLAUDE.md) · [Logic/](Logic/CLAUDE.md) · [Yoga of EatingTests/](Yoga%20of%20EatingTests/CLAUDE.md)

## Commands

```bash
# Build
xcodebuild clean build -project "Yoga of Eating.xcodeproj" -scheme "Yoga of Eating" -destination "platform=iOS Simulator,name=iPhone 17"

# All tests
xcodebuild clean test -project "Yoga of Eating.xcodeproj" -scheme "Yoga of Eating" -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:"Yoga of EatingTests" -configuration Debug

# Single test file
xcodebuild test -project "Yoga of Eating.xcodeproj" -scheme "Yoga of Eating" -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:"Yoga of EatingTests/AIAnalysisIntegrationTests"

# Lint + format (run before committing)
swiftlint lint "Yoga of Eating" && swiftformat "Yoga of Eating" --config .swiftformat
```

**SwiftLint limits**: `force_unwrapping`/`force_cast` = error · file 300 lines (warn 250) · function 50 lines · line 120 chars · cyclomatic complexity 10 · nesting 3.

## SOLID & Design Rules

- **SRP**: One reason to change per class. No "and" in the description → split it.
- **OCP**: Extend via protocols; never modify existing classes.
- **LSP**: Mocks must be fully substitutable for real services (same contracts, same errors).
- **ISP**: Small focused protocols (`MealLogicProvider`), not monoliths.
- **DIP**: Inject via protocol in `init`; never instantiate dependencies inside a class. See [ViewModels/CLAUDE.md](ViewModels/CLAUDE.md) for code examples.
- **MVVM**: Views read `@Published` only; all business logic in ViewModels; no service calls from Views.
- **DRY/SSOT**: Every constant has one location. See [Logic/CLAUDE.md](Logic/CLAUDE.md).

## Security

- All user data access guarded by auth checks (`SecurityAndAuthTests.swift`).
- Sensitive data (meals, health scores, sleep) never logged in production — use `privacy: .private`.
- All disk data encrypted (Data Protection / Keychain for secrets). Never plaintext secrets in UserDefaults.
- HTTPS only; SSL validation always on. Auth tokens in headers, never URL params.
- User-facing errors are generic; details in `failureReason` / Crashlytics only (use `AppError`).
- All user input validated before processing; write tests in `InputValidationTests.swift`.

## AI Meal Analysis Flow

```
User types       → updateMealItemsLocalOnly → local score (0.5 stub), no AI
User hits "done" → updateMeal              → if !isAIAnalyzed: triggerAIAnalysisForMeal
                 → performDeepAnalysis     → guard AIAnalysisProvider cast
                 → AILogicService.analyzeMealQuality → Firebase "analyzeMeal"
                 → score, mood, insight   → meals[i].healthScore updated
                 → isAIAnalyzed = true   → reanalyzeAllMealsForSmileyState
```

Guards in `performDeepAnalysis` (in order): meal exists · `!isAIAnalyzed` · `!analysisInProgress` · description ≥ 5 chars · `logicService as? AIAnalysisProvider`.

## Insight / Synthesis Pipeline

```
Data change → SynthesisScheduler.schedule(_:)
           → debounce or immediate (.sleepLogged)
           → MainViewModel.performInsightLifecycle(trigger:)
           → DailySynthesisEngine.synthesize(...)   → DailySynthesis
           → InsightLifecycleService.generateEnrichedInsight(...) → DailyInsight
           → historicalService.updateInsight(...)
           → MainViewModel.$currentInsight updated
```

`SynthesisTrigger` cases: `.mealChanged`, `.sleepLogged`, `.journalUpdated`, `.todoChanged`, `.feelingChanged`, `.morningThoughtsUpdated`. Sleep fires immediately; all others debounced via `TimingConstants.synthesisDebounceNanoseconds`.

## Scoring Thresholds (SSOT: `ScoringThresholds.swift`)

```swift
healthy:   0.65  // above → .serene smiley, shrink scale
unhealthy: 0.35  // below → .overwhelmed smiley, grow scale
```

## Firebase & HealthKit Notes

- `FirebaseApp.configure()` runs in `YogaOfEatingApp.init()`. Guard `NSClassFromString("XCTestCase") != nil` skips it in tests.
- `AILogicService(functions: nil)` is safe in tests — returns 0.5 fallbacks.
- Sleep query window: yesterday 18:00 → today 12:00. Preferred source: `com.apple.health.*`.

## Critical Regression Tests — Must Stay Green

**Bug**: `MainViewModel()` once defaulted to `MealLogicService`; the AI analysis guard silently always failed; all meals got the 0.5 stub score.

**Rule**: `MainViewModel.init` must default `logicService` to `AILogicService()`. These 4 tests enforce it:
- `AIAnalysisIntegrationTests/test_defaultInit_logicServiceIsAIAnalysisProvider`
- `AIAnalysisIntegrationTests/test_defaultInit_performDeepAnalysis_reachesAIProvider`
- `MainViewModelAIAnalysisTests/test_defaultMainViewModel_usesAIAnalysisProvider`
- `MainViewModelAIAnalysisTests/test_defaultMainViewModel_aiAnalysisGuardPasses`

## Common Pitfalls

- **Never `MainViewModel()` in tests without `skipDataLoading: true`** — loads disk + HealthKit.
- **`@MainActor` on all ViewModel test classes**.
- **`Task {}` in `updateMeal` is fire-and-forget** — use `await triggerAIAnalysisForMeal` in integration tests.
- **`isAIAnalyzed` resets on content change** (`updateMealItemsLocalOnly`) — account for it in score tests.
- **OSLog `.debug` hidden by default** — use `.info` for debugging sessions.

## Build & Conventions

- Zero warnings on merge to `main`. Check: `xcodebuild ... clean build 2>&1 | grep -E "warning:|error:"`
- Branches: `feature/<desc>` or `fix/<desc>`
- Commits: `feat|fix|refactor|test|docs: <what changed>` + `Co-Authored-By: Claude <noreply@anthropic.com>`

## Working Style

- **Think Before Coding** — State assumptions explicitly. If uncertain, ask rather than guess. Push back when a simpler approach exists. Stop when confused; name what's unclear.
- **Simplicity First** — Minimum code that solves the problem. Nothing speculative. No abstractions for single-use code. Would a senior engineer call this overcomplicated? If yes, simplify.
- **Surgical Changes** — Touch only what you must. Don't "improve" adjacent code, comments, or formatting. Match existing style; don't refactor what isn't broken.
- **Goal-Driven Execution** — Define success criteria before starting. Loop until verified. Don't follow steps blindly — define done and iterate.
- **AI for judgment, code for determinism** — Use Claude/Gemini for classification, drafting, insight generation. Don't use AI for routing, retries, or transforms that Swift can do deterministically.
- **Surface context exhaustion** — Don't silently overrun context limits. Summarize and restart.
- **Surface conflicts, don't average them** — If two patterns contradict, pick the more recent/tested one, explain why, flag the other for cleanup. Don't blend conflicting patterns.
- **Read before you write** — Before adding code, read the protocol, its callers, and shared utilities. "Looks orthogonal" is dangerous in a codebase with many extensions and injected dependencies.
- **Checkpoint after every significant step** — Summarize what's done, what's verified, what's left. If you lose track, stop and restate before continuing.
- **Match conventions, even if you disagree** — Conformance > taste inside this codebase. If a convention is genuinely harmful, surface it — don't fork silently.
- **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is wrong if any were skipped. Default to surfacing uncertainty.

## Enforcement Checklist

Every PR before merge:
- [ ] Tests written BEFORE production code; all pass; none pass on first run
- [ ] Security-sensitive features have dedicated security tests
- [ ] Views use `@Published` only; no direct service calls from Views
- [ ] Dependencies injected via protocol in `init`
- [ ] No hardcoded magic values — all in constants files
- [ ] All user-facing strings in `Strings.swift`; all fonts via `FontTheme.*`; all colors via `AppTheme.*`
- [ ] No sensitive data logged; errors are generic to user
- [ ] Zero build warnings
- [ ] No `var` where `let` suffices; no unused imports; no commented-out code
- [ ] Mock tests use shared mocks from `Mocks.swift`; all regression tests green
