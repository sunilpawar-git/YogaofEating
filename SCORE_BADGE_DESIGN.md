<!-- SCORE BADGE IMPROVEMENT GUIDE -->

# Score Badge UX/UI Enhancement Guide

## Overview

The AI meal score badge (displayed in the top-right of each meal card) has been redesigned to be more visible, tappable, and informative. The new design uses color-based feedback and clear affordances to communicate interactivity.

---

## What Changed

### Before (Original)
- **Visual Design**: Subtle grey background (`.secondarySystemBackground`), secondary text color
- **Problem**: Blended too much with the card background, making it hard to see and tap
- **Affordance**: No clear indication that it was tappable
- **Color**: Monochrome — no nutritional feedback from the score value

### After (Improved)
- **Visual Design**: 
  - Color-coded background based on score quality
  - Visible border (1.2pt stroke) for clarity
  - White text for maximum contrast
  - Larger padding for better tap target
  
- **Affordances**:
  - Chevron icon (→) signals "tap for details"
  - Subtle press animation (0.92 scale) on tap
  - Enhanced accessibility hints
  
- **Color Feedback**:
  - 🟢 **Green (>75%)** — Excellent nutrition
  - 🔵 **Teal (55-75%)** — Good nutrition
  - 🟠 **Orange (35-55%)** — Moderate nutrition
  - 🔴 **Red (<35%)** — Low nutrition

---

## Visual Design Details

### Badge Structure
```
┌──────────────────┐
│  85% →           │  ← Score + Chevron icon
└──────────────────┘
  ↑ Colored background (opacity: 0.85)
  ↑ Colored border (stroke: 1.2pt)
```

### Dimensions
| Property | Value |
|----------|-------|
| Horizontal Padding | 8pt |
| Vertical Padding | 4pt |
| Font Size | 12pt |
| Font Weight | Semibold |
| Border Width | 1.2pt |
| Corner Radius | Capsule |

### Color Mapping
```swift
func badgeColorForScore(_ score: Double) -> Color {
    if score > 0.75 { return .green }           // Excellent
    else if score >= 0.55 { return .teal }     // Good
    else if score >= 0.35 { return .orange }   // Moderate
    else { return .red }                        // Low
}
```

---

## UX/Tapability Affordances

### 1. **Chevron Icon (→)**
   - **Why**: Arrow pointing right universally signals "tap to see more"
   - **Size**: 9pt, semibold (smaller than percentage text)
   - **Placement**: Right of the percentage, creates visual hierarchy

### 2. **Press Animation**
   - **Effect**: Scales to 0.92 on tap (subtle but noticeable)
   - **Spring**: (response: 0.2, dampingFraction: 0.6) — snappy, responsive
   - **Feedback**: User immediately knows their tap registered

### 3. **Color as Information**
   - **Visual Language**: Color conveys meal quality at a glance
   - **Consistency**: Score-based coloring aligns with smiley state (green = serene, etc.)
   - **Motivation**: Color can encourage better eating choices

### 4. **Border for Distinction**
   - **Why**: Creates visual separation from the card background
   - **Effect**: Makes the badge "pop" and feel like a distinct, tappable element
   - **Width**: 1.2pt (visible but not heavy-handed)

### 5. **Accessibility Enhancements**
   - **Label**: "Health score: 85%"
   - **Hint**: "Tap to see detailed score breakdown and nutrition analysis"
   - **VoiceOver**: Announces both the score and the action (tappable)

---

## Positioning in the Card

The badge appears in the **top-right corner** of each meal card:

```
┌─ Meal Card ─────────────────┐
│ 🍽️ Breakfast      [85% →]   │  ← Top-right position
│ • Item 1                    │
│ • Item 2                    │
│ 13 items                    │
└─────────────────────────────┘
```

**Why top-right?**
- Natural reading order (left-to-right, top-to-bottom)
- Far from the meal type tag (left side) — less visual clutter
- Clear sightline for users scanning quickly
- Easily accessible thumb on mobile (top-right is reachable)

---

## Implementation Details

### File: `Components/MealScoreBadge.swift`

**Key Properties**:
```swift
@State private var isPressed: Bool = false

var badgeColor: Color {
    guard let score else { return .secondary }
    if score > 0.75 { return .green }
    else if score >= 0.55 { return .teal }
    else if score >= 0.35 { return .orange }
    else { return .red }
}
```

**Body Structure**:
```swift
HStack(spacing: 3) {
    Text(formattedScore)           // "85%"
    Image(systemName: "chevron.right")  // →
}
.background(Capsule().fill(badgeColor.opacity(0.85)))
.overlay(Capsule().strokeBorder(badgeColor, lineWidth: 1.2))
.scaleEffect(isPressed ? 0.92 : 1.0)
```

### File: `Logic/Theme.swift`

**New Theme Properties**:
```swift
enum ScoreBadge {
    static let borderWidth: CGFloat = 1.2
    
    static func colorForScore(_ score: Double) -> Color {
        if score > 0.75 { return .green }
        else if score >= 0.55 { return .teal }
        else if score >= 0.35 { return .orange }
        else { return .red }
    }
}
```

---

## User Experience Flow

1. **User sees meal card** with score badge in top-right
   - Color immediately communicates meal quality (green = good, red = needs work)

2. **User notices chevron icon** and slight visual distinctness
   - Chevron signals "interactive" / "tap for more"

3. **User taps the badge**
   - Scale animation provides tactile feedback
   - Score breakdown sheet opens showing detailed analysis

4. **User sees breakdown** with AI insights, nutrition scores, etc.
   - Clear explanation of how the meal scored

---

## Design Principles Applied

### 1. **Visual Hierarchy**
   - Color background (prominent) > Border > Text
   - Ensures badge is noticed first

### 2. **Affordance**
   - Multiple signals that element is tappable:
     - Color (distinct from background)
     - Border (boundary/containment)
     - Icon (chevron = "go to next")
     - Animation (press feedback)

### 3. **Information Design**
   - Score-based colors encode nutrition quality without text
   - Fits mindfulness aesthetic: simple, non-judgmental feedback

### 4. **Consistency**
   - Border radius matches card radius (capsule = rounded)
   - Press animation matches other cards (0.96 scale)
   - Color palette aligns with smiley states

### 5. **Accessibility**
   - High contrast: white text on colored background
   - Sufficient tap target: 12pt font + 8pt padding
   - Clear VoiceOver hints about action

---

## Future Enhancements

### 1. **Haptic Feedback**
   - Add `.medium` haptic on tap for additional sensory confirmation
   
### 2. **Animated State Transitions**
   - Score changes trigger a brief pulse animation
   - Celebrates improvements, acknowledges declines

### 3. **Long-press Menu**
   - Long-press to quickly view nutritional categories (protein, carbs, fat)
   - Share score or meal data

### 4. **Customizable Color Scheme**
   - Allow users to choose color language (warm/cool/pastel)
   - Respect system accessibility color settings

### 5. **Micro-interactions**
   - Subtle bounce when score updates in real-time
   - Confetti-like animation for reaching new personal bests

---

## Testing the Badge

### Visual Testing
1. Launch app on iPhone simulator
2. Add a meal with high nutrients (>75%) — badge should be green
3. Add a meal with low nutrients (<35%) — badge should be red
4. Verify border is clearly visible and distinct from card

### Interaction Testing
1. Tap the badge — verify scale animation is smooth
2. Hold finger on badge — verify animation responds
3. Use VoiceOver to verify accessibility labels are read correctly

### Accessibility Testing
- [ ] Tap target is at least 44x44pt (sufficient on iPhone)
- [ ] Color alone doesn't convey meaning (text + icon + animation)
- [ ] High contrast: white text on colored background (WCAG AA)
- [ ] VoiceOver clearly states "tappable" status

---

## References

- **Implementation**: `Components/MealScoreBadge.swift`
- **Theme**: `Logic/Theme.swift` (ScoreBadge enum)
- **Usage**: `Views/JournalBlockView.swift` (line 132)
- **Tests**: `Yoga of EatingTests/MealScoreBadgeTests.swift`

---

## Design Inspiration

This badge design follows established UI/UX patterns:
- **Gaming**: Score badges in fitness apps use color to motivate
- **Apple**: Control Center toggles use chevrons to indicate settings access
- **Material Design 3**: Chips with icons signal interactivity
- **Mindfulness Apps**: Calm, Headspace use color psychology for emotional feedback
