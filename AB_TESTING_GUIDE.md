# A/B Testing & Performance Monitoring Guide

## Notification Timing A/B Test

### Objective
Optimize the notification delivery time for daily briefings to maximize user engagement and adoption.

### Test Hypothesis
Different notification timing variants will have different engagement rates:
- **Control (50%)**: Fixed 7:30 AM — catches early risers, traditional breakfast time
- **Variant A (25%)**: Adaptive wake time — personalized based on user patterns
- **Variant B (25%)**: Smart delay 2min — immediately after user logs sleep, while fresh

### Implementation

#### 1. Variant Assignment

Users are automatically assigned to a variant on first briefing generation:

```swift
let variant = NotificationTimingABTest.getCurrentVariant(for: userId)
// Returns one of: fixed_730am, adaptive_wakeTime, smartDelay_2min
```

Assignment is **persistent** per user — stored in UserDefaults to ensure consistency.

Distribution:
- `fixed_730am`: 50% (control baseline)
- `adaptive_wakeTime`: 25% (novelty variant)
- `smartDelay_2min`: 25% (immediate feedback variant)

#### 2. Scheduling Logic

Once assigned, notifications are scheduled based on variant:

```swift
NotificationTimingABTest.scheduleNotification(
    headline: "Your Thursday was balanced…",
    variant: .fixed_730am,    // Or assigned variant
    userId: userId
)
```

**Variant Behaviors**:

| Variant | Behavior | Scheduled Time |
|---------|----------|---|
| `fixed_730am` | Always 7:30 AM UTC | 7:30 AM |
| `adaptive_wakeTime` | User's typical wake time (from HealthKit pattern or default 7:00 AM) | User wake time ±5 min |
| `smartDelay_2min` | 2 minutes after user logs sleep quality | Now + 120 seconds |

#### 3. Logging & Analytics

Every notification scheduling event is logged with metadata:

```swift
NotificationTimingABTest.logNotificationScheduled(
    userId: userId,
    variant: variant,
    scheduledTime: Date()
)
// Logs: event, userId, variant, timestamp
```

Every tap-through is tracked:

```swift
NotificationTimingABTest.logNotificationTapped(
    userId: userId,
    variant: variant,
    delayFromScheduleSeconds: 120  // If user tapped 2min after scheduled time
)
```

---

## Performance Monitoring Dashboard

### Overview

Real-time performance metrics are collected during briefing generation and stored in Firestore for analysis.

### Metrics Collected

#### Generation Performance

| Metric | Description | Source |
|--------|-------------|--------|
| `event: generation_start` | When generation begins for user | Cloud Function entry |
| `event: generation_complete` | When AI returns valid briefing | Gemini API response |
| `event: api_latency` | Gemini model response time (ms) | Cloud Function timing |
| `event: generation_error` | If generation failed, fallback used | Error handler |

#### AI Quality Metrics

| Metric | Description | Range |
|--------|-------------|-------|
| `correlationCardCount` | Number of insight cards generated | 0–3 |
| `averageCorrelationConfidence` | Mean confidence of all cards | 0.0–1.0 |
| `dataQuality` | Assessment of input data | excellent / good / adequate / sparse |
| `headlineLength` | Characters in briefing headline | 0–100 |

### Accessing Metrics

**Via Cloud Function**:

```bash
firebase functions:call getBriefingMetrics \
  --data '{"daysBack": 7}'
```

**Response**:

```json
{
  "period": "Last 7 days",
  "generatedAt": "2026-05-01T09:38:00Z",
  "totalEvents": 842,
  "generationStarts": 120,
  "generationCompletes": 115,
  "generationErrors": 5,
  "uniqueUsers": 48,
  "successRate": "95.83%",
  "averageCorrelationConfidence": 0.72,
  "dataQualityDistribution": {
    "excellent": 45,
    "good": 50,
    "adequate": 18,
    "sparse": 2
  },
  "apiLatencyStats": {
    "count": 115,
    "min": 1250,
    "max": 8900,
    "median": 3200,
    "p95": 6500,
    "average": 3600
  }
}
```

### Key Performance Indicators (KPIs)

#### 1. Generation Success Rate
**Target**: >95%

```
successRate = (completions / starts) * 100
```

- If <95%: Investigate error logs
- Common issues: API quota, invalid input data, timeout

#### 2. API Latency (p95)
**Target**: <6 seconds

```
p95 latency = 95th percentile of Gemini response times
```

- If >6s: Check Gemini quota or model overload
- Optimization: Consider `gemini-2.5-flash-lite` for faster responses

#### 3. Average Correlation Confidence
**Target**: 0.65–0.85

```
confidence = sum(cardConfidence) / cardCount
```

- If <0.65: Users may not have enough data yet; suggest logging more meals
- If >0.85: Excellent data quality; potentially ready for A/B variants

#### 4. Data Quality Distribution
**Target**: >70% "excellent" + "good"

```
goodData% = (excellent + good) / total * 100
```

- If <70%: Need to encourage users to log more diverse data
- Sparse data: Users logging <3 days/week

---

## Monitoring Dashboard Setup (Optional)

### Firestore Query for Dashboard

Create a real-time dashboard to monitor metrics:

```javascript
// Dashboard: Retrieve last 24 hours of generation events
db.collection('briefing_metrics')
  .where('timestamp', '>=', Date.now() - (24 * 60 * 60 * 1000))
  .where('event', '==', 'generation_complete')
  .orderBy('timestamp', 'desc')
  .limit(100)
  .onSnapshot(snapshot => {
    const events = snapshot.docs.map(doc => doc.data());
    updateDashboard(events);
  });
```

### Example Dashboard Metrics Display

```
┌─────────────────────────────────────────┐
│ Daily Briefing Performance Dashboard     │
├─────────────────────────────────────────┤
│ Last 24 Hours                           │
│                                         │
│ ✅ Success Rate:        96.2% (51/53)  │
│ ⏱️  API Latency (p95):   5.2s          │
│ 🎯 Avg Confidence:       0.73          │
│ 📊 Data Quality:         76% good+     │
│                                         │
│ 🔴 Errors (24h):         2             │
│ ⚠️  Slow Calls (>8s):    1             │
│ 💾 Unique Users:         38            │
└─────────────────────────────────────────┘
```

---

## A/B Test Results Interpretation

### After 1–2 Weeks (100+ users per variant)

**Expected Metrics to Track**:

1. **Notification Delivery Success Rate**
   - Target: >95% of notifications delivered
   - If lower: Check OS-level notification limits or quiet hours

2. **Tap-Through Rate (CTR)**
   - Control (7:30 AM): Baseline expected ~20–30%
   - Adaptive: Expected ±5–15% variance from control
   - Smart Delay: Expected +10–30% (higher engagement due to recency)

3. **Time to Tap**
   - Control: Average 5–30 minutes after notification
   - Adaptive: Expected similar to control
   - Smart Delay: Expected <5 minutes (user just logged data)

4. **App Session Duration**
   - Track if users spend longer in the app after tapping
   - Compare by variant

### Statistical Significance

Use this simple formula to check if differences are meaningful:

```
Sample size needed for 80% power, 5% significance:
n = 2 * (Z_α + Z_β)² * (p₁(1-p₁) + p₂(1-p₂)) / (p₁ - p₂)²

Example: If control CTR is 25% and we want to detect a 5% absolute difference:
n ≈ 308 users per variant (924 total)
```

Run for **1–2 weeks** to gather ~300+ samples per variant.

---

## Monitoring Checklist

### Daily (Operations)
- [ ] Check `successRate` — should be >95%
- [ ] Check `apiLatencyStats.p95` — should be <6s
- [ ] Review error logs for patterns
- [ ] Verify Gemini API quota usage

### Weekly (Product)
- [ ] Calculate CTR per variant
- [ ] Compare average time-to-tap
- [ ] Measure app session duration by variant
- [ ] Review data quality trends

### End-of-Test (Analysis)
- [ ] Calculate statistical significance (p-value)
- [ ] Identify winner variant
- [ ] Rollout winner to 100% of users
- [ ] Archive metrics in report

---

## Implementation Checklist

### ✅ Deployment
- [ ] Cloud Function `generateDailyBriefing` deployed with monitoring
- [ ] `briefingPerformanceMonitor.js` in functions directory
- [ ] `getBriefingMetrics` Cloud Function available
- [ ] Firestore collection `briefing_metrics` initialized

### ✅ iOS App
- [ ] `NotificationTimingABTest.swift` implemented
- [ ] `NotificationManager.scheduleBriefingNotification(headline:userId:)` updated
- [ ] `MainViewModel+Insights.swift` passes `userId` to notification scheduler
- [ ] A/B variant persisted in UserDefaults per user

### ✅ Analytics
- [ ] Logging events captured: `generation_start`, `generation_complete`, `api_latency`, `generation_error`
- [ ] Notification tap events logged with variant
- [ ] Performance dashboard accessible (Firestore queries)

### ✅ Testing
- [ ] Manual test: Verify notification appears at correct time per variant
- [ ] Manual test: Verify metrics logged to Firestore
- [ ] Performance test: Gemini latency <8s under load
- [ ] Error handling: App doesn't crash if notification fails

---

## Troubleshooting

### Notifications Not Arriving

**Checklist**:
1. Verify iOS permission granted: Settings → Notifications → Yoga of Eating → Allow ✓
2. Check device time is correct (NTP synced)
3. Verify Firestore metrics show `generation_complete` event
4. Check if app is in foreground (notifications suppressed)

### High Latency (p95 > 8s)

**Causes & Fixes**:
- Gemini API rate limited: Wait 60s before retrying
- Model overloaded: Downgrade to `gemini-2.5-flash-lite`
- Network issue: Implement exponential backoff
- Large input: Limit userData to 7 days max

### Low Correlation Confidence (<0.65)

**Causes**:
- Sparse data: User logged <5 meals/week
- Inconsistent data: All meals identical, sleep always 8h
- Random variation: Normal with small datasets

**Mitigations**:
- Show in-app nudge: "Log more meals for better insights"
- Lower confidence threshold in prompt: Accept 0.5+ confidence

### A/B Test Not Splitting Correctly

**Debug**:
```swift
// Check variant assignment
let variant = NotificationTimingABTest.getCurrentVariant(for: "test-user")
print("Assigned variant: \(variant.rawValue)")  // Should vary across users

// Check distribution
let users = ["user1", "user2", ..., "user100"]
var dist = [String: Int]()
users.forEach { userId in
    let v = NotificationTimingABTest.getCurrentVariant(for: userId)
    dist[v.rawValue, default: 0] += 1
}
print(dist)  // Should be roughly [fixed_730am: 50, adaptive: 25, smartDelay: 25]
```

---

## Success Criteria

After running the A/B test for 1–2 weeks, consider the test successful if:

1. ✅ **No crashes** during notification scheduling
2. ✅ **>90% of notifications delivered** successfully
3. ✅ **Statistically significant difference** detected in CTR (p < 0.05)
4. ✅ **Clear winner** identified (highest CTR + engagement)
5. ✅ **Actionable insights** from time-to-tap and session duration

### Next Steps After Test
1. **Declare winner**: Rollout top variant to all new users
2. **Sunset variants**: Deprecate underperforming variants after 2 weeks
3. **Iterate**: Use learnings for next A/B test (e.g., headline phrasing)
4. **Monitor**: Continue tracking KPIs for the winning variant

---

## Additional Resources

- **Cloud Functions Logging**: `gcloud functions logs read generateDailyBriefing --limit 100`
- **Firestore Metrics Query**: Use Firebase Console → Firestore → `briefing_metrics` collection
- **A/B Test Variant Check**: Set UserDefaults key `user_wake_time_<userId>` to override wake time
- **Reset Test**: Call `NotificationTimingABTest.resetVariantForUser(_:)` to reassign variant

---

**Test Owner**: ________________  
**Start Date**: ________________  
**End Date**: ________________  
**Winner**: ________________  
