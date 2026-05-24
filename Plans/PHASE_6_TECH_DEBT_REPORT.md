# Phase 6 Tech Debt Report — SettingsView 5-Section Restructure

**Date**: 2026-05-23  
**Phase**: 6 of N  
**Status**: ✅ Complete — all tests GREEN, zero build warnings

---

## What Was Done

Phase 6 restructured `SettingsView` from a 4-section layout into a principled 5-section layout, eliminated every remaining hardcoded user-facing string, added Sign Out confirmation flow, and wired new accessibility identifiers required by UI tests.

---

## Tech Debt Eliminated

### 1. Hardcoded Strings Removed from SettingsView.swift

Every string below previously appeared as a string literal in the view. All now resolve through `Strings.Settings.*`.

| Removed Literal | `Strings.Settings` Key Added |
|---|---|
| `"Settings"` (navigation title) | `navigationTitle` |
| `"Login with Google"` | `loginWithGoogleTitle` |
| `"Done"` (toolbar button) | `doneButton` (pre-existing) |
| All alert titles / messages | Pre-existing SSOT keys reused |

### 2. Section Restructure — Old → New

| Old Section | New Section(s) | Notes |
|---|---|---|
| `userDataSection` | `accountSection` | Renamed; Google sign-in button moved here |
| `userDataSection` (heatmap row) | `historySection` | Heatmap extracted to its own section |
| `dataManagementSection` | `dangerZoneSection` | Renamed to match SSOT header string `Strings.Settings.dangerZoneHeader` |
| _(inline in signedInUserView)_ | `dangerZoneSection` | Sign Out button moved here; now shows a confirmation alert before acting |
| _(unchanged)_ | `navigationLinksSection` | Profile, Preferences; **new**: Manage Health Access |
| _(unchanged)_ | `supportSection` | No structural change; SSOT strings already in place |

### 3. Sign Out — Safety Improvement

- Sign Out button was previously inline inside `signedInUserView`, with no confirmation step.
- Phase 6 moves it to `dangerZoneSection` alongside Clear All Data.
- It now fires a `showingSignOutConfirmation` alert (`Strings.Settings.signOutAlertTitle` + `Strings.Settings.signOutConfirmationMessage`) before calling `viewModel.signOut()`.
- Both destructive actions (`signOut`, `deleteAllData`) are now co-located under the "Danger Zone" header — matching the mental model a user expects.

### 4. New Accessibility Identifiers

| Identifier | Element | Purpose |
|---|---|---|
| `manage-health-access-link` | `Button` in navigationLinksSection | Opens `UIApplication.openSettingsURLString`; tested by new UI test |
| `clear-all-data-button` | `Button(role: .destructive)` in dangerZoneSection | Tested by new UI test (requires `app.swipeUp()` to expose) |
| `sign-out-button` | `Button(role: .destructive)` in dangerZoneSection | Available for future UI tests |

---

## New Tests Added

### Unit Tests — `SettingsStringsTests.swift` (new file, 21 tests)

Tests that every `Strings.Settings.*` constant exists and is non-empty (compile + runtime SSOT guard). Two were RED at the start of Phase 6:
- `test_strings_navigationTitle_exists` — RED → GREEN (added `navigationTitle`)
- `test_strings_loginWithGoogleTitle_exists` — RED → GREEN (added `loginWithGoogleTitle`)

### UI Tests — 2 added to `SettingsUITests.swift`

| Test | Was RED | Notes |
|---|---|---|
| `test_navigation_manageHealthAccess_link_exists` | Yes | Passes without scroll; element visible in viewport |
| `test_dangerZone_clearAllData_hasAccessibilityId` | Yes | Requires `app.swipeUp()` — Danger Zone is below the fold; SwiftUI Form on iOS 16+ is a `UICollectionView`, not `UITableView` |

---

## File Size Report

| File | Lines | Status |
|---|---|---|
| `Views/SettingsView.swift` | 242 | ✅ Under 250 warn / 300 error |
| `Yoga of EatingTests/SettingsStringsTests.swift` | ~130 | ✅ |
| `Yoga of EatingUITests/SettingsUITests.swift` | 529 | ⚠️ Exceeds 300-line limit (see Known Issues) |

---

## Test Counts — Cumulative Through Phase 6

| Suite | Tests | Status |
|---|---|---|
| `SettingsStringsTests` | 21 | ✅ All pass |
| `SettingsViewModelTests` | 17 | ✅ All pass |
| `SettingsCloudSyncTests` | 11 | ✅ All pass |
| `ManualRestoreTests` | 10 | ✅ All pass |
| `SettingsViewSyncTests` | 6 | ✅ All pass |
| `SettingsUITests` | 20 | ✅ All pass |
| **Total** | **85** | ✅ |

---

## Known Issues / Future Work

### ⚠️ `SettingsUITests.swift` Exceeds File Length Limit

- **Current**: 529 lines
- **Limit**: warn at 250, error at 300
- **Cause**: All Settings-related UI tests accumulated in a single file across Phases 1–6
- **Recommended fix (Phase 7)**: Split into:
  - `SettingsUITests.swift` — core Settings sheet tests (~150 lines)
  - `SettingsCloudBackupUITests.swift` — cloud backup / sync UI tests (~150 lines)
  - `SettingsPreferencesUITests.swift` — preferences, toggles, time picker (~150 lines)

### ⚠️ Pre-Existing Failure (Not Phase 6)

`WellbeingCoachIntegrationTests.test_integration_noMeals_contractIsNil` fails because `WellbeingBreakdownSheetContract` returns non-nil defaults for zero meals. This pre-dates all Settings phases and is unrelated to this work.

---

## Enforcement Checklist

- ✅ Tests written before production code (TDD Red-Green-Refactor)
- ✅ All hardcoded user-facing strings eliminated from `SettingsView.swift`
- ✅ All strings resolve through `Strings.Settings.*` (SSOT)
- ✅ Destructive actions use `Button(role: .destructive)`
- ✅ Sign Out now requires confirmation before executing
- ✅ New accessibility identifiers documented and tested
- ✅ File length: `SettingsView.swift` = 242 lines (under limit)
- ✅ All 85 Settings tests pass
- ✅ Zero build warnings
- ✅ `--uitesting` sign-out isolation maintained
