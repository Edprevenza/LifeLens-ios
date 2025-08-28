#!/bin/bash

echo "🚀 Opening Xcode and Building via UI"
echo "====================================="
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean first
echo "🧹 Cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf DerivedData

# Kill existing Xcode
killall Xcode 2>/dev/null
sleep 2

# Open the project in Xcode
echo "📂 Opening project in Xcode..."
open -a Xcode LifeLens.xcodeproj

# Wait for Xcode to load
sleep 5

# Use AppleScript to build via Xcode UI
echo "🔨 Triggering build via Xcode UI..."
osascript <<'END'
tell application "Xcode"
    activate
end tell

delay 3

tell application "System Events"
    tell process "Xcode"
        set frontmost to true
        
        -- Try to select iPhone Simulator as destination
        keystroke "0" using {shift down, command down}
        delay 2
        
        -- Select any available simulator
        keystroke return
        delay 1
        
        -- Trigger build
        keystroke "b" using command down
    end tell
end tell
END

echo ""
echo "✅ Build triggered in Xcode!"
echo ""
echo "MANUAL STEPS (if automatic build fails):"
echo "========================================="
echo ""
echo "1. In Xcode, go to: Product → Destination"
echo "2. Select: 'Any iOS Simulator Device (arm64, x86_64)'"
echo "3. Press Cmd+B to build"
echo ""
echo "If that fails:"
echo "1. Go to: Product → Scheme → Edit Scheme"
echo "2. Under 'Run', change 'Build Configuration' to 'Debug'"
echo "3. Under 'Run', uncheck 'Debug executable'"
echo "4. Try building again with Cmd+B"
echo ""
echo "Alternative fix:"
echo "1. File → Project Settings"
echo "2. Change 'Derived Data' to 'Project-relative'"
echo "3. Clean build folder: Shift+Cmd+K"
echo "4. Build again: Cmd+B"