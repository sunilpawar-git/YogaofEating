# Yoga of Eating - Project Overview

## What is this project?

**Yoga of Eating** is a mindful eating iOS app that helps users develop a healthier relationship with food through:
- **Sensory awareness** - Tracking hunger, fullness, and emotional states
- **Meal journaling** - Recording meals with timestamps and reflections
- **AI-powered insights** - Personalized guidance using Gemini AI
- **Daily nudges** - Gentle reminders for mindful eating practices

## Tech Stack

### Frontend (iOS)
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI (100% SwiftUI, no UIKit)
- **Architecture**: MVVM pattern
- **Minimum iOS**: 26.2
- **Target Devices**: iPhone, iPad, Mac (Catalyst), Vision Pro

### Backend
- **Firebase**: Authentication, Firestore, Cloud Functions
- **AI**: Google Gemini AI (via Cloud Functions)
- **Storage**: UserDefaults for local persistence

### Key Dependencies
- Firebase iOS SDK 12.7.0+
- GoogleSignIn-iOS 9.0.0+
- SwiftLint (code quality)
- SwiftFormat (code formatting)

## Project Structure

```
Yoga of Eating/
├── Yoga of Eating/           # Main iOS app
│   ├── Components/           # Reusable SwiftUI components
│   ├── Logic/                # Business logic services
│   │   ├── AuthService.swift
│   │   ├── AILogicService.swift
│   │   ├── MealLogicService.swift
│   │   ├── NotificationManager.swift
│   │   ├── PersistenceService.swift
│   │   └── SensoryService.swift
│   ├── Models/               # Data models
│   ├── ViewModels/           # MVVM view models
│   ├── Views/                # SwiftUI views
│   ├── Tests/                # Unit tests
│   ├── Info.plist            # App configuration (includes Google Sign-In URL scheme)
│   └── YogaOfEatingApp.swift # App entry point
├── functions/                # Firebase Cloud Functions
│   └── index.js              # Gemini AI integration
└── .agent/                   # Agent guidance files
```

## Key Features

1. **Sensory Tracking** - Visual flowchart for hunger/fullness awareness
2. **Meal Logging** - Quick capture with meal type tags
3. **Google Sign-In** - Secure authentication with Firebase
4. **AI Insights** - Server-side Gemini AI for personalized guidance
5. **Dark Mode** - Full support with system/manual theme switching
6. **Notifications** - Daily morning nudges for mindful eating

## Architecture Patterns

### MVVM with Services
- **Views**: SwiftUI views (declarative UI)
- **ViewModels**: `@MainActor` classes with `@Published` properties
- **Services**: Singleton services for business logic
  - `AuthService` - Firebase Auth + Google Sign-In
  - `AILogicService` - Cloud Functions integration
  - `PersistenceService` - Local data storage
  - `MealLogicService` - Meal tracking logic
  - `SensoryService` - Sensory state management
  - `NotificationManager` - Local notifications

### State Management
- `@StateObject` for view-owned state
- `@EnvironmentObject` for shared state (MainViewModel)
- `@AppStorage` for UserDefaults-backed properties
- Combine framework for reactive updates

## Important Configuration

### Google Sign-In Setup
- **URL Scheme**: `com.googleusercontent.apps.705155599602-btvk9mkfids2ofu0c7k2bkt2ona0qdnh`
- **Location**: `Info.plist` → `CFBundleURLTypes`
- **Callback Handler**: `YogaOfEatingApp.swift` → `.onOpenURL { url in GIDSignIn.sharedInstance.handle(url) }`

### Firebase Configuration
- **Config File**: `GoogleService-Info.plist` (gitignored)
- **Initialization**: `YogaOfEatingApp.init()` → `FirebaseApp.configure()`
- **Cloud Functions**: `functions/index.js` → `generateAIInsights` endpoint

## Code Quality Standards

### SwiftLint Rules
- Max file length: 250 lines (warning)
- Enforced on every build via Build Phase
- Config: `.swiftlint.yml`

### SwiftFormat
- Auto-formatting on every build
- Config: `.swiftformat`
- Indent: 4 spaces, Swift 6.0 syntax

### Testing
- Unit tests for ViewModels and Services
- Test target: `Yoga of EatingTests`
- UI tests: `Yoga of EatingUITests`

## Common Tasks

See `.agent/workflows/` for specific task workflows:
- Building and running the app
- Testing Google Sign-In
- Deploying Cloud Functions
- Running tests

## Notes for AI Agents

1. **Always use Swift 6.0 syntax** - Strict concurrency, `@MainActor`, `async/await`
2. **SwiftUI only** - No UIKit unless absolutely necessary
3. **MVVM pattern** - Keep views dumb, logic in ViewModels/Services
4. **Firebase first** - Use Firebase services for backend needs
5. **Test coverage** - Add tests for new ViewModels and Services
6. **Code quality** - SwiftLint must pass (1 warning max allowed)
