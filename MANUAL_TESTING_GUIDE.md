# Manual Testing Guide: Daily Briefing System with Real HealthKit Data

## Overview
This guide walks through manual testing of the newly deployed Daily Briefing system on a real iOS device. The briefing leverages real HealthKit sleep data, real meal logging, and real-time mood/focus tracking to generate personalized insights.

## Prerequisites

### Device Requirements
- **iOS Device**: iPhone 12 or newer (running iOS 17+)
- **HealthKit App**: Must be installed and configured
- **Apple Watch** (optional but recommended): For real objective sleep data
- **Xcode**: Latest version with iOS deployment capability

### HealthKit Setup on Device
Before testing, ensure HealthKit permissions and data sources are configured:

1. **Open the Health app** on your iPhone
2. **Enable HealthKit** if not already active
3. **Grant App Permissions**:
   - Open Health app → Profile icon (top right) → Apps
   - Find "Yoga of Eating" and grant permissions for:
     - Sleep data (Read/Write)
     - Steps and other activity data (Read)
4. **Populate Sleep Data** (if using Apple Watch):
   - Wear Apple Watch and ensure "Sleep Focus" is enabled
   - Sleep data syncs automatically overnight
   - Verify data is visible in Health app: Sleep tab
5. **Manual Sleep Entry** (if no Apple Watch):
   - Health app → Sleep → Add Data
   - Enter yesterday's sleep: start time, end time, quality

### Test Account Setup
- **Firebase Auth**: Already configured for `yoga-of-eating` project
- **User authenticated**: App must have a valid Firebase user session
- **Empty historical data** (optional): For clean testing, consider starting fresh

---

## Testing Workflow

### Phase 1: Data Logging (3–5 days of preparation)

The briefing engine needs **at least 2–3 days of data** to detect meaningful patterns. Build a realistic dataset:

#### Day 1: Breakfast & Sleep Logging
1. **Launch Yoga of Eating app** on device
2. **Tap "Highlight" tab** → Add food for breakfast (e.g., "Oatmeal with berries and yogurt")
3. **Tap "Energise" tab** → Log 2–3 meals throughout the day
   - Breakfast: ~8:00 AM (high-protein option)
   - Lunch: ~12:30 PM (balanced)
   - Dinner: ~6:30 PM (lighter option)
4. **Tap "Reflect" tab**:
   - Log afternoon focus score: ~7/10
   - Log evening feeling: "Productive and calm"
5. **Save and exit app**
6. **Next morning**:
   - Tap "Reflect" → Log last night's sleep quality
   - If Apple Watch: Verify auto-populated sleep metrics are visible
   - Tap "Reflect" → Log morning mood/energy

#### Day 2–3: Build Correlations
Repeat the pattern but vary one variable each day to create detectable correlations:
- **Day 2**: Skip breakfast, light lunch, see if afternoon focus drops
- **Day 3**: Eat high-protein breakfast, monitor afternoon energy boost

**Example correlation the engine should detect**:
- "Your high-protein breakfast on Day 3 correlated with a 40% boost in afternoon focus compared to Day 2's skipped breakfast."

#### Day 4–5: Complete a Full Week
- Continue logging meals (3 per day minimum)
- Log sleep quality each morning
- Include at least one "off day" (lower nutrition, poor sleep)
- Ensure diversity in meal types (high protein, carb-heavy, light, heavy)

---

### Phase 2: Trigger Briefing Generation

Once you have 3–7 days of logged data:

1. **Log sleep quality for the current morning** via the "Reflect" tab
   - This triggers `saveSleepQuality()` → `triggerBriefingGeneration()`
2. **Wait 5–10 seconds** for the async call to complete
3. **Verify in the app**:
   - Check if `MorningBriefingCard` appears at the top of the main screen
   - Card should display: headline, top correlation, nudge, "NEW" badge if unviewed
4. **Check iOS Notifications**:
   - A push notification labeled "Your Morning Briefing" should appear at ~7:30 AM (if configured)
   - Tap notification to open the app and view full briefing details

---

### Phase 3: Validate Briefing Content

#### 3.1 Morning Briefing Card (MainScreen)

**Expected Appearance**:
- Headline (15 words max): e.g., "Your Thursday was balanced—protein at breakfast boosted afternoon focus"
- Top Correlation Card icon: shows food/sleep/focus symbols
- Nudge line: e.g., "Try repeating Tuesday's high-protein breakfast for more sustained energy"
- "NEW" badge if unviewed

**Actions**:
- Tap card → Full briefing detail view slides up
- Scroll through correlation cards
- Mark as read (badge disappears)

#### 3.2 Briefing Detail View

**Expected Sections**:
1. **Headline** (day-specific, warm tone)
2. **Correlation Cards** (1–3 cards showing patterns):
   - Card category: `foodToSleep`, `foodToMood`, `focusToFeeling`, or `timingPattern`
   - Observation: specific finding with confidence level
   - Data points: meals/sleep/mood linked to the insight
3. **Actionable Nudge**:
   - Suggestion: concrete action (25 words)
   - Reasoning: why it matters (25 words)
   - Related meal: specific past meal to replicate or avoid
4. **Weekly Trend** (if available):
   - Average food score
   - Average sleep quality
   - Days logged
   - Trend direction: improving/declining/steady

**Validation Checklist**:
- [ ] Headline is warm and supportive (not clinical)
- [ ] Headline mentions specific day of the week
- [ ] Correlations are based on YOUR actual logged data (not generic)
- [ ] Confidence scores are realistic (0.6–1.0 for high-confidence cards)
- [ ] Nudge is immediately actionable
- [ ] No typos or grammatical errors
- [ ] JSON schema is intact (no broken fields)

---

### Phase 4: Real HealthKit Data Verification

#### 4.1 Apple Watch Sleep Integration

**Setup**:
1. Ensure Apple Watch is paired and Sleep Focus is enabled
2. Wear watch overnight
3. Sleep data syncs automatically in morning

**Testing**:
1. Open Yoga of Eating app
2. Navigate to "Reflect" tab
3. Check if both **subjective** (user-reported) and **objective** (Apple Watch) sleep data appear
4. Expected in briefing:
   - User-reported sleep quality (e.g., "Felt well-rested")
   - Apple Watch metrics: sleep score (%), duration (hours), efficiency (%)
   - Any correlation between reported feeling vs. objective metrics

**Validation**:
- [ ] Apple Watch data populates correctly
- [ ] Timestamp matches sync time (~2–3 seconds from watch bedtime)
- [ ] Briefing mentions discrepancies if they exist (e.g., "You slept 7.5h with 85% efficiency but reported poor sleep—could indicate stress or dreams affecting your perception")

#### 4.2 Sleep-to-Meal Correlation

**Scenario**:
- Log late dinner (8:00 PM) on Day 1
- Log poor sleep quality next morning
- Wait for briefing generation

**Expected Finding**:
- Briefing card: "foodToSleep" category
- Observation: "Late dinner at 8 PM correlated with 30% lower sleep quality the next morning"
- Suggestion: "Try finishing meals 3 hours before bed"

---

### Phase 5: Performance Monitoring

#### 5.1 Briefing Generation Speed

**Test**:
1. Log sleep quality at 7:30 AM
2. Start timer
3. Wait for briefing card to appear on main screen
4. Stop timer

**Expected Result**: Briefing appears within **3–8 seconds**
- 0–2s: Local fallback only
- 2–5s: Server-side generation (Firebase Cloud Function)
- 5–8s: Server call + Gemini response

**If >10 seconds**:
- Check network connectivity
- Verify Cloud Function logs in Firebase Console:
  - `gcloud functions logs read generateDailyBriefing --limit 50 --project yoga-of-eating`

#### 5.2 AI Quality Assessment

**Criteria**:
- [ ] Headline is specific to your data (not generic)
- [ ] Correlations match your actual logged meals/sleep
- [ ] Tone is warm and supportive, not clinical
- [ ] Suggestions are actionable and relevant
- [ ] Confidence scores correlate with data strength
- [ ] No hallucinations (false claims about your data)

**Example of HIGH QUALITY insight**:
```
Headline: "Your Thursday meals built sustained afternoon focus"
Correlation: "foodToFocus - Your high-protein lunches (Tue/Thu) 
correlated with 40% higher afternoon focus scores (confidence: 0.82)"
Nudge: "Try adding protein to your lunch tomorrow to boost 
afternoon productivity"
```

**Example of LOW QUALITY insight** (watch for):
```
Headline: "Keep being awesome!" ← Generic, not specific
Correlation: "You ate food and felt emotions" ← Vague, not data-driven
Nudge: "Eat more vegetables" ← Generic advice, not personalized
Confidence: 0.95 ← Unrealistically high for sparse data
```

#### 5.3 Monitoring via Logs

**Firebase Cloud Functions Logs**:
```bash
gcloud functions logs read generateDailyBriefing \
  --limit 50 \
  --project yoga-of-eating
```

**Expected Log Lines**:
- `Briefing generation started for user: <uid>`
- `Data fetched: 7 days, 21 meals logged`
- `Gemini API call latency: 2.5s`
- `Briefing returned successfully with 3 correlation cards`

**Troubleshooting Logs**:
- `GEMINI_API_KEY not set`: Secret not configured
- `429 Too Many Requests`: API rate limit hit (Gemini quota)
- `Invalid briefing structure from AI`: JSON parsing failed

#### 5.4 Local Fallback Testing

**To test fallback behavior**:
1. Disconnect device from internet (Airplane Mode)
2. Log sleep quality
3. Wait for briefing generation

**Expected Result**:
- Briefing appears within 1–2s (local pattern analyzer)
- Headline: generic but supportive (e.g., "A new day—keep building your wellbeing story")
- Correlation cards: 0–1 based on local pattern detection
- No server call errors logged

---

### Phase 6: A/B Testing Notification Timing

This phase tests different push notification delivery times for briefing alerts.

#### 6.1 Current Implementation (7:30 AM Fixed)

**Setup**:
1. Ensure notifications are enabled:
   - Settings → Notifications → Yoga of Eating → Allow Notifications ✓
2. Set device time to 7:25 AM (for testing)
3. Log sleep quality
4. Wait until 7:30 AM

**Expected Behavior**:
- Push notification arrives at exactly 7:30 AM
- Title: "Your Morning Briefing"
- Body: Briefing headline (e.g., "Your Thursday was balanced…")
- Tap notification → App opens to briefing detail view

**Testing Variants** (if implementing A/B tests):

**Variant A: 7:30 AM (current)**
- Pros: Catches early risers, aligns with morning routine
- Cons: Misses night-shift workers, some sleeping in

**Variant B: 8:00 AM**
- Pros: Accounts for more varied wake times
- Cons: May compete with work/commute attention

**Variant C: Adaptive (based on user's typical wake time)**
- Pros: Personalized, higher engagement
- Cons: Requires additional HealthKit data analysis

#### 6.2 Manual Timing Test

**Procedure**:
1. Device Settings → Developer → Enable manual time adjustment (if available)
2. Set time to 7:00 AM
3. Log sleep quality
4. Advance time by 30 minutes
5. Check for notification

**Metrics**:
- Time from trigger (sleep log) to delivery: _____ seconds
- Delivery accuracy: ±5 minutes acceptable
- Re-engagement: Did user tap notification? Y/N

---

## Test Checklist

### ✅ Briefing Generation & Accuracy
- [ ] Briefing appears within 3–8 seconds of logging sleep
- [ ] Headline is specific to user's data (not generic)
- [ ] 1–3 correlation cards present
- [ ] Confidence scores are realistic (0.6–1.0)
- [ ] Nudge is actionable and relevant
- [ ] Weekly trend data is correct
- [ ] No JSON parsing errors
- [ ] Briefing persists after app restart

### ✅ Real HealthKit Data
- [ ] Apple Watch sleep data populates
- [ ] Sleep metrics (duration, efficiency, score) are correct
- [ ] User-reported sleep aligns with briefing
- [ ] Discrepancies (subjective vs. objective) are noted
- [ ] Sleep-to-meal correlations are accurate

### ✅ UI/UX
- [ ] Morning briefing card appears on main screen
- [ ] Card is visually distinct and tappable
- [ ] Detail view layout is clear and readable
- [ ] Smiley state is not obscured by briefing card
- [ ] Dismissing detail view works smoothly

### ✅ Performance
- [ ] Generation completes within 3–8 seconds
- [ ] No memory leaks or crashes during generation
- [ ] App remains responsive during async call
- [ ] Logs show successful Cloud Function execution

### ✅ Notifications
- [ ] Permission prompt appears on first run
- [ ] Notification arrives at scheduled time (±5 min)
- [ ] Notification title and body are correct
- [ ] Tapping notification opens app to briefing view
- [ ] Notification dismissed cleanly

### ✅ Fallback & Error Handling
- [ ] Local fallback works when offline
- [ ] App doesn't crash on API errors
- [ ] User sees encouraging message on data shortage
- [ ] Retry logic works for transient failures

---

## Troubleshooting

### Briefing Not Appearing
**Possible Causes**:
1. **Insufficient data**: Less than 2–3 days logged
   - **Fix**: Log more meals, sleep, and mood data
2. **Sleep not logged**: Briefing requires sleep quality entry
   - **Fix**: Navigate to Reflect tab and log sleep
3. **Cloud Function failed**: Firebase error
   - **Fix**: Check logs: `gcloud functions logs read generateDailyBriefing`
4. **Network issue**: No internet connection
   - **Fix**: Check WiFi/cellular; local fallback should still work

### Poor Quality Insights
**Possible Causes**:
1. **Generic/repetitive data**: All meals similar, sleep always 8 hours
   - **Fix**: Log varied meals and sleep patterns
2. **Gemini API hallucinating**: AI inventing patterns
   - **Fix**: Provide more diverse, specific data inputs
3. **Confidence too high**: Unrealistic confidence scores
   - **Fix**: Review `PatternAnalyzer` confidence thresholds

**Mitigation**:
- Enable detailed logging in `InsightGenerationService`
- Review raw Gemini response in Cloud Function logs
- Adjust prompt in `index.js` for more conservative confidence

### Notification Not Arriving
**Possible Causes**:
1. **Notifications disabled**: User denied permission
   - **Fix**: Settings → Notifications → Yoga of Eating → Allow
2. **Wrong time scheduled**: System clock misaligned
   - **Fix**: Verify device time is correct
3. **App terminated**: Notification not scheduled if app never opened
   - **Fix**: Open app at least once after updating

### API Rate Limit Errors
**Symptom**: Gemini API returns 429 (Too Many Requests)
**Cause**: Quota exceeded
**Fix**:
- Check Gemini API quota in Google Cloud Console
- Implement exponential backoff in Cloud Function
- Batch requests if testing multiple users

---

## Success Metrics

After completing manual testing, you should see:

1. **Accuracy**: Briefing insights match actual logged data (>90% relevant)
2. **Engagement**: User reads full briefing detail view
3. **Performance**: Generation completes in <8 seconds
4. **Reliability**: 0 crashes during briefing flow
5. **Adoption**: User enables notifications and sees daily briefing
6. **Data Isolation**: Briefing only contains that user's data (no mixing)

---

## Recording Test Results

For each test day, log:

```
Date: [MM/DD/YYYY]
Device: [iPhone model, iOS version]
Test Focus: [Briefing generation / HealthKit integration / Notifications]

Meals Logged: [count]
Sleep Logged: [Yes/No]
HealthKit Data: [Apple Watch / Manual entry / None]

Briefing Generated: [Yes/No]
Generation Time: [___ seconds]
Headline: "[copy-paste]"
Correlations Found: [#]
Quality Rating: [1–5]

Issues/Notes:
- [any errors, slow performance, UI glitches]
- [suggestions for improvement]

Next Steps:
- [remaining tests or follow-ups]
```

---

## Next Phase: A/B Testing & Analytics

Once manual testing is green:

1. **Deploy to TestFlight** with notification A/B variant
2. **Measure engagement metrics**:
   - Briefing view rate
   - Notification tap-through rate
   - Time from notification to app open
   - Correlation with daily mood/productivity
3. **Iterate** on timing, tone, and content based on user feedback
4. **Gather qualitative feedback**: User interviews on insight relevance

---

## Questions During Testing?

Check these resources:
- **App logs**: Xcode console during manual runs
- **Cloud logs**: `gcloud functions logs read generateDailyBriefing`
- **Firebase Console**: Firestore data browser for user snapshots
- **Code**: Review `InsightGenerationService.swift`, `PatternAnalyzer.swift`

---

**Testing completed by**: _______________  
**Date**: _______________  
**Sign-off**: _______________
