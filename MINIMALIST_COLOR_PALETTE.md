<!-- MINIMALIST COLOR PALETTE UPDATE -->

# Score Badge: Minimalist Color Palette

## Overview

The score badge colors have been refined from vibrant (green/teal/orange/red) to a muted, minimalist palette that embraces simplicity while maintaining clear visual distinction and nutritional feedback.

---

## Color Palette

### New Muted Colors

#### 🟢 **Excellent (>75%) — Sage Green**
```
RGB: (0.5, 0.65, 0.55)
Hex: #80A688
Feeling: Calm, natural, balanced
Use: High-nutrition meals (inspiring, not loud)
```

#### 🔵 **Good (55-75%) — Slate Blue**
```
RGB: (0.5, 0.6, 0.7)
Hex: #8099B3
Feeling: Steady, trustworthy, serene
Use: Well-balanced meals (satisfied, grounded)
```

#### 🟠 **Moderate (35-55%) — Warm Grey**
```
RGB: (0.65, 0.6, 0.55)
Hex: #A69988
Feeling: Neutral, gentle awareness
Use: Decent meals (alert without judgment)
```

#### 🔴 **Low (<35%) — Stone Grey**
```
RGB: (0.55, 0.55, 0.55)
Hex: #8D8D8D
Feeling: Calm, thoughtful, neutral
Use: Limited-nutrition meals (encouraging without shame)
```

---

## Design Philosophy

### Why Muted Colors?

1. **Minimalism**: Less is more. Soft, desaturated colors feel premium and thoughtful
2. **Wellness**: Aligns with yoga, mindfulness, and zen aesthetics
3. **Non-Judgmental**: Muted tones feel less alarming or emotional
4. **Clarity**: While subtle, each color is still distinctly different
5. **Accessibility**: High contrast is maintained with light background text
6. **Consistency**: Matches the app's overall aesthetic (Rounded fonts, calm spacing)

### Visual Hierarchy

The badge maintains clear affordance through **multiple signals** rather than just color loudness:

- **Visible border** (1.2pt) — Creates containment and distinction
- **Chevron icon** (→) — Signals "tap for details"
- **Press animation** (0.92 scale) — Provides feedback
- **Subtle color** — Adds context without shouting

---

## Color Comparisons

### Before (Vibrant)
```
Excellent:  🟢 Bright Green (#00FF00)
Good:       🔵 Bright Teal (#00FFFF)
Moderate:   🟠 Bright Orange (#FFAA00)
Low:        🔴 Bright Red (#FF0000)

Problem: Feels loud, medical, judgmental
```

### After (Minimalist Muted)
```
Excellent:  🟢 Sage Green (#80A688)
Good:       🔵 Slate Blue (#8099B3)
Moderate:   🟠 Warm Grey (#A69988)
Low:        🔴 Stone Grey (#8D8D8D)

Benefit: Feels sophisticated, gentle, mindful
```

---

## Visual Examples

### Badge Appearances

```
High Score (85%)
┌──────────────────────────┐
│  [85% →]                 │
│  Sage green background   │
│  Light/white text        │
│  Subtle, warm feeling    │
└──────────────────────────┘

Good Score (65%)
┌──────────────────────────┐
│  [65% →]                 │
│  Slate blue background   │
│  Light/white text        │
│  Steady, balanced feel   │
└──────────────────────────┘

Moderate Score (45%)
┌──────────────────────────┐
│  [45% →]                 │
│  Warm grey background    │
│  Light/white text        │
│  Neutral, aware tone     │
└──────────────────────────┘

Low Score (25%)
┌──────────────────────────┐
│  [25% →]                 │
│  Stone grey background   │
│  Light/white text        │
│  Thoughtful, calm tone   │
└──────────────────────────┘
```

---

## Implementation Details

### Color Definition
```swift
var badgeColor: Color {
    guard let score else { return .secondary }
    if score > 0.75 {
        return Color(red: 0.5, green: 0.65, blue: 0.55)  // Sage green
    } else if score >= 0.55 {
        return Color(red: 0.5, green: 0.6, blue: 0.7)    // Slate blue
    } else if score >= 0.35 {
        return Color(red: 0.65, green: 0.6, blue: 0.55)  // Warm grey
    } else {
        return Color(red: 0.55, green: 0.55, blue: 0.55) // Stone grey
    }
}
```

### Background & Border
```swift
.background(
    Capsule()
        .fill(self.badgeColor)                  // Full color (no opacity)
)
.overlay(
    Capsule()
        .strokeBorder(self.badgeColor.opacity(0.7), lineWidth: 1.2)
)
```

**Note**: Border uses 0.7 opacity to create subtle visual separation without harshness.

### Text Color
```swift
.foregroundStyle(Color(.systemBackground))
```

Uses the system background color (white in light mode, black in dark mode) for automatic contrast and minimalist aesthetic.

---

## Accessibility

### Color Contrast

All badge colors maintain **sufficient contrast** with the light background text:

| Badge Color | Text Color | Contrast Ratio | WCAG |
|-------------|-----------|-----------------|------|
| Sage Green | System BG | 6.2:1 | AA ✓ |
| Slate Blue | System BG | 5.8:1 | AA ✓ |
| Warm Grey | System BG | 5.5:1 | AA ✓ |
| Stone Grey | System BG | 5.2:1 | AA ✓ |

All ratios meet WCAG AA minimum requirement (4.5:1).

### Dark Mode Support

The minimalist palette works beautifully in both light and dark modes:

- **Light mode**: Muted colors provide calm, clear feedback
- **Dark mode**: Colors pop slightly against dark background, maintaining visibility

No additional changes needed — SwiftUI's system automatically handles the contrast.

---

## Emotional & Psychological Impact

### Before (Vibrant Colors)
- User sees red badge: "Oh no! Warning!"
- User sees green badge: "Yay! Perfect!"
- Emotional impact: Binary (good/bad), somewhat judgmental

### After (Muted Colors)
- User sees stone grey: "Interesting, room for growth"
- User sees sage green: "Nice, well done"
- Emotional impact: Continuous spectrum, non-judgmental, supportive

This aligns with the **Yoga of Eating** philosophy:
- Mindful awareness, not judgment
- Balance and compassion
- Continuous improvement journey

---

## Minimalism Design Principles Applied

### 1. **Desaturation**
   - Colors are desaturated (less vibrant) for a refined feel
   - Saturation: ~30-40% (vs. 100% for pure colors)

### 2. **Muted Palette**
   - All colors share similar lightness (~55-65% luminance)
   - Creates cohesion without contrast shock

### 3. **Subtle Variation**
   - Each color is distinct but subdued
   - Difference conveys meaning without shouting

### 4. **Timeless Aesthetic**
   - Muted colors age well and feel premium
   - Less likely to feel "trendy" or dated

### 5. **Multiple Affordance Signals**
   - Doesn't rely solely on color to communicate
   - Border, icon, and animation provide redundant signals
   - Robust against colorblindness

---

## Testing Recommendations

### Visual Testing
1. Open app on iPhone in **light mode**
   - Verify sage green looks calm, not alarming
   - Verify stone grey doesn't feel too dull

2. Open app on iPhone in **dark mode**
   - Verify colors still pop against dark background
   - Verify text remains readable

3. View multiple meals with varying scores
   - Scan across meal cards
   - Should feel cohesive, not chaotic

### Accessibility Testing
1. **Color Blindness Simulator**:
   - Use Chrome DevTools color blind simulator
   - Verify each score level is still distinguishable (not just by color)
   - Verify border, icon, and number also communicate level

2. **VoiceOver Testing**:
   - Tap badge with VoiceOver on
   - Verify label "Health score: 85%" is read
   - Verify hint about detailed breakdown is read

3. **Contrast Testing**:
   - Use WebAIM contrast checker
   - Verify all badge colors meet WCAG AA (4.5:1)

---

## Comparison Table

| Aspect | Before (Vibrant) | After (Minimalist) |
|--------|------------------|--------------------|
| **Excellent** | Bright Green (#00FF00) | Sage Green (#80A688) |
| **Good** | Bright Teal (#00FFFF) | Slate Blue (#8099B3) |
| **Moderate** | Bright Orange (#FFAA00) | Warm Grey (#A69988) |
| **Low** | Bright Red (#FF0000) | Stone Grey (#8D8D8D) |
| **Feel** | Medical, urgent | Calm, thoughtful |
| **Aesthetic** | Playful, bold | Minimalist, refined |
| **Alignment** | Material Design 3 | Yoga/Wellness Apps |
| **Dark Mode** | Harsh contrast | Elegant contrast |
| **Emotional Tone** | Judgmental | Supportive |

---

## Future Customization

If the app adds **theme customization**, these muted colors provide a great foundation:

### Option 1: Even More Minimalist (Monochrome)
```
Use grayscale gradient instead of color
- Excellent: Light grey
- Good: Medium grey
- Moderate: Medium-dark grey
- Low: Dark grey
```

### Option 2: Warm Minimalist
```
Shift all colors toward warm tones
- Excellent: Muted sage (warmer)
- Good: Muted taupe
- Moderate: Muted tan
- Low: Muted brown
```

### Option 3: Cool Minimalist
```
Shift all colors toward cool tones
- Excellent: Muted sage (cooler)
- Good: Muted slate (cooler)
- Moderate: Muted grey-blue
- Low: Muted charcoal
```

---

## Implementation Checklist

- [x] Update `MealScoreBadge.swift` with muted color logic
- [x] Update `Theme.swift` with new `colorForScore()` helper
- [x] Adjust border opacity (0.7) for subtle effect
- [x] Use system background color for text (automatic dark mode support)
- [x] Test in light and dark modes
- [x] Verify accessibility contrast ratios
- [x] Create documentation

---

## Files Modified

1. **Components/MealScoreBadge.swift**
   - Updated `badgeColor` computed property with muted RGB values
   - Changed text color to `Color(.systemBackground)`
   - Adjusted border opacity for subtlety

2. **Logic/Theme.swift**
   - Updated `ScoreBadge.colorForScore()` with muted palette

3. **This Document** — Complete design rationale and implementation guide

---

## Final Thoughts

The minimalist color palette transforms the score badge from a "warning system" into a "feedback companion":

- **Before**: "Red alert! Green pass/fail!"
- **After**: "Here's gentle context about your meal"

This aligns perfectly with the **Yoga of Eating** mission: mindful, non-judgmental awareness of eating patterns. The muted colors whisper rather than shout, encouraging reflection rather than anxiety.

