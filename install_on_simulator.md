# Install LifeLens on iOS Simulator

## Quick Installation Steps

Since automated build is having issues with Xcode destinations, please follow these simple steps:

### In Xcode (already open):

1. **Select Target Device**
   - In the toolbar at the top, click on the device selector (next to the LifeLens scheme)
   - Choose **iPhone 16 Pro** from the list

2. **Build and Run**
   - Press **⌘+R** (Command+R) 
   - Or click the **Play button** (▶️) in the toolbar
   - Or go to menu: **Product → Run**

3. **Wait for Build**
   - Xcode will compile the app
   - It will automatically install on the simulator
   - The simulator will launch with the app

## What's Been Fixed

✅ **Profile Menu Screens** - All alignment issues resolved:
- Help & Support - Properly aligned grid buttons
- Privacy & Security - Fixed toggle spacing
- Notification Settings - Corrected text wrapping
- Medical History - Improved checkbox layout

✅ **ECG Monitor Widget** - Production-grade waveform display

✅ **Consistent UI** - 16px padding, 30x30 icons throughout

## If Build Fails

1. Try **Product → Clean Build Folder** (⇧⌘K)
2. Then **Product → Build** (⌘B)
3. Finally **Product → Run** (⌘R)

## Alternative: Manual Installation

If you have a built .app file:
```bash
xcrun simctl install "iPhone 16 Pro" /path/to/LifeLens.app
xcrun simctl launch "iPhone 16 Pro" com.yourcompany.LifeLens
```

The app is ready with all fixes applied!