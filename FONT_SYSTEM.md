<!-- FONT SYSTEM GUIDE FOR YOGA OF EATING -->

# Font System Guide — Yoga of Eating

## Overview

All fonts in the Yoga of Eating app use **SF Rounded** (`.rounded` design) for a warm, minimalist, and mindful aesthetic. This design choice embodies the app's wellness-focused philosophy.

### Why SF Rounded?
- **Warm & Approachable** — Perfect for mindfulness and wellness applications
- **Minimal** — Clean, uncluttered letterforms
- **Readable** — Excellent legibility across all text sizes
- **Native** — Built into iOS; no additional dependencies

---

## Font Configuration

All fonts are defined in **`Logic/FontTheme.swift`** (centralized, single source of truth).

### Available Fonts

| Use Case | Property | Size | Weight | Code |
|----------|----------|------|--------|------|
| **Meal Entry** | `FontTheme.mealEntry` | 17pt | Regular | `TextField` in meals |
| **Text Entry** | `FontTheme.textEntry` | 16pt | Regular | `TextField`/`TextEditor` in highlights & reflect |
| **Section Headers** | `FontTheme.sectionHeader` | 18pt | Semibold | Display headlines |
| **Body Text** | `FontTheme.body` | 16pt | Regular | General body copy |
| **Captions** | `FontTheme.caption` | 12pt | Regular | Helper text, metadata |

### Custom Font Sizes

For non-standard sizes, use the convenience method:

```swift
FontTheme.textEntry(size: 14, weight: .semibold)
```

---

## Where Fonts Are Used

### Text Input Fields (Primary)

1. **Meals** (`JournalBlockInputSection.swift`)
   - Property: `FontTheme.mealEntry` (17pt)
   - Component: `TextField` for meal descriptions
   - Effect: Prominent, encouraging journaling

2. **Highlights** (`HighlightSections.swift`)
   - Sleep Notes: `FontTheme.textEntry` (16pt) on `TextField`
   - Morning Thoughts: `FontTheme.textEntry` (16pt) on `TextEditor`

3. **Reflect** (`ReflectSections.swift`)
   - Journal: `FontTheme.textEntry` (16pt) on `TextEditor`

### Display Text (Secondary)

- **BriefingDetailView**: Headlines (`.rounded`)
- **DayTimelineView**: Quotes (`.rounded`)
- **ScoreBreakdownSheet**: Meal descriptions (`.rounded`)
- **JournalBlockStyles**: Breathing placeholder (`.rounded`)
- **MorningBriefingCard**: Headlines (`.rounded`)

---

## Adding New Text Elements

When adding new text to the app:

### For Text Entry (TextField/TextEditor)
```swift
TextField("Placeholder", text: $text)
    .font(FontTheme.textEntry)  // or FontTheme.mealEntry for larger
```

### For Display Text
```swift
Text("Some headline")
    .font(FontTheme.sectionHeader)

Text("Supporting text")
    .font(FontTheme.body)

Text("Small helper")
    .font(FontTheme.caption)
```

### For Custom Sizes
```swift
Text("Custom size text")
    .font(FontTheme.textEntry(size: 14, weight: .semibold))
```

---

## Design Principles

### 1. **Single Source of Truth**
   - All font definitions live in `FontTheme.swift`
   - Never hardcode fonts elsewhere
   - Search for hardcoded `.serif` or `.monospaced` to catch missed instances

### 2. **Consistency**
   - All text entry fields use `FontTheme.textEntry` or `FontTheme.mealEntry`
   - All headers use `FontTheme.sectionHeader`
   - All captions use `FontTheme.caption`

### 3. **Maintainability**
   - To change all fonts app-wide: edit `FontTheme.swift` once
   - No need to hunt through 10+ view files

### 4. **Minimalism**
   - SF Rounded supports the "less is more" philosophy
   - Sizes stay consistent (16–17pt for entry, 18pt for headers)
   - Weights are moderate (Regular, Semibold max)

---

## Future Enhancements

### Optional: Font Size Accessibility
If the app adds accessibility options for users with visual impairments, extend `FontTheme`:

```swift
static let accessibilityMealEntry = Font.system(
    size: UIAccessibility.isItalicTextEnabled ? 18 : 17,
    weight: .regular,
    design: .rounded
)
```

### Optional: Dark Mode Tweaks
SF Rounded works beautifully in both light and dark modes with no changes needed.

### Optional: Custom Font Weights
If design requires it, add new static properties:

```swift
static let headlineBold = Font.system(size: 18, weight: .bold, design: .rounded)
```

---

## Testing Fonts Visually

To verify the SF Rounded font is applied correctly:

1. **Run the app** on iPhone 16 simulator
2. **Log meals, highlights, and reflections** — observe the warm, rounded letterforms
3. **Compare before/after** — the `.serif` fonts were more formal; `.rounded` is warmer and more approachable

---

## References

- **FontTheme**: `Logic/FontTheme.swift`
- **Meal Entry**: `Views/JournalBlockInputSection.swift` (line 60)
- **Highlights**: `Components/HighlightSections.swift` (lines 76, 260)
- **Reflect**: `Components/ReflectSections.swift` (line 84)

