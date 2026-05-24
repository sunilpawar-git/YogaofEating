# Tech Debt Remediation Plan — Phases 8–13
## Scope: Settings Sprint 1–7 Accumulated Debt

Generated after comprehensive audit of all Settings-scope files.
All previous phases (1–7) must stay GREEN throughout this work.

---

## Audit Findings Summary

| # | Category | Severity | File(s) | Description |
|---|---|---|---|---|
| 1 | SSOT — Strings | 🔴 CRITICAL | `SettingsViewModel+Sync.swift` | 8 hardcoded accessibility label/hint strings |
| 2 | SSOT — Strings | 🔴 CRITICAL | `SettingsViewModel+Restore.swift` | 8 hardcoded accessibility label/hint strings |
| 3 | SSOT — Strings | 🔴 CRITICAL | `PreferencesSettingsView.swift` | ALL ~12 user-facing strings hardcoded |
| 4 | SSOT — Strings | 🔴 CRITICAL | `UserProfileSettingsView.swift` | ALL ~18 user-facing strings hardcoded |
| 5 | SSOT — Strings | 🟠 HIGH | `SettingsView.swift` lines 39, 50 | `Button("Cancel", role: .cancel)` × 2; `Strings.Common.cancel` exists unused |
| 6 | FontTheme | 🟠 HIGH | `PreferencesSettingsView.swift` lines 56, 88 | `.font(.caption)` → `FontTheme.caption` |
| 7 | FontTheme | 🟠 HIGH | `UserProfileSettingsView.swift` lines 37, 117, 136 | `.font(.caption)` → `FontTheme.caption` |
| 8 | FontTheme | 🟠 HIGH | `SettingsView.swift` lines 82, 84 | `.font(.headline)` / `.font(.subheadline)` — no FontTheme tokens exist |
| 9 | AppTheme Colors | 🟡 MEDIUM | `SettingsCloudSection.swift` | `.foregroundColor(.blue/.green/.red/.primary)` — hardcoded color literals |
| 10 | AppTheme Spacing | 🟡 MEDIUM | `SettingsCloudSection.swift` | `.cornerRadius(8)`, `.padding(.vertical, 8)`, `.padding(.horizontal, 16)`, `.scaleEffect(0.8)` — magic numbers |
| 11 | AppTheme Colors | 🟡 MEDIUM | `UserProfileSettingsView.swift` lines 47, 69, 89, 102 | `.foregroundColor(.secondary)` × 4 → `AppTheme.textSecondary` |
| 12 | AppTheme Colors | 🟡 MEDIUM | `SettingsView.swift` line 85 | `.foregroundColor(.secondary)` → `AppTheme.textSecondary` |
| 13 | DIP Violation | 🟡 MEDIUM | `SettingsViewModel.swift` | `NotificationManager.shared` × 5 — not injected via protocol |
| 14 | DIP Violation | 🟡 MEDIUM | `SettingsViewModel+Sync.swift` | `HealthKitService.shared` × 5 — not injected via protocol |
| 15 | Test Quality | 🟢 LOW | `SettingsUITests.swift` lines 78, 99 | `XCTAssertTrue(true, ...)` — trivially passes, asserts nothing |
| 16 | Test Quality | 🟢 LOW | `SettingsCloudBackupUITests.swift` line 39 | `signInButton.exists \|\| true` — tautology, always passes |
| 17 | File Length Warn | 🟢 LOW | `SettingsViewModelTests.swift` | 262 lines — over 250 warn threshold |

### Pre-existing (out of scope, tracked separately)
- `WellbeingCoachIntegrationTests.test_integration_noMeals_contractIsNil` — predates all Sprint 1–7 work; contract builder returns non-nil defaults for zero meals; test expects nil.

---

## Phase 8 — Accessibility Strings SSOT

**Priority: CRITICAL**
**Risk: HIGH** — UI tests reference accessibility labels as string literals (e.g., `app.buttons["Sync with Cloud button"]`). Changing these strings without updating UI tests will break the test suite.

### Problem

`SettingsViewModel+Sync.swift` and `SettingsViewModel+Restore.swift` each contain
8 hardcoded accessibility strings inside computed properties:

```swift
// SettingsViewModel+Sync.swift (lines 178–192) — hardcoded
var syncAccessibilityLabel: String {
    switch self.syncStatus {
    case .idle:    "Sync with Cloud button"          // ← must move to Strings.swift
    case .syncing: "Syncing data to cloud"           // ← must move to Strings.swift
    case .success: "Sync completed successfully"     // ← must move to Strings.swift
    case let .error(message): "Sync failed: \(message)"  // ← must move to Strings.swift
    }
}
var syncAccessibilityHint: String { ... /* 4 more */ }

// SettingsViewModel+Restore.swift (lines 88–102) — 8 more hardcoded strings
var restoreAccessibilityLabel: String { ... }
var restoreAccessibilityHint: String { ... }
```

### TDD Sequence

1. **RED**: Add `SettingsAccessibilityStringsTests.swift` — write tests that verify `Strings.Settings.Sync.*` and `Strings.Settings.Restore.*` constants exist and have the correct values. Tests fail: constants don't exist yet.
2. **GREEN**: Add constants to `Strings.swift` under `Strings.Settings.Sync` and `Strings.Settings.Restore`.
3. **REFACTOR**: Update `SettingsViewModel+Sync.swift` and `SettingsViewModel+Restore.swift` to use the new constants. Update **all UI test files** that reference old string literals.

### Constants to Add to `Strings.swift` (under `enum Settings`)

```swift
enum Sync {
    // Labels
    static let accessibilityLabelIdle     = "Sync with Cloud button"
    static let accessibilityLabelSyncing  = "Syncing data to cloud"
    static let accessibilityLabelSuccess  = "Sync completed successfully"
    static let accessibilityLabelErrorFmt = "Sync failed: %@"   // use String(format:, message)

    // Hints
    static let accessibilityHintIdle      = "Double tap to sync your data with cloud storage"
    static let accessibilityHintSyncing   = "Sync in progress, please wait"
    static let accessibilityHintSuccess   = "Sync completed"
    static let accessibilityHintError     = "Double tap to retry sync"
}

enum Restore {
    // Labels
    static let accessibilityLabelIdle     = "Restore from Cloud button"
    static let accessibilityLabelRestoring = "Restoring data from cloud"
    static let accessibilityLabelSuccess  = "Restore completed successfully"
    static let accessibilityLabelErrorFmt = "Restore failed: %@"

    // Hints
    static let accessibilityHintIdle      = "Double tap to restore your data from cloud backup"
    static let accessibilityHintRestoring = "Restore in progress, please wait"
    static let accessibilityHintSuccess   = "Restore completed"
    static let accessibilityHintError     = "Double tap to retry restore"
}
```

> **Note**: `Strings` enum is NOT available in the UI test target. UI tests must continue to use the string literal values directly. Any accessibility label values used as XCUITest element queries **must not change** (or UI test queries must be updated in the same commit).

### Files Changed
- `Logic/Strings.swift` — add constants
- `ViewModels/SettingsViewModel+Sync.swift` — use constants
- `ViewModels/SettingsViewModel+Restore.swift` — use constants
- `Yoga of EatingTests/SettingsAccessibilityStringsTests.swift` — new (RED first)
- `Yoga of EatingUITests/SettingsCloudBackupUITests.swift` — update string literals if any accessibility label values change

---

## Phase 9 — PreferencesSettingsView SSOT

**Priority: CRITICAL**
**Risk: LOW** — isolated view, no UI test currently asserts on these specific strings

### Problem

`Views/PreferencesSettingsView.swift` (91 lines) has ~12 hardcoded user-facing strings and 2 hardcoded font calls.

Hardcoded strings (confirmed):
- `.navigationTitle("Preferences")`
- `Section("Appearance")`
- `Text("System").tag(0)`, `Text("Light").tag(1)`, `Text("Dark").tag(2)`
- `.accessibilityLabel("Theme")`
- `Toggle("Morning Nudge", ...)`
- `Toggle("Meal Reminders", ...)`
- `Text("Notifications")`
- `Text("Send reminders before meals. ...")` (notification footer)
- `Section("Sensory Feedback")`
- `Toggle("Haptic Nudges", ...)`
- `Toggle("Sound Effects", ...)`
- `Toggle("Sync Body Metrics (Apple Health)", ...)`
- `Text("Integrations")`
- `Text("When enabled, your height, weight, age, and gender will be synced from Apple Health.")`

Hardcoded fonts:
- Line 56: `.font(.caption)` — should be `FontTheme.caption`
- Line 88: `.font(.caption)` — should be `FontTheme.caption`

### TDD Sequence

1. **RED**: Add `SettingsPreferencesStringsTests.swift` — verify `Strings.Settings.Preferences.*` constants exist with correct values. Tests fail.
2. **GREEN**: Add `Strings.Settings.Preferences` enum to `Strings.swift`. Update `PreferencesSettingsView.swift` to use them + `FontTheme.caption`.
3. **REFACTOR**: Ensure view remains under 91 lines; no behavioral change.

### Constants to Add (under `enum Settings`)

```swift
enum Preferences {
    static let navigationTitle         = "Preferences"
    static let appearanceSection       = "Appearance"
    static let themeSystem             = "System"
    static let themeLight              = "Light"
    static let themeDark               = "Dark"
    static let themeAccessibilityLabel = "Theme"
    static let morningNudgeToggle      = "Morning Nudge"
    static let mealRemindersToggle     = "Meal Reminders"
    static let notificationsSection    = "Notifications"
    static let notificationsFooter     = "Send reminders before meals. Requires notification permission."
    static let sensoryFeedbackSection  = "Sensory Feedback"
    static let hapticNudgesToggle      = "Haptic Nudges"
    static let soundEffectsToggle      = "Sound Effects"
    static let syncAppleHealthToggle   = "Sync Body Metrics (Apple Health)"
    static let integrationsSection     = "Integrations"
    static let appleHealthFooter       = "When enabled, your height, weight, age, and gender will be synced from Apple Health."
}
```

### Files Changed
- `Logic/Strings.swift`
- `Views/PreferencesSettingsView.swift`
- `Yoga of EatingTests/SettingsPreferencesStringsTests.swift` — new (RED first)

---

## Phase 10 — UserProfileSettingsView SSOT

**Priority: CRITICAL**
**Risk: LOW** — isolated view, no UI test currently asserts on all these specific strings

### Problem

`Views/UserProfileSettingsView.swift` (139 lines) has ~18 hardcoded strings, 3 hardcoded `.font(.caption)` calls, and 4 hardcoded `.foregroundColor(.secondary)` calls.

Hardcoded strings:
- `.navigationTitle("Profile & Health")`
- `Text("Personal Details")` (section header)
- `Text("This information is used to calculate your health insights and personalize feedback.")`
- `Text("Name")`
- `Text("Unspecified").tag(0)`, `Text("Male").tag(1)`, `Text("Female").tag(2)`, `Text("Other").tag(3)`
- `Text("Age")`
- `Text("Metric").tag(0)`, `Text("Imperial").tag(1)`
- `Section("Health Insights")`
- `Text("Complete your personal details above to see health insights")`
- `Toggle("Show Health Insights", ...)`
- `Text("Privacy")`
- `Text("Your health data is calculated on-device and never leaves your phone.")`

Hardcoded fonts:
- Lines 37, 117, 136: `.font(.caption)` → `FontTheme.caption`

Hardcoded colors:
- Lines 47, 69, 89, 102: `.foregroundColor(.secondary)` → `AppTheme.textSecondary`

### TDD Sequence

1. **RED**: Add `SettingsUserProfileStringsTests.swift` — verify `Strings.Settings.UserProfile.*` constants exist. Tests fail.
2. **GREEN**: Add `Strings.Settings.UserProfile` enum to `Strings.swift`. Update `UserProfileSettingsView.swift`.
3. **REFACTOR**: Ensure view remains under 139 lines.

### Constants to Add (under `enum Settings`)

```swift
enum UserProfile {
    static let navigationTitle          = "Profile & Health"
    static let personalDetailsSection   = "Personal Details"
    static let personalDetailsFooter    = "This information is used to calculate your health insights and personalize feedback."
    static let nameLabel                = "Name"
    static let genderUnspecified        = "Unspecified"
    static let genderMale               = "Male"
    static let genderFemale             = "Female"
    static let genderOther              = "Other"
    static let ageLabel                 = "Age"
    static let unitMetric               = "Metric"
    static let unitImperial             = "Imperial"
    static let healthInsightsSection    = "Health Insights"
    static let healthInsightsEmptyState = "Complete your personal details above to see health insights"
    static let showHealthInsightsToggle = "Show Health Insights"
    static let privacySection           = "Privacy"
    static let privacyFooter            = "Your health data is calculated on-device and never leaves your phone."
}
```

### Files Changed
- `Logic/Strings.swift`
- `Views/UserProfileSettingsView.swift`
- `Yoga of EatingTests/SettingsUserProfileStringsTests.swift` — new (RED first)

---

## Phase 11 — Theme Compliance: SettingsView + SettingsCloudSection

**Priority: HIGH**
**Risk: LOW-MEDIUM** — visual only; no behavioral change

### Problem A: `SettingsView.swift` — Cancel string + FontTheme + AppTheme

1. `Button("Cancel", role: .cancel) {}` × 2 (lines 39, 50) — `Strings.Common.cancel` already exists but unused
2. `.font(.headline)` (line 82) — no `FontTheme.headline` token exists; nearest is `sectionHeader` (18pt semibold rounded)
3. `.font(.subheadline)` (line 84) — no `FontTheme.subheadline` token; nearest is `body` (16pt regular rounded)
4. `.foregroundColor(.secondary)` (line 85) — `AppTheme.textSecondary` exists

**Resolution for fonts**: Add two new tokens to `FontTheme.swift`:
```swift
/// 17pt Semibold Rounded — for section-level user display names
static let displayName = Font.system(size: 17, weight: .semibold, design: .rounded)

/// 15pt Regular Rounded — for secondary user info (email, subtitle)
static let displaySubtitle = Font.system(size: 15, weight: .regular, design: .rounded)
```
These names are semantic (describe use, not size), following the existing naming pattern.

### Problem B: `SettingsCloudSection.swift` — 9 hardcoded theme values

| Current | → Replace With |
|---|---|
| `.foregroundColor(.blue)` | `AppTheme.CloudSync.syncButtonColor` (new token) |
| `.foregroundColor(.green)` | `AppTheme.CloudSync.successColor` (new token) |
| `.foregroundColor(.red)` | `AppTheme.CloudSync.errorColor` (new token) |
| `.foregroundColor(.primary)` | `AppTheme.textPrimary` (exists) |
| `.cornerRadius(8)` | `AppTheme.CornerRadius.small` (exists: 8pt) |
| `.padding(.vertical, 8)` | `AppTheme.Spacing.small` (exists: 8pt) |
| `.padding(.horizontal, 16)` | `AppTheme.Spacing.medium` (exists: 16pt) |
| `.padding(.top, 8)` | `AppTheme.Spacing.small` |
| `.scaleEffect(0.8)` | `AppTheme.CloudSync.progressViewScale` (new token: 0.8) |

New tokens to add to `ThemeComponents.swift` under `AppTheme.CloudSync`:
```swift
// In ThemeComponents.swift — extend existing AppTheme.CloudSync
static let syncButtonColor: Color = .blue
static let successColor: Color    = .green
static let errorColor: Color      = .red
static let progressViewScale: CGFloat = 0.8
```

### TDD Sequence

1. **RED**: Add `SettingsThemeComplianceTests.swift` — verify `FontTheme.displayName` and `FontTheme.displaySubtitle` exist; verify `AppTheme.CloudSync.syncButtonColor`, `.successColor`, `.errorColor`, `.progressViewScale` exist. Tests fail.
2. **GREEN**: Add tokens to `FontTheme.swift` and `ThemeComponents.swift`. Update `SettingsView.swift` and `SettingsCloudSection.swift`.
3. **REFACTOR**: No structural change expected.

### Files Changed
- `Logic/FontTheme.swift` — add `displayName`, `displaySubtitle`
- `Logic/ThemeComponents.swift` — add `syncButtonColor`, `successColor`, `errorColor`, `progressViewScale` to `AppTheme.CloudSync`
- `Views/SettingsView.swift` — Cancel strings, font tokens, color token
- `Views/SettingsCloudSection.swift` — 9 theme replacements
- `Yoga of EatingTests/SettingsThemeComplianceTests.swift` — new (RED first)

---

## Phase 12 — DIP: Inject NotificationManager + HealthKitService

**Priority: MEDIUM**
**Risk: MEDIUM-HIGH** — requires SettingsViewModel initializer change; affects all existing tests

### Problem

`SettingsViewModel.swift` calls `NotificationManager.shared` 5 times directly:
```swift
NotificationManager.shared.scheduleMorningNudge(at: self.morningBriefingTime)
NotificationManager.shared.scheduleDefaultMealReminders()
NotificationManager.shared.cancelMealReminders()
NotificationManager.shared.cancelMorningNudge()
```

`SettingsViewModel+Sync.swift` calls `HealthKitService.shared` 5 times directly:
```swift
HealthKitService.shared.requestAuthorization()
HealthKitService.shared.fetchLatestWeight(unit:)
HealthKitService.shared.fetchLatestHeight(unit:)
HealthKitService.shared.fetchAge()
HealthKitService.shared.fetchGender()
```

These are direct singleton dependencies — impossible to unit test notification scheduling or HealthKit sync without the real system.

### Design

```swift
// New protocol (or use existing ActivityDataProvider if it covers these methods)
protocol NotificationScheduling {
    func scheduleMorningNudge(at time: Date)
    func cancelMorningNudge()
    func scheduleDefaultMealReminders()
    func cancelMealReminders()
}
extension NotificationManager: NotificationScheduling {}

// SettingsViewModel — inject via init
init(
    userDefaults: UserDefaults = .standard,
    notificationScheduler: NotificationScheduling = NotificationManager.shared,
    // ... existing params
)
```

For HealthKit:
- `HealthKitService` already conforms to `ActivityDataProvider` protocol — check if health profile methods can be covered by a new `HealthProfileDataProvider` protocol or extend `ActivityDataProvider`.
- If `HealthProfileService.swift` / `HealthProfileServiceProtocol` already covers this, inject that instead (see CLAUDE.md architecture).

### TDD Sequence

1. **RED**: Add `SettingsNotificationSchedulingTests.swift` — test that toggling `isMorningNudgeEnabled` calls the injected scheduler, not the real `NotificationManager`. Tests fail (DIP not implemented).
2. **GREEN**: Add `NotificationScheduling` protocol; inject into `SettingsViewModel`.
3. **RED**: Add `SettingsHealthKitSyncTests.swift` — test `syncFromHealthKit()` calls injected service, not `HealthKitService.shared`. Tests fail.
4. **GREEN**: Add `HealthProfileDataProvider` or reuse existing protocol; inject into `SettingsViewModel`.
5. **REFACTOR**: Ensure all existing tests still pass (they use `MockPersistenceService` but no mock for notifications/HealthKit).

> **Impact**: The `SettingsViewModel` default init in production code stays clean — defaults are still the real singletons. But unit tests can now inject mocks. Existing test files will NOT break because `SettingsViewModelTests` doesn't currently test notification side effects.

### Files Changed
- `Logic/NotificationScheduling.swift` — new protocol (or add to `NotificationManager.swift`)
- `ViewModels/SettingsViewModel.swift` — inject `notificationScheduler`
- `ViewModels/SettingsViewModel+Sync.swift` — inject `healthKitProvider`
- `Yoga of EatingTests/Mocks.swift` — add `MockNotificationScheduler`, `MockHealthProfileDataProvider`
- `Yoga of EatingTests/SettingsNotificationSchedulingTests.swift` — new (RED first)
- `Yoga of EatingTests/SettingsHealthKitSyncTests.swift` — new (RED first)

---

## Phase 13 — Test Quality: Eliminate Trivial Assertions

**Priority: LOW**
**Risk: LOW** — test-only change; no production code touched

### Problem

Three UI test assertions guarantee nothing:

**`SettingsUITests.swift` line 78:**
```swift
XCTAssertTrue(true, "Personal details are accessible in settings")
// ← always passes; does not verify the element exists
```
Fix: `XCTAssertTrue(app.navigationBars["Profile & Health"].waitForExistence(timeout: 3))`

**`SettingsUITests.swift` line 99:**
```swift
XCTAssertTrue(true, "Settings opened successfully")
// ← always passes
```
Fix: `XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))`

**`SettingsCloudBackupUITests.swift` line 39:**
```swift
XCTAssertTrue(signInButton.exists || true, ...)
// ← tautology; || true means always passes
```
Fix: remove `|| true`; choose one of:
- Assert the button exists (if sign-out state is guaranteed by `--uitesting`)
- Assert the cloud backup screen loaded instead (more stable)

### File Length Warning

`SettingsViewModelTests.swift` is 262 lines (over 250 warn). Do NOT split preemptively; only split when the next test addition would breach 300 lines. Note in code comments which test group to extract first (health insights tests, if `SettingsHealthInsightsTests` is a sibling file, should absorb overflow).

### TDD Sequence

1. **RED**: The existing trivial assertions are already "passing" but non-meaningful. Replace them one at a time with real assertions. Verify new assertion fails with the `--uitesting` flag active on a fresh simulator (expected: element is navigated to; assertion should pass).
2. **GREEN**: Confirm correct assertion text. Run full UI test suite.
3. **REFACTOR**: None needed.

### Files Changed
- `Yoga of EatingUITests/SettingsUITests.swift` — replace 2 trivial assertions
- `Yoga of EatingUITests/SettingsCloudBackupUITests.swift` — fix tautology on line 39

---

## Execution Order & Dependencies

```
Phase 8  ──────────────────────────────┐
Phase 9  ─────────────────────────┐   │
Phase 10 ──────────────────────┐  │   │  (all independent of each other)
Phase 11 ───────────────────┐  │  │   │
Phase 12 ──────────────────┐│  │  │   │
Phase 13 ─────────────────┐││  │  │   │
                           ↓↓↓  ↓  ↓   ↓
                    All phases converge → Build + Full test suite GREEN
```

No phase depends on another. They can be done in priority order or in any sequence. Recommended order: 8 → 9 → 10 → 11 → 13 → 12 (defer DIP until last as it has highest risk).

---

## Definition of Done (All Phases)

- [ ] All strings → `Strings.swift` (zero hardcoded user-facing text in Views or ViewModels)
- [ ] All fonts → `FontTheme.*` (zero `.font(.caption)`, `.font(.headline)`, etc. in Settings files)
- [ ] All colors/spacing → `AppTheme.*` (zero `.foregroundColor(.red/.blue/.green/.secondary)`, no magic number padding)
- [ ] Zero `XCTAssertTrue(true)` or `|| true` tautologies in Settings test files
- [ ] All new `Strings.*` constants covered by unit tests
- [ ] All new `FontTheme.*` and `AppTheme.*` tokens covered by unit tests
- [ ] Build succeeds with zero warnings on iPhone 17 simulator
- [ ] All 20 UI tests GREEN
- [ ] All unit tests GREEN (excluding pre-existing `WellbeingCoachIntegrationTests` failure)
- [ ] No file exceeds 300 lines

---

## Files NOT Requiring Changes

The following Settings files are already fully compliant:

| File | Status |
|---|---|
| `Views/SettingsView.swift` | Compliant except Cancel strings + 2 font calls + 1 color (Phase 11) |
| `Views/SettingsCloudBackupView.swift` | ✅ Fully compliant |
| `ViewModels/SettingsViewModel.swift` | Compliant except NotificationManager.shared (Phase 12) |
| `Logic/StorageKeys.swift` | ✅ No orphaned keys found |
| All Phase 7 test files | ✅ Already split and within limits |
