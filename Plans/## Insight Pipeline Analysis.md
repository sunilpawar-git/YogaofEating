## Insight Pipeline Analysis

### How it works (architecture summary)

The pipeline has two paths that race:

**Server path:** `SnapshotPayloadBuilder` serializes 7 days of snapshots → Firebase Cloud Function `generateDailyBriefing` → Gemini generates `headline`, `nudge`, `correlationCards`

**Local fallback:** `PatternAnalysisEngine` runs 9 heuristic algorithms over the same 7-day window → returns hardcoded observation strings with computed confidence scores

`DailySynthesisEngine` runs independently and locally to compute the 4 dimension scores (Physical, Emotional, Clarity, Momentum) shown in "Today's Wellbeing."

---

### What the pipeline does well

- **Data collection is comprehensive.** All 6 sources (sleep, todos, morning thoughts, food, morning review, evening journal) are captured and fed into synthesis.
    
- **4-dimension model is sound.** Physical (meal quality) / Emotional (feeling + journal sentiment) / Clarity (sleep) / Momentum (todo completion) maps well to actual wellbeing drivers.
    
- **Trigger architecture is correct.** Any data change re-runs synthesis. Sleep bypasses debounce and fires immediately.
    

---

### What the pipeline does poorly — with evidence from the screenshots

#### Problem 1: Causal narrative doesn't reflect score direction

**Screenshot:** Momentum = 10%, but the narrative says _"Your follow-through on intentions is leading today."_

**Root cause:** `causalNarrative` is a single hardcoded string per dimension in `Strings.Synthesis.CausalNarrative.*`, with no branching for whether the score is high or low. `DailySynthesisEngine` picks the dominant dimension (largest deviation from 0.5) and attaches the same string regardless of direction.

At 10%, behavioral momentum is _terrible_ — but the narrative reads as positive. This is actively misleading.

**Fix needed:** The narrative must encode direction: `"Few intentions were completed today — this is weighing on your overall wellbeing"` vs `"Strong follow-through on intentions is carrying today."`

---

#### Problem 2: Correlation cards are generic textbook advice, not user-specific findings

**Screenshot:** _"Regular meal timing is linked to better sleep quality"_ and _"Morning intentions are often unmet — consider setting fewer, more focused goals."_

**Root cause:** These are **hardcoded strings** in `PatternAnalysisEngine+BriefingCards.swift`. The confidence score (60%, 100%) is computed from real data, but the observation text never changes regardless of the user's actual pattern.

The user ate at 11:50 and 13:15 today. The insight doesn't know — or say — whether _their_ meal timing was consistent or erratic. The "Intention Gap" card says "often unmet" but doesn't say how many were unmet today, this week, or over what period.

**Fix needed:** Inject actual data values into the observation strings. E.g.:

- `"You completed 1 of 4 morning intentions today (25%). This week's average: 35%."` instead of `"Morning intentions are often unmet"`
    
- `"Your meal gaps ranged from 2–6 hours this week — shorter gaps on days you slept well"` instead of generic timing advice
    

---

#### Problem 3: Food data is rich but absent from narrative

The user logged `50gm Kobichi bhaaji, 1 jowar bhakri, 1 small Mango, 100ml Varan` and scored 65%. None of this surfaces anywhere in the insights. The Physical score is 82% but there's no explanation of what drove that score.

**Root cause:** `SnapshotPayloadBuilder` sends `items: ["kobichi bhaaji", "jowar bhakri", ...]` to the server, but the local fallback and synthesis engine only use `healthScore` (a single float), not the food content.

**Fix needed:** The server Gemini prompt should be instructed to reference actual food items. Locally, the causal narrative for physical could note the meal count and approximate quality: _"Two meals logged, both scoring above 60% — your eating today was grounded."_

---

#### Problem 4: Text signals are keyword-matched, not semantically understood

`TextSignalExtractor` runs simple substring matching over morning thoughts and journal text. Keywords like `"plan"`, `"ready"`, `"clear"` trigger `.clear` signal, `"rest"` triggers `.selfCompassionate`. This will false-fire constantly on normal language.

Additionally: extracted signals feed into `DailySynthesisEngine` for dimension scoring, but they **don't appear in any displayed insight text** — the user never sees what was extracted from their words.

**Fix needed:** Pass raw morningThoughts and journalText directly in the Gemini payload. Let the LLM do semantic interpretation. The current keyword matching is both lossy and brittle, and the results are never surfaced to the user anyway.

---

#### Problem 5: Missing data silently centers scores at 0.5

If the user hasn't logged feeling, emotional tone = 0.5. No sleep selection = clarity = 0.5. No todos = momentum = 0.5. The synthesis runs with neutral placeholders and produces a 4-dimension breakdown that looks authoritative but is partly fabricated.

The user never knows which dimensions are real vs defaulted.

**Fix needed:** Track data completeness. Mark dimensions as "not enough data" rather than centering at 0.5. Show a data gap indicator in the Today's Wellbeing sheet.

---

#### Problem 6: Server prompts are a black box

The actual instructions sent to Gemini live in Firebase Cloud Functions, not in the Swift codebase. From the `SnapshotPayloadBuilder` output we can see what data reaches the prompt, but the instructions themselves are unauditable here. Given that the Morning Briefing output is generic and non-specific, the prompt likely doesn't instruct Gemini to reference actual food items, actual times, or actual counts.

The server response fields (`headline`, `nudge.suggestion`, `nudge.reasoning`, `correlationCards[].observation`) are all plain strings — there's no structured constraint forcing the AI to mention specific data.

---

### Ranked improvements (highest ROI first)

|   |   |   |   |
|---|---|---|---|
|Priority|Change|Where|Impact|
|1|Make causal narrative direction-aware (high vs low score)|Strings.Synthesis.CausalNarrative.* + DailySynthesisEngine|Stops misleading language like "leading today" at 10%|
|2|Inject actual counts into correlation card strings|PatternAnalysisEngine+BriefingCards.swift|Makes patterns specific: "1 of 4 todos" not "often unmet"|
|3|Send raw morningThoughts + journalText to Gemini payload|SnapshotPayloadBuilder|Enables AI to quote user's own words back|
|4|Add Gemini prompt instruction to reference specific food items + times|Firebase Cloud Function|Physical score tied to actual meal content|
|5|Track and display data completeness in dimension sheet|DailySynthesisEngine + Today's Wellbeing view|Honest about what's inferred vs logged|
|6|Replace keyword matching with raw text in Gemini payload|InsightLifecycleService|Better emotional signal extraction|

---

### The core diagnosis

The pipeline architecture is solid. The weakness is at the **content layer**: hardcoded strings pretend to be personalized insights, computed scores are attached to generic narratives, and the AI (Gemini) likely never sees the user's actual food names, journal sentences, or specific intention counts. The result is insights that feel like health-app boilerplate rather than a reflection of _this user's day_.

The fix isn't architectural — it's making each string data-aware and ensuring the Gemini prompt is instructed to ground its output in specifics from the payload.

Want me to start with the highest-ROI change (direction-aware causal narratives), or would you prefer to first examine the Firebase Cloud Function prompt?