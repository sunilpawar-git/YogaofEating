---
description: Move existing app code into a local Swift Package for auto-discovery of files
---

# Migration to Modular Architecture

This workflow moves the core application code into a local Swift Package. This allows new files to be detected automatically without manually editing the Xcode project file.

## 1. Create Package Structure
```bash
mkdir -p "Yoga of Eating/Packages/AppFeature/Sources/AppFeature"
mkdir -p "Yoga of Eating/Packages/AppFeature/Tests/AppFeatureTests"
```

## 2. Create Package.swift
Create `Yoga of Eating/Packages/AppFeature/Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
            ]
        ),
        .testTarget(name: "AppFeatureTests", dependencies: ["AppFeature"]),
    ]
)
```

## 3. Move Source Files
Move the following directories from `Yoga of Eating/` to `Yoga of Eating/Packages/AppFeature/Sources/AppFeature/`:
- `Components`
- `Logic`
- `Models`
- `ViewModels`
- `Views`

## 4. Fix Imports
You will need to add `public` access modifiers to:
- Views, ViewModels, and Models so they are visible to the main app
- The `init` methods of these classes/structs

## 5. Link Package in Xcode
1. File > Add Package Dependencies...
2. Click "Add Local..."
3. Select the `Packages/AppFeature` folder
4. Add `AppFeature` library to your App Target's "Frameworks, Libraries, and Embedded Content"
