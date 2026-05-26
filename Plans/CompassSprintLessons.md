# Today's Compass — Sprint Lessons

## Problem

The "Morning Briefing" sheet was stale and non-functional:
- Title still read "Morning Briefing" (sprint renamed it "Today's Compass")
- Showed 0% goal completion regardless of actual todo state
- Content was generic, not AI-personalised — it was the local `PatternAnalysisEngine` fallback firing every time
- Refresh produced the same stale data

Root cause was unknown going in. The sheet appeared to work (no crash, no visible error) but silently fell back to local generation on every call.

---

## Sprint Fix (6 Phases)

The sprint rebuilt the briefing pipeline end-to-end:

| Phase | Work |
|---|---|
| 1 | Cloud Function `generateDailyBriefing` — fetches 7 days of real data, calls Gemini |
| 2 | `InsightLifecycleService` — server-first with local fallback |
| 3 | `BriefingDetailView` — new sheet UI with correlation cards, nudge, weekly trend |
| 4 | `SnapshotPayloadBuilder` — sends raw journal + morning thoughts to Gemini |
| 5 | `HistoricalDataService` — 30/90-day summary for context |
| 6 | `CorrelationCard.dataReferences` — Gemini grounds observations in user data |

After the sprint, the sheet was wired but **still showed stale data**. The sprint hadn't actually fixed the live behaviour.

---

## Tech Debt Sweep

A post-sprint audit found issues the sprint introduced or missed:

**Crash risks**
- 3× `calendar.date(byAdding:)!` force unwraps in `HistoricalDataService+Summary.swift` — crash on any calendar edge case
- 1× force unwrap in `MainViewModel+Reflection.swift`
- Fix: guard-let with `HistoricalSummary.empty` fallback

**Data loss**
- `dismissInsight()` appended to `nudgeHistory` in memory but never called `saveData()` — nudges lost on restart

**SSOT violations**
- `Strings.Briefing.navigationTitle` ("Morning Briefing") and `cardTitle` ("Today's Compass") diverged; sheet still showed old title
- Gemini model ID hardcoded as raw string in 4 places in `index.js`

**Dead code**
- `hasBriefingAvailable` and `hasUnreadBriefing` — computed, never referenced outside the ViewModel

**Cache bypass missing**
- `triggerInsightGeneration()` short-circuited on cached insight; refresh button called it without force, so stale data persisted
- Fix: `force: Bool = false` param; ↻ toolbar button passes `force: true`

**JS type mismatch**
- `isAccomplished === true` (boolean) but iOS serialises it as string `"true"` — goal completion was always 0%

---

## Cloud Function Failure

Even after all the above fixes were deployed, the sheet still showed local fallback content. Xcode logs revealed:

```
[InsightLifecycle] Server generation failed, falling back to local
```

Firebase logs showed:

```
FirebaseAppError: The default Firebase app does not exist.
Make sure you call initializeApp() before using any of the Firebase services.
    at BriefingPerformanceMetrics.logGenerationStart (briefingPerformanceMonitor.js:26)
    at index.js:429
```

**Root cause**: `firebase-functions/v2` does not auto-initialize the Firebase Admin SDK. `index.js` required `firebase-admin` but never called `admin.initializeApp()`. `BriefingPerformanceMonitor` had a lazy guard (`initializePerformanceMonitoring()`) that was supposed to handle this, but with `firebase-admin@13` the deferred init inside a handler doesn't reliably complete before `admin.firestore()` is called on the next line.

**Fix**: one line added at module load time in `index.js`:
```js
if (!admin.apps.length) {
    admin.initializeApp();
}
```

This ran synchronously before any handler, making the admin SDK available to all downstream calls including `BriefingPerformanceMonitor`.

---

## Key Lessons

1. **Silent fallbacks hide real failures.** The local fallback made the app appear functional. A forced error (or at least a visible indicator) would have surfaced the Cloud Function failure immediately.

2. **`firebase-functions/v2` requires explicit admin init.** The v1 runtime auto-initialised; v2 does not. Any project migrating to v2 must add `admin.initializeApp()` at module load.

3. **Type contracts between Swift and JS are invisible.** iOS serialises `Bool` as string `"true"`/`"false"`; JS strict equality `=== true` silently never matches. Cross-platform payloads need explicit coercion comments or tests.

4. **Force unwraps on `Calendar.date(byAdding:)` are latent crashes.** The API returns `Optional` for a reason (DST transitions, calendar reform). Always guard-let.

5. **Cache bypass must be explicit.** Idempotent generation is good for cost; but a user-visible refresh must be able to escape the cache. Flag it at the call site, not as a global override.

6. **Post-sprint audits catch what feature work misses.** The 6-phase sprint shipped working architecture. The audit caught the production failure and the debt that would have caused maintenance pain later.
