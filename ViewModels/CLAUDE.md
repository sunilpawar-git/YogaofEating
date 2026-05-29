# ViewModels/ — Organization, SOLID, & Synthesis

## MainViewModel Extension Files

`MainViewModel` is split across extensions (250-line file limit):

| File | Responsibility |
|------|---|
| `MainViewModel.swift` | Core state, smiley logic, `@Published` properties |
| `MainViewModel+Lifecycle.swift` | `loadData`, `saveData`, day-reset monitor, account-switch detection, cloud restore, activity data refresh |
| `MainViewModel+MealCRUD.swift` | Add/update/delete meals, local score updates |
| `MainViewModel+AIAnalysis.swift` | AI analysis pipeline, scoring guards, async analysis flow |
| `MainViewModel+Insights.swift` | Daily briefing generation, insight notifications |
| `MainViewModel+Highlight.swift` | Highlight data aggregation (stats, patterns) |
| `MainViewModel+Reflect.swift` | Reflection tab data contract (`ReflectViewContract`) |
| `MainViewModel+Reflection.swift` | Journal entry persistence and evening review logic |
| `MainViewModel+MindCheck.swift` | Mind check (morning intentions, evening accountability) |
| `MainViewModel+DaySummary.swift` | Daily summary aggregation (stats, insights) |
| `MainViewModel+DateContext.swift` | Date header/subtext for the timeline banner |
| `MainViewModel+Navigation.swift` | Day navigation and data contracts for tab views |
| `MainViewModel+RecentMeals.swift` | Recent meals list and copy-meal (repeat meal) feature |
| `MainViewModel+CaloriePill.swift` | `CaloriePillData` computed property for the calorie pill |

## SettingsViewModel Extension Files

| File | Responsibility |
|------|---|
| `SettingsViewModel.swift` | User profile, appearance, notification, sensory prefs; all `@Published` properties |
| `SettingsViewModel+Sync.swift` | Cloud sync logic, network monitoring |
| `SettingsViewModel+Restore.swift` | Manual restore flow, backup listing |

## SOLID Principles

### Dependency Inversion (DIP) — most important rule

Always inject via protocol, never instantiate inside a class:

```swift
// ❌ BAD
class MainViewModel {
    let service = AILogicService()
}

// ✅ GOOD
class MainViewModel {
    let logicService: MealLogicProvider
    init(logicService: MealLogicProvider = AILogicService()) { ... }
}
```

### MVVM data flow

Views are read-only. Never call services from a View:

```swift
// ✅ CORRECT
struct MealLogView: View {
    @StateObject var viewModel: MealViewModel
    var body: some View {
        Button("Analyze") { viewModel.analyzeCurrentMeal() }
    }
}

@MainActor class MealViewModel: ObservableObject {
    @Published var mealScore: Double = 0.5
    func analyzeCurrentMeal() { mealScore = logicService.calculateScore(...) }
}
```

### Other SOLID rules (brief)
- **SRP**: Each class has one reason to change. If you can't describe it without "and", split it.
- **OCP**: Extend via protocols, don't modify existing code.
- **LSP**: Any mock must be substitutable for the real service (same contracts, same error cases).
- **ISP**: Small focused protocols (`MealLogicProvider`) not large monoliths (`AppService`).

## DailySynthesis Shape

- `causalNarrative` — from `CausalNarrativeResolver`; physical variant uses format strings in `Strings.Synthesis.CausalNarrative.*_fmt`
- `dataCompleteness: Set<WellbeingDimension>` — which dimensions have real data
- Use `synthesis.overall` (not `synthesis.dimensions.overall`) for the composite that excludes 0.5 stubs
- `synthesis.score(for:) -> Double?` — real score or nil
- `synthesis.displayScore(for:) -> Double` — real score or 0.5 fallback for legacy callers

## SnapshotPayloadBuilder

Server payload includes raw text for Gemini grounding:
- `morningThoughts` — raw text from `highlightData.morningThoughts` (omit if nil/empty)
- `journalEntry` — raw text from `reflectData.journalText` (omit if nil/empty)

`TextSignalExtractor` signals are for local synthesis only (`DailySynthesisEngine.collectSignals`) — NOT in the server payload.

## CorrelationCard

`CorrelationCard.dataReferences: [String]?` — optional server-grounded strings. iOS degrades gracefully when absent (nil).
