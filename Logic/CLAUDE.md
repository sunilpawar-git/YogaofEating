# Logic/ — Centralized Resources & Theming

All constants, tokens, and strings live here. Never hardcode in Views or ViewModels.

## Strings (`Strings.swift` + `Strings+*.swift`)

Never hardcode user-facing strings. All text lives in `Strings.swift`.

```swift
// ✅  Text(Strings.Timeline.tapToLog)
// ❌  Text("TAP TO LOG")
```

Organized by feature area: `Strings.MindCheck.*`, `Strings.Insight.*`, `Strings.Timeline.*`, etc.
When a feature's strings exceed ~50 lines, extract to `Strings+<Feature>.swift`.
Existing extensions: `Strings+CaloriePill.swift`, `Strings+Macros.swift`, `Strings+WellbeingCoach.swift`.

## Font System (`FontTheme.swift`)

Never hardcode fonts. Use `FontTheme.*` (SF Rounded via `.rounded` design).

```swift
// ✅  .font(FontTheme.mealEntry)
// ❌  .font(.system(size: 17, weight: .regular, design: .rounded))
```

| Token | Size | Weight | Use |
|---|---|---|---|
| `FontTheme.mealEntry` | 17pt | Regular | Large TextField input |
| `FontTheme.textEntry` | 16pt | Regular | TextEditor/TextField |
| `FontTheme.sectionHeader` | 18pt | Semibold | Display headlines |
| `FontTheme.body` | 16pt | Regular | Body copy |
| `FontTheme.caption` | 12pt | Regular | Helper text, metadata |

Custom size: `FontTheme.textEntry(size: 14, weight: .semibold)`

## Colors & Theming (`Theme.swift` + `ThemeComponents.swift`)

Exactly two theme files — do not create more.

| File | Responsibility |
|---|---|
| `Theme.swift` | Base tokens: background/accent/text/border colors, `Spacing`, `CornerRadius`, `Typography`, `Shadow`, `Layout` |
| `ThemeComponents.swift` | Component tokens: `MealCard`, `ScoreBadge`, `ScoreColors`, `Animation`, `Timeline`, `CaloriePill`, `Fasting`, `DateContext`; plus `View` helpers (`cardStyle`, `subtleBorder`, `pillStyle`) |

```swift
// ✅  view.background(AppTheme.cardBackground)
// ✅  view.padding(AppTheme.Spacing.medium)
// ❌  view.background(Color(.systemGray6).opacity(0.5))
```

Key tokens — **Theme.swift**: `AppTheme.background`, `.cardBackground`, `.sheetBackground`, `.secondaryBackground`, `Spacing.*`, `CornerRadius.*`, `Typography.*`, `Layout.*`

Key tokens — **ThemeComponents.swift**: `AppTheme.CaloriePill.*`, `.ScoreBadge.*`, `.Animation.*`, `.Timeline.*`, `.Fasting.*`, `.DateContext.*`

> Timing note: text-entry settle delay (500 ms) lives in `TimingConstants.textEntryDebounceNanoseconds`, not `AppTheme.TextEntry`.

## Validation Limits (`ValidationLimits.swift`)

| Constant | Limit |
|---|---|
| `ValidationLimits.mealDescription` | 500 chars |
| `ValidationLimits.journalEntry` | 1000 chars |
| `ValidationLimits.todoItem` | 150 chars |

Never hardcode field length limits in Views or ViewModels.

## Other SSOT Files

- **`TimingConstants.swift`** — All async delays, debounce intervals, polling periods. Never hardcode nanosecond/millisecond literals elsewhere.
- **`StorageKeys.swift`** — All `UserDefaults` key strings. Never pass raw literals to `UserDefaults.standard`.
- **`AppNotification.swift`** — Typed `NotificationCenter` names for cross-ViewModel signals (e.g. `AppNotification.healthProfileDidChange`). Never post raw string literals.
- **`Logging.swift`** — All `Logger` instances live in `AppLoggers`. Never create `Logger(subsystem:category:)` inline. Mark sensitive data with `privacy: .private`.
- **`AppError.swift`** — All service layers throw `AppError`. `errorDescription` never exposes internals; detailed context in `failureReason` for server-side logging only.
