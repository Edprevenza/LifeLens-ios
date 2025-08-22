# Fix iOS Build Issue - iOS 18.5 SDK

## The Problem
The project is configured to require iOS 18.5 SDK but your Xcode only has iOS 18.2 simulator runtime installed.

## Quick Fix in Xcode

1. **Open Xcode** (already open)

2. **Select the Project**:
   - Click on "LifeLens" in the project navigator (left sidebar)
   - Select the "LifeLens" PROJECT (not target) at the top

3. **Update Build Settings**:
   - Go to "Build Settings" tab
   - Search for "iOS Deployment Target"
   - Change it to "17.0" for both Debug and Release

4. **Select Target Settings**:
   - Now select the "LifeLens" TARGET (below the project)
   - Go to "General" tab
   - Under "Minimum Deployments", set iOS to "17.0"

5. **Clean and Build**:
   - Menu: Product → Clean Build Folder (Shift+Cmd+K)
   - Select "iPhone 16" from device dropdown
   - Click Play button (▶) or press Cmd+R

## Alternative: Command Line Fix

If you prefer command line, run this in Terminal:

```bash
cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Open in Xcode
open LifeLens.xcodeproj

# Then in Xcode, just press Cmd+R to build and run
```

## What This Fixes
- Removes iOS 18.5 requirement
- Uses iOS 18.2 runtime that's installed
- Allows building for simulator

The app will launch automatically in the simulator after building.