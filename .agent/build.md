# Build & Development Guide

## Quick Start

### Prerequisites
- Xcode 16.2+ (for Swift 6.0 and iOS 26.2)
- macOS 26.2+
- CocoaPods or Swift Package Manager (SPM is used)
- Firebase CLI (for Cloud Functions)

### Initial Setup

1. **Clone and open project**
   ```bash
   cd "/Users/sunil/Desktop/Yoga of Eating/Yoga of Eating"
   open "Yoga of Eating.xcodeproj"
   ```

2. **Install dependencies** (automatic via SPM)
   - Firebase iOS SDK
   - GoogleSignIn-iOS

3. **Add GoogleService-Info.plist**
   - Download from Firebase Console
   - Place in `Yoga of Eating/` directory
   - **Do not commit** (gitignored)

## Building the App

### Recommended Simulator
**IMPORTANT**: Use these exact settings for builds:

```bash
# Recommended simulator
Platform: iOS Simulator
Device: iPhone 17 Pro
iOS Version: 26.2
Architecture: arm64
```

### Build Commands

#### Via Xcode
1. Open `Yoga of Eating.xcodeproj`
2. Select scheme: **Yoga of Eating**
3. Select destination: **iPhone 17 Pro (iOS 26.2)**
4. Press `⌘R` to build and run

#### Via Command Line
```bash
cd "/Users/sunil/Desktop/Yoga of Eating/Yoga of Eating"

# Build for simulator
xcodebuild -scheme "Yoga of Eating" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2" \
  build

# Build and run
xcodebuild -scheme "Yoga of Eating" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2" \
  -quiet build
```

### Clean Build
```bash
# Clean build folder
xcodebuild clean -scheme "Yoga of Eating"

# Or in Xcode: ⇧⌘K (Shift+Command+K)
```

## Available Destinations

Based on current Xcode setup:

### Physical Devices
- **stux.13** (iOS device, connected)
- **My Mac** (macOS, arm64 and x86_64)

### Simulators (iOS 26.2)
- iPhone 17 Pro ⭐ **RECOMMENDED**
- iPhone 17 Pro Max
- iPhone 17
- iPhone 16e
- iPhone Air
- iPad Pro 13-inch (M5)
- iPad Pro 11-inch (M5)
- iPad Air 13-inch (M3)
- iPad Air 11-inch (M3)
- iPad (A16)
- iPad mini (A17 Pro)

## Build Configuration

### Debug vs Release
- **Debug**: Development builds with debugging symbols
- **Release**: Optimized builds for distribution

### Build Settings
- **Deployment Target**: iOS 26.2
- **Swift Version**: 5.0 (Swift 6.0 mode enabled)
- **Code Signing**: Automatic (Development Team: CCVJR9P725)
- **Bundle ID**: `com.yogaofeating.Yoga-of-Eating`

### Info.plist Configuration
Key settings in `Yoga of Eating/Info.plist`:
- **CFBundleURLTypes**: Google Sign-In URL scheme
- **NSUserNotificationsUsageDescription**: Notification permissions

## Code Quality Checks

### SwiftLint
Runs automatically on every build:
```bash
# Manual run
swiftlint

# Auto-fix violations
swiftlint --fix
```

### SwiftFormat
Runs automatically on every build:
```bash
# Manual run
swiftformat .

# Check without modifying
swiftformat --lint .
```

### Current Violations
- ⚠️ `SettingsView.swift`: File length 270 lines (max 250) - **Known issue**

## Testing

### Run Unit Tests
```bash
# Via Xcode: ⌘U (Command+U)

# Via command line
xcodebuild test -scheme "Yoga of Eating" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2"
```

### Test Targets
- **Yoga of EatingTests**: Unit tests for ViewModels and Services
- **Yoga of EatingUITests**: UI automation tests

## Firebase Cloud Functions

### Setup
```bash
cd "/Users/sunil/Desktop/Yoga of Eating/functions"
npm install
```

### Deploy
```bash
firebase deploy --only functions
```

### Local Testing
```bash
firebase emulators:start --only functions
```

## Common Build Issues

### Issue: "Unable to find device matching..."
**Solution**: Use iPhone 17 Pro (iOS 26.2) as specified above

### Issue: "Google Sign-In crash"
**Solution**: Verify `Info.plist` contains correct URL scheme:
`com.googleusercontent.apps.705155599602-btvk9mkfids2ofu0c7k2bkt2ona0qdnh`

### Issue: "Firebase not configured"
**Solution**: Ensure `GoogleService-Info.plist` is in project and added to target

### Issue: "SwiftLint/SwiftFormat not found"
**Solution**: Install via Homebrew:
```bash
brew install swiftlint swiftformat
```

## Performance Tips

1. **Use Release builds** for performance testing
2. **Profile with Instruments** for memory/CPU analysis
3. **Test on physical device** for accurate performance metrics
4. **Monitor Firebase quota** to avoid unexpected costs

## Deployment

### TestFlight
1. Archive build: `Product → Archive`
2. Upload to App Store Connect
3. Submit for TestFlight review

### App Store
1. Increment version in `project.pbxproj`
2. Update release notes
3. Submit via App Store Connect

## Environment Variables

None currently used. All configuration via:
- `GoogleService-Info.plist` (Firebase)
- `Info.plist` (App settings)
- `@AppStorage` (User preferences)
