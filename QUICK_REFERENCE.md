# Quick Reference: Daily Briefing Deployment & A/B Testing

## 🚀 Cloud Functions

### All Deployed Functions (Verified Active)
```bash
gcloud functions list --project yoga-of-eating

NAME                  STATE   TRIGGER      REGION
generateDailyBriefing ACTIVE  HTTP/Callable us-central1  ← NEW
getBriefingMetrics    ACTIVE  HTTP/Callable us-central1  ← NEW
analyzeMeal           ACTIVE  HTTP/Callable us-central1
getMealInsight        ACTIVE  HTTP/Callable us-central1
generateInsight       ACTIVE  HTTP/Callable us-central1
```

### Monitor Logs
```bash
# Watch briefing generation
gcloud functions logs read generateDailyBriefing --limit 50 --project yoga-of-eating --follow

# Check for errors
gcloud functions logs read generateDailyBriefing --project yoga-of-eating | grep -i error
```

### Call Metrics Dashboard (Authenticated Users Only)
```bash
firebase functions:call getBriefingMetrics --data '{"daysBack": 7}'
```

---

## 📱 iOS Implementation

### Key Files Modified
```
Logic/NotificationTimingABTest.swift      ← NEW: A/B variant assignment & scheduling
Logic/NotificationManager.swift           ← UPDATED: Uses A/B variants
ViewModels/MainViewModel+Insights.swift   ← UPDATED: Passes userId to notifications
```

### Variant Assignment (Always Call First)
```swift
let userId = Auth.auth().currentUser?.uid ?? "unknown"
let variant = NotificationTimingABTest.getCurrentVariant(for: userId)
// Returns: .fixed_730am (50%) | .adaptive_wakeTime (25%) | .smartDelay_2min (25%)
```

### Schedule Briefing Notification
```swift
// In MainViewModel+Insights.triggerBriefingGeneration():
NotificationManager.shared.scheduleBriefingNotification(
    headline: briefing.headline,
    userId: userId  // ← REQUIRED for A/B test variant
)
```

---

## 📊 Performance Monitoring

### Monitor KPIs (7-Day Summary)
```bash
firebase functions:call getBriefingMetrics --data '{"daysBack": 7}'
```

**Response Contains**:
- `successRate`: % of completions / starts (target >95%)
- `averageCorrelationConfidence`: 0.0–1.0 (target 0.65–0.85)
- `apiLatencyStats.p95`: Gemini response time in ms (target <6s)
- `dataQualityDistribution`: excellent/good/adequate/sparse counts

### Firestore Metrics Collection
```
briefing_metrics/
  ├── {doc} event: "generation_start"
  │        userId: "user-123"
  │        timestamp: 1714551480000
  │
  ├── {doc} event: "generation_complete"
  │        userId: "user-123"
  │        correlationCardCount: 2
  │        averageCorrelationConfidence: 0.74
  │        dataQuality: "good"
  │
  ├── {doc} event: "api_latency"
  │        durationMs: 3200
  │        modelUsed: "gemini-2.5-flash"
  │
  └── {doc} event: "generation_error"
           errorMessage: "..."
           fallbackUsed: true
```

---

## 🧪 A/B Test Variants

### Variant Details

| Variant | Probability | Scheduled Time | Use Case |
|---------|------------|---|---|
| **fixed_730am** | 50% (Control) | 7:30 AM daily | Baseline, traditional timing |
| **adaptive_wakeTime** | 25% (Variant A) | User wake time ±5min | Personalized, data-driven |
| **smartDelay_2min** | 25% (Variant B) | Now + 120 seconds | Immediate engagement |

### Check User's Variant
```swift
let variant = NotificationTimingABTest.getCurrentVariant(for: "user-123")
print(variant.rawValue)  // "fixed_730am", "adaptive_wakeTime", or "smartDelay_2min"
```

### Reset Variant (Testing Only)
```swift
NotificationTimingABTest.resetVariantForUser("user-123")
// Next call to getCurrentVariant() will reassign
```

### Log Engagement
```swift
NotificationTimingABTest.logNotificationTapped(
    userId: "user-123",
    variant: .fixed_730am,
    delayFromScheduleSeconds: 120
)
```

---

## 📋 Testing Checklist

### Manual Testing (Follow MANUAL_TESTING_GUIDE.md)
```
Phase 1: Build test data (3–5 days)
  □ Log 3 meals/day
  □ Log sleep quality each morning
  □ Log mood/focus in Reflect tab
  
Phase 2: Trigger briefing
  □ Log sleep quality → awaits briefing generation
  □ Wait 3–8 seconds
  
Phase 3: Validate content
  □ Briefing card appears on main screen
  □ Headline is specific to user's data
  □ Correlations cards present
  □ Nudge is actionable
  
Phase 4: Real HealthKit data
  □ Apple Watch sleep syncs correctly
  □ Briefing mentions both subjective & objective sleep
  □ Sleep-to-meal correlations detected
  
Phase 5: Performance monitoring
  □ Generation completes within 3–8s
  □ No crashes or memory leaks
  □ Metrics logged to Firestore
  
Phase 6: Notification A/B test
  □ Notification arrives at scheduled time
  □ Tapping notification opens briefing detail view
  □ Engagement events logged
```

### Performance Targets
- ✅ Generation: <8 seconds (p95)
- ✅ Success rate: >95%
- ✅ Confidence: 0.65–0.85 average
- ✅ Notifications: >95% delivered
- ✅ CTR: >20% baseline, measure variance by variant

---

## 🔧 Troubleshooting

### Briefing Not Appearing
```bash
# 1. Check Cloud Function logs
gcloud functions logs read generateDailyBriefing --project yoga-of-eating

# 2. Verify user has logged sleep
# (required trigger for briefing generation)

# 3. Check Firestore briefing_metrics collection
# Should see "generation_complete" event for user

# 4. Fallback active? Check for "generation_error" event
```

### Slow Briefing Generation (>8s)
```bash
# Check p95 latency
firebase functions:call getBriefingMetrics --data '{"daysBack": 1}' | grep p95

# If >8s, check:
# 1. Gemini API quota (Google Cloud Console)
# 2. Network latency to us-central1
# 3. Consider downgrading to gemini-2.5-flash-lite
```

### Notification Not Received
```bash
# 1. Check iOS notification permission
#    Settings → Notifications → Yoga of Eating → Allow

# 2. Verify device time (NTP synced)

# 3. Check variant assignment
let variant = NotificationTimingABTest.getCurrentVariant(for: uid)
print("Assigned: \(variant.rawValue)")

# 4. Check Firestore notification_events logs
```

### A/B Test Distribution Off
```bash
# Query Firestore to check variant distribution
# Select from briefing_metrics where event == "generation_complete"
# Group by variant, count users

# Expected:
# fixed_730am: ~50%
# adaptive: ~25%
# smartDelay: ~25%

# If skewed, check:
# 1. Random number generator seeding
# 2. UserDefaults cache clearing
# 3. User device time zone
```

---

## 📈 A/B Test Execution Timeline

### Week 1: Setup & Validation
- [ ] Deploy Cloud Functions
- [ ] Run manual tests on 3–5 devices
- [ ] Verify metrics logging to Firestore
- [ ] Confirm all 3 variants scheduling correctly

### Week 2–3: A/B Test Running
- [ ] Monitor daily KPIs
- [ ] Calculate CTR per variant
- [ ] Check for statistical significance
- [ ] Adjust sampling if needed

### Week 4: Analysis & Rollout
- [ ] Declare winner variant (highest CTR + engagement)
- [ ] Rollout winner to 100% of users
- [ ] Archive test data and metrics
- [ ] Plan next A/B test iteration

---

## 💾 Important Firestore Collections

### briefing_metrics
Events logged by Cloud Functions during briefing generation
```
event:                    generation_start | generation_complete | api_latency | generation_error
userId:                   string
timestamp:                number (unix ms)
correlationCardCount:     number (if complete)
averageConfidence:        number 0.0–1.0 (if complete)
durationMs:               number (if latency)
errorMessage:             string (if error)
dataQuality:              "excellent" | "good" | "adequate" | "sparse"
```

### notification_events (Manual logging in iOS app)
```
event:                    briefing_notification_scheduled | briefing_notification_tapped
userId:                   string
variant:                  fixed_730am | adaptive_wakeTime | smartDelay_2min
scheduledTime:            ISO8601 string (if scheduled)
delaySeconds:             number (if tapped)
timestamp:                ISO8601 string
```

---

## 🔐 Environment Setup

### Required Secrets
```bash
# Google Cloud Secret Manager
gcloud secrets list --project yoga-of-eating

NAME            CREATED              REPLICATION_POLICY
GEMINI_API_KEY  2025-12-28T12:04:46  automatic
```

### Required APIs Enabled
```bash
gcloud services list --project yoga-of-eating --enabled | grep -E "cloudfunctions|secretmanager|firestore|generative"

cloudfunctions.googleapis.com         ENABLED
secretmanager.googleapis.com          ENABLED
firestore.googleapis.com              ENABLED
aiplatform.googleapis.com             ENABLED (Gemini API)
```

---

## 📚 Documentation Files

| File | Purpose | Audience |
|------|---------|----------|
| `POST_SPRINT_DEPLOYMENT_SUMMARY.md` | Executive overview, architecture | Product, Eng Leads |
| `MANUAL_TESTING_GUIDE.md` | Step-by-step testing playbook | QA, Testers |
| `AB_TESTING_GUIDE.md` | A/B test hypothesis, execution, analysis | Product, Data Analysts |
| `functions/briefingPerformanceMonitor.js` | Monitoring module implementation | Backend Eng |
| `Logic/NotificationTimingABTest.swift` | A/B variant logic | iOS Eng |

---

## 🎯 Quick Command Reference

```bash
# Deploy functions
cd /Users/sunil/Downloads/YogaofEating
npx firebase-tools@latest deploy --only functions

# Monitor briefing generation
gcloud functions logs read generateDailyBriefing --project yoga-of-eating --follow

# Get 7-day KPIs
firebase functions:call getBriefingMetrics --data '{"daysBack": 7}'

# List all functions
gcloud functions list --project yoga-of-eating

# Check Gemini API quota
gcloud compute project-info describe --project yoga-of-eating | grep compute

# Reset user A/B test (developer only)
# Run in Firebase Console: 
# db.collection('briefing_metrics').where('userId', '==', 'USER_ID').delete()
```

---

## 📞 Support Contacts

- **Cloud Functions Issues**: Firebase Support, GCP Console
- **Gemini API Issues**: Google AI Support
- **iOS Issues**: Apple Developer Forums
- **A/B Test Design**: Data Science team

---

**Last Updated**: May 1, 2026  
**Status**: ✅ PRODUCTION READY  
**Version**: 1.0
