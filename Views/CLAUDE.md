# Views/ — Tab Implementation Guidelines

## The Rule: Parameters, Not @EnvironmentObject

Tab views receive only the data they need via a typed contract struct. Never inject `MainViewModel` directly.

```swift
// ✅ CORRECT — only receives what it needs
struct MyTabView: View {
    let data: MyTabViewContract?
}

// ❌ WRONG — full access to ALL user data
struct MyTabView: View {
    @EnvironmentObject var viewModel: MainViewModel
}
```

## How to Wire a New Tab

1. **Define a contract struct** in `Models/TabViewContracts.swift` (existing SSOT: `HighlightViewContract`, `ReflectViewContract`).

2. **Expose it via a computed property** on `MainViewModel` in the relevant `MainViewModel+<Tab>.swift` extension:
   ```swift
   var myTabData: MyTabViewContract? {
       guard self.isViewingToday else { return nil }
       guard !self.meals.isEmpty else { return nil }
       return MyTabViewContract(mealsCount: self.meals.count, ...)
   }
   ```

3. **Use mock data in previews** — never `MainViewModel()` in a preview:
   ```swift
   #Preview {
       MyTabView(data: MyTabViewContract(mealsCount: 3, averageScore: 0.75))
   }
   ```

4. **Write data isolation tests**:
   ```swift
   func test_myTabView_cannotAccessMeals() { ... }
   func test_myTabView_cannotAccessSleepData() { ... }
   ```

## Code Review Checklist for Tab PRs

- ✓ Tab view accepts data via parameters, not `@EnvironmentObject`
- ✓ No direct references to `MainViewModel` in tab view code
- ✓ Previews use mock data
- ✓ Computed properties on `MainViewModel` are minimal
- ✓ Unit tests verify data isolation
