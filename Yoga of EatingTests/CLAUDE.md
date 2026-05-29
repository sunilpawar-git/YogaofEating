# Yoga of EatingTests/ — TDD Rules & Test Infrastructure

## TDD Cycle (Red-Green-Refactor) — Mandatory

**EVERY feature needs failing tests first. No exceptions.**

1. **Red** — Write the smallest failing test for ONE behavior
   - Name: `test_<scenario>_<expectedOutcome>` or `test_<given>_<when>_<then>`
   - One assertion per test (or logically grouped assertions)
   - Fail for the right reason — not a typo or compile error

2. **Green** — Write minimum production code to pass the test
   - Resist over-engineering; duplication is OK here
   - Do not refactor until the test passes

3. **Refactor** — Clean production AND test code without breaking tests
   - Eliminate duplication, extract helpers, apply SOLID
   - Run all tests after each refactoring step

**Before any feature implementation:**
- Write 3–5 tests FIRST, then implement
- If a test passes on the first run without code changes, tighten it

## Test File Layout (one file per behavior area)

| File | Purpose |
|---|---|
| `MainViewModelAIAnalysisTests.swift` | ViewModel AI analysis logic (unit) |
| `AILogicServiceTests.swift` | AILogicService unit tests (nil-functions + protocol conformance) |
| `AIAnalysisIntegrationTests.swift` | Full pipeline: typing → done → AI score → smiley state |
| `PersistenceServiceTests.swift` | JSON encode/decode round-trips |
| `HistoricalDataSyncTests.swift` | Firestore sync with mock cloud service |
| `SecurityAndAuthTests.swift` | Auth guard clauses, encryption, data protection |

UI tests live in `Yoga of EatingUITests/` (separate target — run separately).

## What to Mock vs. What to Test Real

| Layer | Unit tests | Integration tests |
|---|---|---|
| Firebase Functions | `MockAILogicService` | Firebase Emulator (not CI) |
| Persistence | `MockPersistenceService` | Real `PersistenceService` |
| HistoricalData | `MockHistoricalDataService` | Real `HistoricalDataService` |
| Auth & Security | `MockAuthService` / `MockAuthCoreProvider` | Manual / TestFlight only |
| Network | Mock URLSession | Real network only |

Never let a test touch the real filesystem, Firebase, or HealthKit.

## Mock Files

| File | Contents |
|---|---|
| `Mocks.swift` | Core service mocks: `MockAILogicService`, `MockPersistenceService`, `MockHistoricalDataService`, etc. |
| `Mocks+Auth.swift` | Auth mocks: `MockAuthService`, `MockAuthUser`, `MockAuthCoreProvider` |
| `Mocks+Services.swift` | Auxiliary service mocks added over time |

Test-local mocks (e.g. `SlowMockAILogicService`) can live inline in the test file.

## Test Fixtures

`TestBuilders.swift` — fluent builder classes (e.g. `MealBuilder`) for test data. Use these instead of ad-hoc `Meal(id: UUID(), ...)` literals. `TestBuilders+Synthesis.swift` extends for synthesis-specific builders.

## MainViewModelProtocol

`Logic/MainViewModelProtocol.swift` defines the minimal `@MainActor` protocol that `HistoricalDataService` calls back on. New services that delegate persistence back to the ViewModel should use this protocol.

## Common Test Pitfalls

- **Never instantiate `MainViewModel()` without `skipDataLoading: true`** — real init loads disk and launches HealthKit queries.
- **`@MainActor` on all ViewModel test classes** — `MainViewModel` is `@MainActor`; XCTest must match.
- **`Task {}` in `updateMeal` is fire-and-forget** — integration tests must `await Task.sleep` or call `await triggerAIAnalysisForMeal` directly.
- **`isAIAnalyzed` resets on content change** (`updateMealItemsLocalOnly`) — account for this in score-check tests.

## TDD Anti-Patterns (Never)

- ❌ Write production code, then tests to match it
- ❌ Skip tests for "simple" or "just UI" changes
- ❌ Tests that pass on first run without code changes
- ❌ Multiple behaviors in one test method
- ❌ Mock the code under test (mock at boundaries only)
- ❌ Tests that depend on execution order
- ❌ Leave failing tests in the codebase
- ❌ Test private implementation details

## Tests Verify Intent, Not Just Behavior

A test must encode WHY behavior matters, not just WHAT it does. If the business logic changes and the test still passes, the test is wrong. Every assertion should break when the underlying contract is violated — not just when the function signature changes.
