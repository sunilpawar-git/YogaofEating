# How to View Logs in Xcode

## 🔍 Why You're Not Seeing Logs

The logs only appear when:
1. **The app is running** (not just built)
2. **The Debug Console is visible** in Xcode
3. **You've logged a meal** (which triggers AI analysis)

## 📋 Steps to View Logs

### Step 1: Show the Debug Console

In Xcode, you need to show the **Debug Console** at the bottom:

1. **Method 1 - Keyboard Shortcut:**
   - Press `⌘ + Shift + Y` (Command + Shift + Y)
   - This toggles the debug area

2. **Method 2 - Menu:**
   - Go to: `View` → `Debug Area` → `Show Debug Area`
   - Or: `View` → `Debug Area` → `Activate Console`

3. **Method 3 - Button:**
   - Look at the bottom-right of Xcode window
   - Click the button with two overlapping rectangles (or a console icon)
   - This shows/hides the debug area

### Step 2: Run the App

1. Make sure the app is **running** (not just built)
2. Click the **Play** button (▶️) or press `⌘ + R`
3. Wait for the app to launch on simulator/device

### Step 3: Check Console Output

Once the app is running, you should see logs in the **Debug Console** at the bottom:

**On App Launch, you should see:**
```
🔥 Firebase initialized
📱 Yoga of Eating app starting...
🔔 Notifications configured
🚀 MainViewModel initialized with AILogicService
✅ AI Integration is ACTIVE - Gemini will analyze meals!
```

**When you log a meal, you should see:**
```
🍽️ Meal updated - ID: [UUID], Items: [your meal description]
📝 Local healthScore set to: 0.5
🤖 AI Analysis started for meal: [your meal description]
📡 Calling Firebase Cloud Function 'analyzeMeal' with description: '[your meal]'
📥 Received response from Cloud Function
📋 Parsed response - healthScore: X.XX, mood: [mood], sound: [sound]
✅ AI Analysis successful - Score: X.XX, Mood: [mood], Sound: [sound]
📊 Updated meal healthScore to: X.XX
😊 Smiley state updated - Current mood: [mood], Scale: X.XX
```

## 🎯 Quick Test

1. **Run the app** (`⌘ + R`)
2. **Show console** (`⌘ + Shift + Y`)
3. **Look for startup logs** - You should see the Firebase and MainViewModel initialization messages immediately
4. **Log a meal** - Tap the smiley, enter a meal description
5. **Watch for AI logs** - You should see the AI analysis logs appear

## ⚠️ Troubleshooting

### If you still don't see logs:

1. **Check Console Filter:**
   - In the debug console, make sure there's no filter active
   - Look for a search/filter box at the bottom
   - Clear any filters or search terms

2. **Check Output Level:**
   - In the debug console, look for "All Output" vs "Debugger Output"
   - Make sure it's set to show "All Output"

3. **Check if Running on Device:**
   - If running on a physical device, logs might be in **Window** → **Devices and Simulators**
   - Select your device → Click "Open Console"

4. **Verify App is Actually Running:**
   - Look at the top bar - it should say "Running Yoga of Eating on [device]"
   - If it says "Ready" or "Stopped", the app isn't running

5. **Check for Errors:**
   - Look for red error messages in the console
   - These might indicate why logs aren't appearing

## 📱 Testing on Physical Device

If running on a physical device (not simulator):
- Logs appear in the same debug console
- Make sure device is connected via USB
- Check **Window** → **Devices and Simulators** if logs don't appear

## ✅ What to Look For

The logs will help you verify:
- ✅ Firebase is initialized
- ✅ AI service is active
- ✅ Meals are being logged
- ✅ AI analysis is being triggered
- ✅ Cloud Function is being called
- ✅ Responses are being received
- ✅ Smiley state is updating

If you see all these logs, the AI integration is working! 🎉

