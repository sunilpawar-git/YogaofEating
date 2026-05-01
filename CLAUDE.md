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

### TDD-Driven Development Workflow (Mandatory)

**EVERY feature must follow Test-Driven Development (TDD). No exceptions. No feature code without failing tests first.**

#### The TDD Cycle (Red-Green-Refactor)

1. **Red** — Write the smallest possible failing test that describes ONE behavior
   - Test must fail with a clear error message
   - Name tests with descriptive patterns: `test_<scenario>_<expectedOutcome>` or `test_<given>_<when>_<then>`
   - One assertion per test, or logically grouped assertions in a logical flow
   - Ensure the test fails for the right reason (not a typo or compilation error)

2. **Green** — Write the minimum production code to make the test pass
   - Resist over-engineering; just make it pass
   - Duplicate code is OK at this stage; refactoring comes next
   - Do not refactor until the test passes
   - If the test passes but you used a hack, that's OK for now

3. **Refactor** — Clean up production code AND test code without breaking tests
   - Eliminate duplication (DRY principle)
   - Extract helper functions and constants (SSOT)
   - Apply SOLID principles (Single Responsibility, etc.)
   - Run all tests after each refactoring step
   - Refactoring is not optional; it's part of the cycle

#### Before Any Feature Implementation

- **No feature code exists without corresponding failing tests**
- **Write 3–5 tests FIRST; then implement the feature**
- **Each test tests ONE behavior; never combine concerns**
- **If you write a test and it passes immediately, the test is too loose — tighten it**

### Test file per feature, not per class

Each behaviour area gets its own test file:
- `MainViewModelAIAnalysisTests.swift` — ViewModel AI analysis logic (unit)
- `AILogicServiceTests.swift` — AILogicService unit tests (nil-functions paths + protocol conformance)
- `AIAnalysisIntegrationTests.swift` — full pipeline: typing → done → AI score → smiley state
- `PersistenceServiceTests.swift` — JSON encode/decode round-trips
- `HistoricalDataSyncTests.swift` — Firestore sync with mock cloud service
- `SecurityAndAuthTests.swift` — auth guard clauses, encryption, data protection
- `E2ETests.swift` — UI-level smoke tests (launch, basic meal log, app restart)

### What to mock vs. what to test real

| Layer | Mock in unit tests | Real in integration tests |
|---|---|---|
| Firebase Functions (`AILogicService`) | `MockAILogicService` (conforms to `AIAnalysisProvider`) | Firebase Emulator (separate target, not CI) |
| Persistence | `MockPersistenceService` | Real `PersistenceService` in `PersistenceServiceTests` |
| HistoricalData | `MockHistoricalDataService` | Real `HistoricalDataService` in `HistoricalDataServiceTests` |
| Auth & Security | `MockAuthService` / `MockAuthCoreProvider` | Manual / TestFlight only; test guards in unit tests |
| Network | Mock HTTP client / URLSession | Real network in integration tests only |

Never let a test touch the real filesystem, Firebase, or HealthKit. Use mocks at those boundaries.

### Mocks live in `Mocks.swift`

Shared mocks (`MockAILogicService`, `MockPersistenceService`, `MockHistoricalDataService`, etc.) are in `Yoga of EatingTests/Mocks.swift`. Add new shared mocks there. Test-local mocks (e.g. `SlowMockAILogicService`) can live inline in the test file.

### TDD Anti-Patterns (NEVER do these)

- ❌ Write production code, then write tests to pass it (inverted workflow)
- ❌ Skip tests because "it's too simple" or "it's just a UI change"
- ❌ Write tests that pass on the first run without any code changes
- ❌ Test multiple behaviors in one test method
- ❌ Mock everything, including the code under test (mock at boundaries, not internals)
- ❌ Write tests that depend on test execution order
- ❌ Leave failing tests in the codebase (either fix or delete them)
- ❌ Test private implementation details; test behavior through public interfaces

## SOLID & Design Principles — Non-Negotiable

### Single Responsibility Principle (SRP)

Each class/struct has ONE reason to change. Examples:

- ❌ `DataManager` (violates SRP: handles persistence, network, caching, validation)
- ✅ `PersistenceService` (only handles JSON encode/decode and disk I/O)
- ✅ `AILogicService` (only calls Firebase Functions; receives mocked results in tests)
- ✅ `ScoringValidator` (validates score ranges; nothing else)

**Test for SRP**: If you can't describe a class's responsibility in one sentence without "and" or "also", it violates SRP.

### Open/Closed Principle (OCP)

- Classes are OPEN for extension, CLOSED for modification
- Extend via protocols and inheritance, not by modifying existing code
- Example: Add a new scoring strategy by creating `ScoringStrategy` protocol, not by modifying `MealLogicProvider`

### Liskov Substitution Principle (LSP)

- Any implementation of a protocol must be substitutable for any other
- All `MealLogicProvider` implementations must work identically (in tests and production)
- Mock implementations must behave exactly like real implementations (same contracts, same error cases)

### Interface Segregation Principle (ISP)

- Clients depend on small, focused protocols, not large monolithic ones
- ❌ `AppService` protocol (has 20 methods; clients only use 2–3)
- ✅ `MealLogicProvider` (small, focused)
- ✅ `AIAnalysisProvider: MealLogicProvider` (extends with one responsibility)

### Dependency Inversion Principle (DIP)

- High-level modules depend on abstractions (protocols), not concrete types
- Inject dependencies via initializers or property injection
- NEVER create dependencies inside a class; always accept them as parameters
- Example:
  ```swift
  // ❌ BAD: Direct dependency on concrete type
  class MainViewModel {
      let service = AILogicService() // Hard to test
  }
  
  // ✅ GOOD: Dependency injection via protocol
  class MainViewModel {
      let logicService: MealLogicProvider // Protocol; easy to mock in tests
      init(logicService: MealLogicProvider = AILogicService()) { ... }
  }
  ```

### DRY (Don't Repeat Yourself)

- **Extract shared code into helper functions, extensions, or services**
- **Use SSOT for constants and thresholds (never hardcode magic values)**
- **Scoring thresholds, API endpoints, timing constants → SSOT single location**
- ❌ `let threshold = 0.65` appears in multiple files
- ✅ `ScoringThresholds.healthy` (imported everywhere)

### SSOT (Single Source of Truth)

**Every piece of configurable or reusable data has ONE location:**

- Scoring thresholds → `ScoringThresholds.swift`
- API endpoints → `APIConstants.swift` or Firebase config
- Timing values (analysis delay, retry intervals) → `TimingConstants.swift`
- Error messages → `LocalizedStrings.swift` or Localizable.strings
- Test fixtures → `Mocks.swift`

**Test for SSOT**: Search the codebase for a constant value (e.g., `0.65`). If it appears more than once outside of constants files, you have a SSOT violation.

### MVVM Compliance

**Data Flow**: View → ViewModel → Model (Services/Repositories)

- Views are **read-only**; they display `@Published` properties from ViewModels
- ViewModels handle all business logic and coordinate services
- Models are pure data structures
- **NEVER access services directly from Views; always go through ViewModel**

Example (✅ correct MVVM):
```swift
struct MealLogView: View {
    @StateObject var viewModel: MealViewModel
    var body: some View {
        Button("Analyze") {
            viewModel.analyzeCurrentMeal() // ViewModel method, not direct service call
        }
    }
}

@MainActor class MealViewModel: ObservableObject {
    @Published var mealScore: Double = 0.5
    let logicService: MealLogicProvider
    
    func analyzeCurrentMeal() {
        // Calls service, updates @Published property
        mealScore = logicService.calculateScore(...)
    }
}
```



## Cybersecurity & Data Protection — Critical

### Authentication & Authorization

- **All user data access must be guarded by authentication checks**
- **Authorization: users can only access their own data**
- Test these guards in `SecurityAndAuthTests.swift`:
  ```swift
  func test_userCannotAccessOtherUsersData() { ... }
  func test_analysisRequiresAuthentication() { ... }
  ```

### Sensitive Data Handling

**Golden Rule**: Sensitive user data (meal details, health metrics, scores) must NEVER be:
- Logged to console in production builds
- Sent to analytics without explicit opt-in
- Stored in plaintext on disk
- Cached without encryption
- Transmitted over unencrypted channels

**Sensitive data includes**:
- Meal descriptions and content
- Health scores and analytics
- Sleep data
- User identity information

**Implementation**:
```swift
// ❌ NEVER log sensitive data
os_log("User meal: \(meal.description)", log: OSLog.default, type: .debug)

// ✅ Log only non-sensitive metadata
os_log("Analyzed meal ID %{public}@", log: OSLog.default, type: .debug, mealId)
```

### Encryption at Rest

- **User data stored on disk must be encrypted using Keychain (for secrets) or Data Protection (for files)**
- **Never store API keys or tokens in UserDefaults without encryption**
- **Firestore Security Rules must enforce user-level data isolation**

### Network Security

- **All API calls must use HTTPS only (enforce via URLSessionConfiguration)**
- **Certificate pinning should be considered for Firebase endpoints**
- **Never send auth tokens in URL parameters; use Authorization headers only**
- **Validate SSL certificates; never disable certificate validation**

### Firestore Security Rules Template

```javascript
match /meals/{userId}/daily/{mealId} {
  // User can only read/write their own data
  allow read, write: if request.auth.uid == userId;
}

match /insights/{userId}/daily/{date} {
  // User can only read their own insights
  allow read: if request.auth.uid == userId;
  // Only the backend can write (Cloud Functions authenticated)
  allow write: if false;
}
```

### Input Validation & Sanitization

- **All user input must be validated BEFORE processing**
- **Validate meal description length, format, and content**
- **Sanitize inputs before passing to AI services**
- **Write validation tests**:
  ```swift
  func test_emptyMealDescriptionIsRejected() { ... }
  func test_mealDescriptionWithSQLInjectionIsSanitized() { ... }
  func test_excessivelyLongDescriptionIsRejected() { ... }
  ```

### Error Handling & Information Disclosure

- **Never expose internal error details to users**
- **Log detailed errors server-side only (Firebase Crashlytics, Cloud Logging)**
- **Show generic user-friendly error messages in the UI**

Example:
```swift
// ❌ BAD: Exposes internal error
catch {
    print("Firebase error: \(error.localizedDescription)")
    showAlert(error.localizedDescription)
}

// ✅ GOOD: Generic message to user, detailed log server-side
catch {
    logError(error) // Firebase Crashlytics
    showAlert("We couldn't process that meal. Please try again.")
}
```

### Dependency Security

- **Use CocoaPods/SPM with pinned versions; never use floating versions**
- **Regularly audit dependencies for known vulnerabilities**
- **Keep Firebase SDK and all dependencies up to date**
- **Review third-party library code before integrating**

### Test Security Guards

Every security-sensitive feature must have dedicated tests:
- `SecurityAndAuthTests.swift` — authentication, authorization, data isolation
- `EncryptionTests.swift` — verify sensitive data encryption
- `InputValidationTests.swift` — validate all user input handling
- `NetworkSecurityTests.swift` — HTTPS enforcement, cert validation

Example security test:
```swift
@MainActor
final class SecurityAndAuthTests: XCTestCase {
    func test_unauthenticatedUserCannotAnalyzeMeal() {
        let mockAuthService = MockAuthService(isAuthenticated: false)
        let viewModel = MainViewModel(authService: mockAuthService, ...)
        
        // Should not proceed with analysis
        XCTAssertThrowsError(try viewModel.performDeepAnalysis(...))
    }
    
    func test_userCanOnlyAccessOwnMeals() {
        let user1ViewModel = createViewModel(userId: "user1", ...)
        let user2ViewModel = createViewModel(userId: "user2", ...)
        
        // user2's meals should not be accessible to user1
        XCTAssertEqual(user1ViewModel.meals.filter { $0.userId == "user2" }.count, 0)
    }
}
```

## Critical regression tests — must stay green

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
- **TDD Violation: "I'll test it after"** — You won't. Tests written after are always incomplete. Write tests FIRST.
- **Hardcoded constants in multiple files** — All reusable constants must live in `Constants.swift` or domain-specific files (`ScoringThresholds.swift`, etc.). Search before hardcoding.
- **Test passing on first run** — If your test passes without any production code changes, the test is too loose. Tighten it until it fails.
- **Over-mocking** — Mock at boundaries (Firebase, filesystem, network). Never mock the code under test. Mock internal dependencies in integration tests.
- **Skipping security tests** — Assume every user-facing feature needs an auth guard, input validation, and encryption. Test them.

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

---

## ENFORCEMENT CHECKLIST — For Code Review

Every PR must satisfy all of these before merge:

### ✅ TDD Discipline
- [ ] Tests written BEFORE production code (Red-Green-Refactor cycle followed)
- [ ] At least 1 failing test for every feature
- [ ] All tests pass
- [ ] No test passing on first run without code changes
- [ ] Security-sensitive features have dedicated security tests

### ✅ MVVM Architecture
- [ ] Views display data via `@Published` properties only
- [ ] No direct service calls from Views
- [ ] ViewModels coordinate all business logic
- [ ] Models are pure data structures (Codable, Equatable, etc.)

### ✅ SOLID Principles
- [ ] Each class has one reason to change (SRP)
- [ ] Dependencies injected via initializer or property (DIP)
- [ ] Protocols used for abstractions, not concrete types (ISP, LSP)
- [ ] No monolithic mega-classes (OCP)

### ✅ DRY & SSOT
- [ ] No hardcoded magic values (all constants centralized)
- [ ] `ScoringThresholds.swift` is sole source of threshold values
- [ ] `Constants.swift` contains all shared constants
- [ ] No duplicate code; extracted into helpers or services
- [ ] Search results for constant values (e.g., `0.65`) appear only in constants files

### ✅ Cybersecurity
- [ ] All user data access guarded by authentication checks
- [ ] No sensitive data logged to console in production
- [ ] Firestore Security Rules enforce user-level data isolation
- [ ] User input validated and sanitized before processing
- [ ] HTTPS enforced; SSL certificate validation enabled
- [ ] API keys and tokens NOT stored in UserDefaults
- [ ] Errors shown to user are generic; detailed errors logged server-side

### ✅ Code Quality
- [ ] Zero build warnings (test with xcodebuild command above)
- [ ] No `var` where `let` suffices
- [ ] No unused imports
- [ ] Meaningful variable/function names
- [ ] No commented-out code
- [ ] Tests are isolated and can run in any order

### ✅ Test Coverage
- [ ] Unit tests for all business logic
- [ ] Integration tests for cross-service flows
- [ ] Security tests for auth, validation, data isolation
- [ ] Mock tests use shared mocks from `Mocks.swift`
- [ ] All regression tests still pass

---

## Quick Reference

**Before writing ANY feature code**: Ask yourself:
1. "What test should I write first?" → Write Red test
2. "What's the minimum code to pass?" → Write Green code
3. "Can I refactor without breaking tests?" → Refactor
4. "Does this violate SOLID?" → Redesign if yes
5. "Are there duplicate constants?" → Extract to SSOT
6. "Is sensitive data protected?" → Add security test

**If you skip any of these steps, you are not following this guide.**

