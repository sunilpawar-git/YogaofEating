# Phase 7 Tech Debt Report — SettingsUITests Split

**Date**: 2026-05-23  
**Phase**: 7 of N  
**Status**: ✅ Complete — 20/20 UI tests GREEN, zero regressions

---

## Problem Addressed

`SettingsUITests.swift` accumulated 529 lines across Phases 1–6, exceeding the project's 300-line file limit (warn at 250, error at 300). Phase 7 is a pure structural refactoring — no new behaviour, no new production code. The 20 existing passing tests serve as the safety net.

---

## Changes Made

### Files Created

| File | Lines | Tests | Responsibility |
|---|---|---|---|
| [Yoga of EatingUITests/SettingsCloudBackupUITests.swift](../Yoga%20of%20EatingUITests/SettingsCloudBackupUITests.swift) | 190 | 9 | Sync button state machine + Cloud Backup navigation |
| [Yoga of EatingUITests/SettingsPreferencesUITests.swift](../Yoga%20of%20EatingUITests/SettingsPreferencesUITests.swift) | 116 | 3 | Morning briefing time picker + `openPreferences()` helper |

### Files Modified

| File | Before | After | Tests |
|---|---|---|---|
| [Yoga of EatingUITests/SettingsUITests.swift](../Yoga%20of%20EatingUITests/SettingsUITests.swift) | 529 lines | 136 lines | 8 (core settings + Phase 6) |

### No project.pbxproj edit required

The UITests target uses `PBXFileSystemSynchronizedRootGroup` (Xcode 15+ folder sync). New `.swift` files in `Yoga of EatingUITests/` are auto-included in the target without manual registration.

---

## Test Distribution (Post-Split)

| Class | File | Tests |
|---|---|---|
| `SettingsUITests` | `SettingsUITests.swift` | 8 |
| `SettingsCloudBackupUITests` | `SettingsCloudBackupUITests.swift` | 9 |
| `SettingsPreferencesUITests` | `SettingsPreferencesUITests.swift` | 3 |
| **Total** | | **20** |

---

## Additional Fix

The `openPreferences()` helper in the old `SettingsUITests.swift` Strategy 3 fallback used `self.app.tables.firstMatch.swipeUp()`. On iOS 16+, SwiftUI `Form` renders as `UICollectionView`, not `UITableView`, so `tables.firstMatch` returns nothing. The fix (`self.app.swipeUp()`) was applied in the moved helper inside `SettingsPreferencesUITests.swift`.

---

## Enforcement Checklist

- ✅ All 20 tests pass across 3 files
- ✅ No tests deleted — only moved between classes
- ✅ No production code changed
- ✅ All 3 files under 250-line warning threshold
- ✅ `PBXFileSystemSynchronizedRootGroup` handles auto-inclusion — no project file edits needed
- ✅ Each new class has its own `setUp`/`tearDown` with `--uitesting` launch arg
- ✅ Zero build warnings
