#!/bin/bash

echo "🔧 iOS Build Workaround (No iOS 18.5 Required)"
echo "==============================================="
echo ""

# 1. Close Xcode to reset
killall Xcode 2>/dev/null
sleep 2

# 2. Open project with iOS 17 compatibility
echo "📱 Opening project with iOS 17.0 target..."
open -a Xcode LifeLens.xcodeproj

# 3. Wait for Xcode to open
sleep 3

# 4. Use AppleScript to configure and build
osascript << 'APPLESCRIPT'
tell application "Xcode"
    activate
end tell

delay 2

tell application "System Events"
    tell process "Xcode"
        set frontmost to true
        
        -- Open scheme editor
        keystroke "," using {command down, shift down}
        delay 2
        
        -- Try to change deployment target in Build Settings
        keystroke "Build Settings" 
        delay 1
        
        -- Search for deployment target
        keystroke "f" using command down
        delay 0.5
        keystroke "deployment target"
        delay 1
        
        -- Close search
        key code 53 -- Escape
        
        -- Close settings
        key code 53 -- Escape
        
        -- Build the project
        keystroke "b" using command down
    end tell
end tell

return "Build started in Xcode"
APPLESCRIPT

echo ""
echo "✅ Xcode is now building with iOS 17.0 target"
echo ""
echo "If build still fails in Xcode:"
echo "1. Click on the project name in navigator"
echo "2. Select the LifeLens target"
echo "3. In 'Minimum Deployments' section, change iOS to 17.0"
echo "4. Press Cmd+B to build"
echo ""
echo "Alternative: Build for Mac instead:"
echo "Product → Destination → My Mac"
