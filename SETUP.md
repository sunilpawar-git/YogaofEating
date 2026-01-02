# Security Setup Guide

## Firebase Configuration Files

**IMPORTANT**: `GoogleService-Info.plist` contains sensitive Firebase credentials and is **NOT** included in this repository for security reasons.

### For Developers

Each developer must add their own `GoogleService-Info.plist` file locally:

1. Get the file from Firebase Console
2. Place it in the root directory
3. The file is already in `.gitignore`

### Security Best Practices

- ✅ Keep `GoogleService-Info.plist` local only
- ❌ Never commit Firebase credentials to git

**Last Updated**: Security cleanup completed - `GoogleService-Info.plist` removed from all git history.
