# Code Review: Next-Day Insight Engine — Issues & Remediation Plan

**Date**: May 1, 2026  
**Scope**: Sprint implementation of Daily Briefing system  
**Status**: 16 issues identified | 6 Critical/High | Ready for phased remediation

---

## Executive Summary

The Next-Day Insight engine implementation contains **16 identified issues** ranging from critical data persistence bugs to security leaks and maintainability concerns:

- **Critical (5)**: Struct mutation bug, missing auth, parsing errors, notification wiring, cold start issue
- **High (1)**: Missing HealthKit integration
- **Medium (7)**: Magic numbers, debug UI, logging, semantic mismatches
- **Low (3)**: Nice-to-have optimizations

**Recommendation**: Fix Phase A (ship blockers) before production deployment. Phases B & C can run in parallel with next sprint planning.

---

## Issues Identified

### 🔴 CRITICAL ISSUES (Ship Blockers)

#### 1. **Struct Mutation Anti-Pattern: `markBriefingViewed()` Does Nothing**

**Severity**: CRITICAL — Data Corruption  
**File**: `ViewModels/MainViewModel+Insights.swift:87–92`

```swift
// ❌ BUG: Struct mutation via optional chaining affects temporary copy, not @Published
func markBriefingViewed() {
    guard self.currentBriefing != nil else { return }
    self.currentBriefing?.markAsViewed()  // Mutates temp copy, lost!
    if let updated = self.currentBriefing {
        self.historicalService.updateBriefing(for: Date(), briefing: updated)
        // ↑ Persists unmodified briefing with isViewed == false FOREVER
    }
}
```

**Impact**:
- Unread indicator never clears
- User sees persistent "new briefing" dot
- Persistence contradicts UX
- Same bug in `dismissInsight()` (line 61–67)

**Fix**:
```swift
func markBriefingViewed() {
    guard var briefing = self.currentBriefing else { return }
    briefing.markAsViewed()  // Mutate local copy
    self.currentBriefing = briefing  // Re-publish
    self.historicalService.updateBriefing(for: Date(), briefing: briefing)
}
```

---

#### 2. **Cold Start: `currentBriefing` Never Restored After App Relaunch**

**Severity**: CRITICAL — Missing Data on Relaunch  
**File**: `ViewModels/MainViewModel.swift:138–152` + `MainViewModel+Insights.swift:99–104`

**Issue**: `loadData()` restores meals and snapshots but **never** hydrates `currentBriefing` from `historicalService.getSnapshot(for: Date())?.briefing`.

```swift
// ❌ In loadData():
func loadData() {
    if let data = self.persistenceService.load() {
        self.meals = data.meals
        self.smileyState = data.smileyState
        self.lastResetDate = data.lastResetDate
        self.historicalService.historicalData = data.historicalData
        // MISSING: self.currentBriefing = historicalService.getSnapshot(for: Date())?.briefing
        self.checkAndResetIfNewDay()
    }
}

// ❌ In triggerBriefingGeneration():
if let existing = self.currentBriefing,
   Calendar.current.isDate(existing.date, inSameDayAs: date)
{
    return  // Only checks @Published var, not persistent snapshot!
}
// Can trigger DUPLICATE Cloud Function calls
```

**Impact**:
- Morning Briefing card disappears after app relaunch (even though data exists in Firestore)
- Duplicate briefing generation calls → wasted Gemini quota
- User sees blank screen instead of yesterday's briefing

**Fix**:
```swift
// In loadData():
func loadData() {
    if let data = self.persistenceService.load() {
        // ... existing code ...
        self.historicalService.historicalData = data.historicalData
        
        // NEW: Hydrate currentBriefing from today's snapshot
        if let todaySnapshot = self.historicalService.getSnapshot(for: Date()) {
            self.currentBriefing = todaySnapshot.briefing
        }
    }
}

// In triggerBriefingGeneration():
func triggerBriefingGeneration() {
    let date = Date()
    
    // Check BOTH memory AND persistent snapshot
    if let existing = self.currentBriefing,
       Calendar.current.isDate(existing.date, inSameDayAs: date)
    {
        return
    }
    
    if let snapshot = self.historicalService.getSnapshot(for: date),
       snapshot.briefing != nil {
        self.currentBriefing = snapshot.briefing  // Restore from snapshot
        return
    }
    
    // ... rest of generation logic
}
```

---

#### 3. **`WakeTimePredictor` Has Invalid Swift Syntax (Dead Code)**

**Severity**: CRITICAL — Unreliable A/B Variant  
**File**: `Logic/NotificationTimingABTest.swift:250–260`

```swift
// ❌ BUG: .map returns [Int?], not Optional[Array]
if let stored = userDefaults.string(forKey: key),
   let components = stored.split(separator: ":").map({ Int($0) }),  // ❌ Invalid!
   components.count == 2 {
    return (components[0], components[1])
}
```

**Issue**: `split().map { Int($0) }` returns `[Int?]` (array of optionals), **not** `Optional[Array]`. The conditional binding is invalid Swift and should NOT compile.

**Impact**:
- "Adaptive wake time" variant silently falls back to default (7:00 AM)
- A/B test variance artificially reduced
- No actual personalization despite framework promises

**Fix**:
```swift
static func predictWakeTime(for userId: String) -> (hour: Int, minute: Int) {
    let userDefaults = UserDefaults.standard
    let key = "user_wake_time_\(userId)"
    
    if let stored = userDefaults.string(forKey: key) {
        let components = stored.split(separator: ":").compactMap { Int($0) }
        if components.count == 2, let hour = components.first, let minute = components.last {
            return (hour, minute)
        }
    }
    
    // Default: 7:00 AM
    return (7, 0)
}
```

**Add Test**:
```swift
func test_predictWakeTime_parsesValidFormat() {
    let defaults = UserDefaults(suiteName: "test")!
    defaults.set("6:30", forKey: "user_wake_time_user123")
    
    let time = WakeTimePredictor.predictWakeTime(for: "user123")
    XCTAssertEqual(time.hour, 6)
    XCTAssertEqual(time.minute, 30)
}
```

---

#### 4. **`generateDailyBriefing` Cloud Function Has No Authentication Gate**

**Severity**: CRITICAL — Security + Abuse  
**File**: `functions/index.js:361–366`

```javascript
// ❌ BUG: Accepts anonymous requests, burns quota
exports.generateDailyBriefing = onCall({ secrets: [geminiApiKey] }, async (request) => {
    const userId = request.auth?.uid || 'anonymous';  // ❌ Falls back to 'anonymous'!
    await BriefingPerformanceMetrics.logGenerationStart(userId);
    
    const userData = request.data.userData;  // No auth check before processing!
```

**Impact**:
- **Cost/Abuse**: Arbitrary clients can trigger briefing generation → burn Gemini quota
- **Privacy**: Arbitrary user wellness data processed without verification
- **Metrics Pollution**: Firestore `briefing_metrics` filled with anonymous logs
- **Rate Limiting**: No per-user throttling

**Fix**:
```javascript
exports.generateDailyBriefing = onCall({ secrets: [geminiApiKey] }, async (request) => {
    // MUST authenticate before doing ANY work
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 
            'User must be authenticated to generate briefings');
    }
    
    const userId = request.auth.uid;
    
    // Optional: Consider App Check for mobile clients
    // const appCheckToken = request.appCheck?.token;
    
    const userData = request.data.userData;
    // ... rest of function
});
```

---

#### 5. **Notification Identifier: UUID-Based Schedule, Fixed ID Cancel → Orphaned Notifications**

**Severity**: CRITICAL — Broken Wiring  
**Files**: `Logic/NotificationTimingABTest.swift:186–189` + `NotificationManager.swift:123–126`

**Issue**: Notifications are scheduled with random UUIDs but cancelled by fixed ID:

```swift
// ❌ In NotificationTimingABTest (scheduling):
let request = UNNotificationRequest(
    identifier: UUID().uuidString,  // ❌ Random UUID every time!
    content: content,
    trigger: trigger
)

// ❌ In NotificationManager (cancellation):
func cancelBriefingNotification() {
    UNUserNotificationCenter.current()
        .removePendingNotificationRequests(
            withIdentifiers: ["morning_briefing"]  // ❌ Wrong ID!
        )
}
```

**Impact**:
- `cancelBriefingNotification()` NEVER actually cancels (orphaned notifications)
- Duplicate notifications pile up if app calls schedule twice
- API dead code
- User may receive multiple notifications per day

**Fix**:
```swift
// ✅ Use stable identifier
private static let briefingNotificationId = "morning_briefing"

static func scheduleNotification(
    headline: String,
    variant: NotificationTimingVariant,
    userId: String,
    for targetDate: Date = Date()
) -> Date? {
    let scheduler = NotificationScheduler()
    
    switch variant {
    case .fixed_730am:
        return scheduler.scheduleFixed(
            headline: headline, 
            at: (7, 30),
            identifier: Self.briefingNotificationId  // ✅ Stable ID
        )
    // ... etc
}

// In NotificationManager:
func cancelBriefingNotification() {
    UNUserNotificationCenter.current()
        .removePendingNotificationRequests(
            withIdentifiers: [NotificationTimingABTest.briefingNotificationId]
        )
}
```

---

### 🟠 HIGH-PRIORITY ISSUES

#### 6. **Briefing Ignores HealthKit Sleep Data (Missing Parity with Insights)**

**Severity**: HIGH — Reduced Quality  
**File**: `ViewModels/MainViewModel+Insights.swift:106–117`

**Issue**: `generateBriefing()` does NOT accept or pass HealthKit sleep data, unlike `generateInsight()`:

```swift
// ❌ In triggerBriefingGeneration():
Task {
    if let briefing = await self.insightService.generateBriefing(for: date) {
        // NO HealthKit data passed!
    }
}

// ✅ Compare in triggerInsightGenerationIfNeeded():
let healthKitSleepData = await self.fetchHealthKitSleepDataForInsights(relativeTo: date)
if let insight = try await self.insightService.generateInsight(
    for: date,
    healthKitSleepData: healthKitSleepData  // ✅ Data included
)
```

**Impact**:
- Server briefing prompt receives weaker signal (subjective sleep only)
- Undermines "Next-Day Insight" quality vs. internal insights
- Asymmetry in data pipeline (maintenance headache)

**Fix**:
```swift
func triggerBriefingGeneration() {
    let date = Date()
    
    // ... existing checks ...
    
    Task {
        // NEW: Fetch HealthKit data first
        let healthKitSleepData = await self.fetchHealthKitSleepDataForInsights(relativeTo: date)
        
        if let briefing = await self.insightService.generateBriefing(
            for: date,
            healthKitSleepData: healthKitSleepData  // ✅ Pass data
        ) {
            self.currentBriefing = briefing
            self.historicalService.updateBriefing(for: date, briefing: briefing)
            
            let userId = Auth.auth().currentUser?.uid ?? "unknown"
            NotificationManager.shared.scheduleBriefingNotification(
                headline: briefing.headline,
                userId: userId
            )
        }
    }
}
```

---

### 🟡 MEDIUM-PRIORITY ISSUES

#### 7. **Briefing Payload Missing `eveningMindCheck` (Integration Gap)**

**Severity**: MEDIUM — Incomplete Data  
**File**: `Logic/InsightGenerationService.swift:557–566`

**Issue**: `generateBriefingFromServer` stops after morning mind check but never attaches `eveningMindCheck`:

```swift
// ❌ In generateBriefingFromServer():
if let morning = snapshot.morningMindCheck, !morning.isEmpty {
    data["morningMindCheck"] = morning.map { ... }
}

return data  // ❌ No eveningMindCheck! Compare with generateInsightFromServer which includes it
```

**Impact**:
- Cloud prompt never sees evening reflections
- Weaker "end-of-day" context for briefing narrative
- Inconsistent vs. insight pipeline

**Fix**:
```swift
// Add after morning check:
if let evening = snapshot.eveningMindCheck, !evening.isEmpty {
    data["eveningMindCheck"] = evening.map { entry in
        return ["text": entry.text, "category": entry.category.displayName]
    }
}
```

---

#### 8. **`getBriefingMetrics` Exposes Aggregate Data to Any Signed-In User (Info Disclosure)**

**Severity**: MEDIUM — Security  
**File**: `functions/index.js:542–547`

```javascript
// ⚠️ ISSUE: Any authenticated user can view operational metrics
exports.getBriefingMetrics = onCall(async (request) => {
    // Comment says "optional: Verify admin" but never enforces!
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    // Returns aggregated counts, latency distributions, unique user counts
    return metrics;  // ❌ No admin check!
});
```

**Impact**:
- Info disclosure: latency distributions, event counts, unique user totals
- Competitive intelligence (growth metrics)
- Should be admin-only or removed from client surface

**Fix**:
```javascript
exports.getBriefingMetrics = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 
            'User must be authenticated');
    }
    
    // NEW: Check admin custom claim
    const idToken = await admin.auth().verifyIdToken(request.auth.token);
    if (idToken.admin !== true) {
        throw new HttpsError('permission-denied', 
            'Only admins can view briefing metrics');
    }
    
    const daysBack = request.data.daysBack || 7;
    // ... rest of function
});
```

---

#### 9. **A/B Variant Assignment Uses Unordered Dictionary (Non-Deterministic Split)**

**Severity**: MEDIUM — Test Validity  
**File**: `Logic/NotificationTimingABTest.swift:75–87`

```swift
// ⚠️ ISSUE: Dictionary iteration order is not guaranteed
private static func _assignVariant() -> NotificationTimingVariant {
    let rand = Double.random(in: 0..<1.0)
    var cumulative: Double = 0
    
    for (variant, probability) in Self.variant_distribution {  // ❌ Unordered!
        cumulative += probability
        if rand < cumulative {
            return variant
        }
    }
    
    return .fixed_730am
}

private static let variant_distribution = [
    NotificationTimingVariant.fixed_730am: 0.50,
    NotificationTimingVariant.adaptive_wakeTime: 0.25,
    NotificationTimingVariant.smartDelay_2min: 0.25
]
```

**Impact**:
- 50/25/25 distribution may not hold (could skew to 55/20/25, etc.)
- Iteration order may differ across Swift versions/platforms
- A/B test validity compromised
- Hard to debug

**Fix**:
```swift
// Use ordered array instead of dictionary
private static let variant_weights: [(NotificationTimingVariant, Double)] = [
    (.fixed_730am, 0.50),
    (.adaptive_wakeTime, 0.25),
    (.smartDelay_2min, 0.25)
]

private static func _assignVariant() -> NotificationTimingVariant {
    let rand = Double.random(in: 0..<1.0)
    var cumulative: Double = 0
    
    for (variant, probability) in Self.variant_weights {  // ✅ Ordered!
        cumulative += probability
        if rand < cumulative {
            return variant
        }
    }
    
    return .fixed_730am
}
```

---

#### 10. **Briefing Generation Silent Failure (No Client-Side Logging)**

**Severity**: MEDIUM — Poor Observability  
**File**: `Logic/InsightGenerationService.swift:608–612`

```swift
// ⚠️ ISSUE: Silent failure in catch block
} catch {
    return nil  // ❌ No logging! Harder to debug prod issues
}
```

**Impact**:
- No device-side logging of generation failures
- Harder to diagnose production issues vs. network timeout
- Contrast: Server has structured metrics logging

**Fix**:
```swift
} catch {
    let logger = Logger(subsystem: "com.yogaofeating", category: "InsightGeneration")
    logger.error("Briefing generation failed: \(error.localizedDescription, privacy: .public)")
    
    // Optional: Emit client-side analytics event for monitoring
    // AnalyticsManager.logBriefingGenerationError(error)
    
    return nil
}
```

---

#### 11. **Debug UI Shipped in Production (NotificationTimingABTestView)**

**Severity**: MEDIUM — Code Cleanliness  
**File**: `Logic/NotificationTimingABTest.swift:278–337`

```swift
// ⚠️ DEBUG UI in production code
struct NotificationTimingABTestView: View {
    @State private var selectedVariant = NotificationTimingVariant.fixed_730am
    // ... full debug UI ...
}
```

**Impact**:
- Increases surface area (debug buttons leaking into Release builds)
- Confuses users if accidentally accessible
- Should be #if DEBUG gated or moved to developer settings

**Fix**:
```swift
#if DEBUG
struct NotificationTimingABTestView: View {
    // ... existing UI ...
}
#endif

// Or move to a DebugSettings target
```

---

#### 12. **Magic Numbers Scattered Across Correlation Logic**

**Severity**: MEDIUM — Maintainability  
**Files**: `Logic/PatternAnalyzer.swift`, `Logic/InsightGenerationService.swift`

**Examples**:
- `0.15` (line 231), `0.1` (line 241), `5.5` (line 313), `0.7` (line 284), `0.6` (line 340)
- No single SSOT for thresholds

**Impact**:
- Hard to adjust sensitivity across codebase
- Inconsistent tuning vs. `ScoringThresholds` (which you already use elsewhere)
- Risk of divergence between insights & briefing confidence

**Fix**:
```swift
// Add to a new "BriefingThresholds" or extend existing ScoringThresholds
struct BriefingThresholds {
    static let minCorrelationConfidence = 0.60      // Emit cards >= 0.6
    static let goodCorrelationConfidence = 0.70     // High-confidence card
    static let minDataPoints = 5
    static let timingConsistencyThreshold = 5.5     // Hours std dev
    static let foodScoreDelta = 0.15                // Food score drop threshold
    static let focusThreshold = 0.7
    // ... more
}
```

---

#### 13. **Force-Unwrapped Calendar Math (Crash Risk)**

**Severity**: MEDIUM — Defensive Programming  
**File**: `Logic/PatternAnalyzer.swift` (lines 54–55, 221–223, 330–331)

```swift
// ⚠️ Force unwrap (crash if ever nil)
let dayMinus7 = Calendar.current.date(byAdding: .day, value: -7, to: date)!
```

**Impact**:
- `date(byAdding:)` can theoretically return nil
- App crash if edge case ever triggered (e.g., very old/future dates)

**Fix**:
```swift
guard let dayMinus7 = Calendar.current.date(byAdding: .day, value: -7, to: date) else {
    return []  // Or log warning
}
```

---

#### 14. **`print()` Logging Scattered (May Leak Wellness Data)**

**Severity**: MEDIUM — Security/Cleanliness  
**File**: `Logic/InsightGenerationService.swift` (lines 147–213, 337–379)

```swift
// ⚠️ print() statements in prod code
print("[PERF] Briefing generation started for user...")
print("[PERF] Correlation confidence:")
```

**Impact**:
- Noisy console output
- Wellness data snippets may leak to device logs
- Hard to control in Release builds

**Fix**:
```swift
let logger = Logger(subsystem: "com.yogaofeating", category: "Briefing")
logger.info("Briefing generation started (user: \(userId, privacy: .private))")
```

---

### 🟢 LOW-PRIORITY IMPROVEMENTS

#### 15. **`analyzePatterns` vs `generateCorrelationCards` Divergent Pipelines**

**Severity**: LOW — Tech Debt  
**Issue**: Two separate correlation detectors (legacy vs. new) with overlapping logic.

**Recommendation**: Document difference, or consolidate into single pipeline for future sprint.

---

#### 16. **Semantic Mismatch: `focusToFeeling` Category**

**Severity**: LOW — UI Taxonomy  
**Issue**: `analyzeTodoProductivity` emits `CorrelationCategory.focusToFeeling`, but the insight is about **todo completion vs meal quality**.

**Fix**: Clarify naming or add `.todoCompletion` category if needed.

---

## Remediation Plan (Phased)

### **PHASE A: Ship Blockers** (Before Production) — *1–2 days*

| Priority | Issue | Fix | Est. Time | Risk |
|----------|-------|-----|-----------|------|
| P0 | Struct mutation (Issue #1) | Copy-mutate-assign pattern | 30 min | LOW |
| P0 | Cold start (Issue #2) | Hydrate `currentBriefing` on load | 45 min | LOW |
| P0 | Wake time parsing (Issue #3) | Fix compactMap + add tests | 30 min | LOW |
| P0 | Missing auth gate (Issue #4) | Add `request.auth` check | 15 min | LOW |
| P0 | Notification ID (Issue #5) | Use stable UUID | 30 min | LOW |

**Total**: ~2.5 hours, 5 tests to add  
**Blockers**: All must pass before deployment  
**Testing**: Add unit tests for each fix (dataflow, auth, parsing, notifications)

---

### **PHASE B: Quality + Parity** (Parallel with next sprint) — *4–6 hours*

| Issue | Fix | Est. Time | Owner |
|-------|-----|-----------|-------|
| #6 (HealthKit) | Pass sleep data to `generateBriefing` | 1 hour | iOS |
| #7 (Evening check) | Add `eveningMindCheck` to briefing payload | 30 min | iOS |
| #9 (Dict ordering) | Use ordered array for variant weights | 30 min | iOS |
| #10 (Silent fail) | Add OSLog to briefing generation | 30 min | iOS |
| #8 (Info disclosure) | Require admin claim on `getBriefingMetrics` | 30 min | Backend |

**Total**: ~4 hours  
**Can start**: After Phase A ships  
**Testing**: Integration tests for new data flows

---

### **PHASE C: Hardening + Tech Debt** (Next sprint planning) — *6–8 hours*

| Issue | Fix | Est. Time | Owner |
|-------|-----|-----------|-------|
| #11 (Debug UI) | Gate `NotificationTimingABTestView` with `#if DEBUG` | 30 min | iOS |
| #12 (Magic numbers) | Extract `BriefingThresholds` constant | 1.5 hours | iOS |
| #13 (Force unwrap) | Replace with guard statements | 1 hour | iOS |
| #14 (print logging) | Replace with Logger | 1 hour | iOS |
| #15 (Divergent pipelines) | Document or consolidate correlation logic | 2 hours | iOS |
| #16 (Semantics) | Clarify `focusToFeeling` category naming | 30 min | iOS |

**Total**: ~7 hours  
**Dependencies**: Phase A complete  
**Testing**: Comprehensive unit tests for all thresholds, logging paths

---

## Implementation Roadmap

```
TODAY (May 1)
└─ Phase A: Ship Blockers
   ├─ [30 min] Fix struct mutation in MainViewModel+Insights
   ├─ [45 min] Hydrate currentBriefing on loadData()
   ├─ [30 min] Fix WakeTimePredictor parsing + tests
   ├─ [15 min] Add auth check to generateDailyBriefing
   ├─ [30 min] Unify notification identifier
   └─ [2 hours] Testing & sign-off
   └─ DEPLOY (May 2 morning)

WEEK 1 (May 5–9)
└─ Phase B: Quality + Parity (run in parallel with manual testing)
   ├─ Pass HealthKit to generateBriefing
   ├─ Add evening mind check to payload
   ├─ Fix A/B variant distribution
   ├─ Add structured logging to briefing generation
   ├─ Lock down getBriefingMetrics
   └─ Merge to main, deploy to TestFlight

WEEK 2+ (May 12+)
└─ Phase C: Hardening (backlog for next sprint)
   ├─ Extract BriefingThresholds constant
   ├─ Replace force-unwraps & print statements
   ├─ Gate debug UI
   ├─ Consolidate correlation logic
   └─ Full test coverage audit
```

---

## Testing Checklist

### Phase A Tests (Required Before Ship)
- [ ] `test_markBriefingViewed_persistsViewedState`
- [ ] `test_loadData_hydratesTodaysBriefing`
- [ ] `test_triggerBriefingGeneration_skipsIfSnapshotExists`
- [ ] `test_predictWakeTime_parsesValidFormat`
- [ ] `test_predictWakeTime_defaultsOn invalid`
- [ ] `test_generateDailyBriefing_rejectsAnonymousRequests`
- [ ] `test_scheduleBriefingNotification_usesFiveIdentifier`
- [ ] `test_cancelBriefingNotification_cancelsScheduledRequest`

### Phase B Tests
- [ ] `test_generateBriefing_includesHealthKitSleepData`
- [ ] `test_briefingPayload_includesEveningMindCheck`
- [ ] `test_abtestAssignment_maintainsDistribution` (100 runs)
- [ ] `test_generateBriefing_logsErrorOnFailure`
- [ ] `test_getBriefingMetrics_requiresAdminClaim`

### Phase C Tests
- [ ] `test_allCorrelationThresholds_defined`
- [ ] `test_noForceUnwraps_inPatternAnalyzer`
- [ ] `test_noAssertions_inProductionCode`

---

## Sign-Off Checklist

- [ ] All Phase A tests passing
- [ ] Code review on struct mutation & auth fixes
- [ ] Performance benchmarks unchanged (latency, success rate)
- [ ] Manual testing on real device (ref: `MANUAL_TESTING_GUIDE.md`)
- [ ] Firestore metrics logged correctly
- [ ] A/B variant distribution verified (100 assignments)
- [ ] Notification delivery tested on device
- [ ] Product sign-off on quality

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Phase A changes break existing flow | Comprehensive unit tests + integration test on real device |
| Hidden dependencies on struct mutation | Search codebase for `?.markAsViewed()` patterns |
| Auth check breaks existing Cloud Function calls | Gradual rollout, monitor error rates on backend |
| HealthKit data missing in briefing | Ensure fetchHealthKitSleepDataForInsights works in test environment |
| Notification ID change causes orphans | Clear old notifications before deploying new version |

---

## Success Criteria

### Phase A (Ship Blockers)
- ✅ 0 critical issues remaining
- ✅ All 8 unit tests passing
- ✅ Manual smoke test on 2 real devices
- ✅ Briefing card persists after app relaunch
- ✅ Notification cancel works
- ✅ Cloud Function rejects anonymous requests

### Phase B (Quality)
- ✅ Briefing includes HealthKit sleep data
- ✅ A/B distribution stable at 50/25/25 ± 2%
- ✅ Structured logging for all errors
- ✅ 0 new production issues

### Phase C (Hardening)
- ✅ No magic numbers outside `BriefingThresholds`
- ✅ No `print()` statements in prod code
- ✅ All force-unwraps justified or removed
- ✅ Code complexity metrics stable

---

## References

- **CLAUDE.md**: TDD, MVVM, SSOT principles
- **MANUAL_TESTING_GUIDE.md**: Real device validation
- **Code Review Output**: Detailed issue descriptions above

---

**Prepared by**: Code Review Agent  
**Date**: May 1, 2026  
**Status**: Ready for implementation  
**Next Step**: Start Phase A implementation
