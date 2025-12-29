# Agent Guidance Directory

This directory contains documentation to help AI agents understand and work with the Yoga of Eating project.

## Files

### 📋 [project.md](./project.md)
**Project overview and architecture**
- What the app does
- Tech stack and dependencies
- Project structure
- Architecture patterns
- Code quality standards

### 🔨 [build.md](./build.md)
**Build and development instructions**
- **Recommended simulator**: iPhone 17 Pro (iOS 26.2)
- Build commands (Xcode and CLI)
- Testing instructions
- Common build issues and solutions
- Deployment guide

### 📁 [workflows/](./workflows/)
**Task-specific workflows**
- Step-by-step guides for common tasks
- Can be invoked with slash commands
- Auto-runnable steps marked with `// turbo`

## Quick Reference

### Build the app
```bash
cd "/Users/sunil/Desktop/Yoga of Eating/Yoga of Eating"
xcodebuild -scheme "Yoga of Eating" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2" \
  build
```

### Run tests
```bash
xcodebuild test -scheme "Yoga of Eating" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2"
```

### Deploy Cloud Functions
```bash
cd "/Users/sunil/Desktop/Yoga of Eating/functions"
firebase deploy --only functions
```

## For AI Agents

When working on this project:

1. **Read `project.md` first** to understand the architecture
2. **Check `build.md`** for build settings (especially simulator choice)
3. **Look in `workflows/`** for task-specific guidance
4. **Always use iPhone 17 Pro (iOS 26.2)** for builds
5. **Follow Swift 6.0 and SwiftUI best practices**
6. **Ensure SwiftLint passes** before committing

## Updating This Documentation

Keep these files up to date when:
- Adding new dependencies
- Changing architecture patterns
- Updating build requirements
- Adding new workflows
- Fixing common issues

These docs are version controlled and should evolve with the project.
