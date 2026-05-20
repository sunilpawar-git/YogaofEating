Let me explore the relevant files before giving concrete recommendations.

Completed Task: "Explore insight pipeline files"

Ran terminal command: find /Users/sunil/Downloads/YogaofEating -type f -name "*.swift" | grep -E "(DailySynthesis|Strings|PatternAnalysis|TextSignal|SnapshotPayload|InsightLifecycle)" | head -20

Read [](file:///Users/sunil/Downloads/YogaofEating/Logic/DailySynthesisEngine.swift)

Read [](file:///Users/sunil/Downloads/YogaofEating/Logic/Strings.swift)

Read [](file:///Users/sunil/Downloads/YogaofEating/Logic/PatternAnalysisEngine%2BBriefingCards.swift)

Read [](file:///Users/sunil/Downloads/YogaofEating/Logic/TextSignalExtractor.swift)

Read [](file:///Users/sunil/Downloads/YogaofEating/Logic/SnapshotPayloadBuilder.swift)

Read [](file:///Users/sunil/Downloads/YogaofEating/Logic/InsightLifecycleService.swift)

Read [](file:///Users/sunil/Downloads/YogaofEating/Logic/TextSignalKeywords.swift)

Read [](file:///Users/sunil/Downloads/YogaofEating/Logic/InsightLifecycleService%2BLocalGeneration.swift)

Here's my concrete recommendation for each problem:

---

**Problem 1 — Direction-aware causal narrative**

`causalNarrative(for:overall:)` at `DailySynthesisEngine.swift:173` ignores the `overall` parameter entirely. The fix is two parts:
- Add `_high` / `_low` variants to `Strings.Synthesis.CausalNarrative` in `Strings.swift:388`
- Change the switch at line 175 to branch on whether the dominant dimension score is above or below 0.5 — not just which dimension it is

This is a small, self-contained change.

---

**Problem 2 — Data-injected correlation cards**

Each `analyze*()` method in `PatternAnalysisEngine+BriefingCards.swift` already computes the numbers (avg score, gap, ratios) to derive `confidence` — they just never inject those numbers into the observation string. The fix is to interpolate the computed values directly into the string before returning. For example, `analyzeTodoBriefingCard` already knows how many todos were accomplished — it's right there in the confidence calculation.

No new data sources needed, just plumb the existing locals into the string.

---

**Problem 3 — Food data absent from narrative**

This splits into two independent sub-fixes:

**Local path:** `DailySynthesisEngine` has `meals` available but `causalNarrative()` only receives a `WellbeingDimension` and `Double` — no meal data. Change the signature to pass the synthesis input data through, so the physical narrative can reference meal count and average score.

**Server path:** This is a Firebase Cloud Function change. The payload already includes food item names and times (confirmed in `SnapshotPayloadBuilder`). The Cloud Function prompt just needs to be updated to instruct Gemini to reference them. This is a separate, server-side task.

---

**Problem 4 — Keyword matching**

`SnapshotPayloadBuilder.build()` sends structured `morningMindCheck`/`eveningMindCheck` entries but never the free-text `morningThoughts` or `journalEntry` strings. Add those two raw fields to the per-snapshot payload. Once Gemini receives the raw text, `TextSignalExtractor` becomes redundant for the server path. Keep it only for the local fallback scoring path.

---

**Problem 5 — Silent 0.5 defaults**

The four `compute*` functions at lines 72–112 return `Double`. Change them to return `Double?` — `nil` when data is absent, a real score when computed. Add a `dataCompleteness: Set<WellbeingDimension>` field to `DailySynthesis` to track which dimensions had real data. The Today's Wellbeing view then shows a muted/dashed bar for `nil` dimensions rather than a confident 50%.

This is the most invasive change since it touches the model, engine, and view — but it's clean and honest.

---

**Problem 6 — Black-box server prompt**

This is genuinely a server-side problem. Three things together address it without needing the prompt to be auditable from Swift:

1. Problems 3+4 above make the payload maximally specific — food names, times, raw journal text
2. The Cloud Function prompt needs one explicit instruction added: *"Reference specific food items, times, and counts from the payload rather than giving generic advice"*
3. The `correlationCards[].observation` response field could optionally include a `dataReferences` array (parallel to what the local path already does) so the app can verify the AI actually grounded its output

Items 1 and 3 are Swift changes. Item 2 is a Cloud Function change that should be tracked separately.

---

**Summary of what changes where:**

| Problem | File(s) | Type |
|---|---|---|
| 1 | `Strings.swift:388`, `DailySynthesisEngine.swift:173` | Swift |
| 2 | `PatternAnalysisEngine+BriefingCards.swift:38,73,114,156` | Swift |
| 3 (local) | `DailySynthesisEngine.swift` signature change | Swift |
| 3 (server) | Firebase Cloud Function prompt | Server |
| 4 | `SnapshotPayloadBuilder.swift`, remove `TextSignalExtractor` from server path | Swift |
| 5 | `DailySynthesisEngine.swift`, `DailySynthesis` model, wellbeing sheet view | Swift |
| 6 | Firebase Cloud Function prompt + optional `dataReferences` field | Server + Swift |

Problems 1, 2, and 4 are low-risk and self-contained — good starting points. Problem 5 touches three layers and warrants its own branch.