#!/bin/bash

echo "🔧 Auto iOS Platform Installer"
echo "==============================="
echo ""

# 1. Check current Xcode installation
echo "📱 Checking Xcode installation..."
XCODE_PATH=$(xcode-select -p)
echo "Xcode path: $XCODE_PATH"

# 2. Try to download iOS platform using xcodebuild
echo ""
echo "📦 Attempting to download iOS platform..."
echo "This may take several minutes..."

# Try downloading iOS 18.2 platform specifically
sudo xcodebuild -downloadPlatform iOS 2>&1 | while read line; do
    echo "$line"
    if [[ "$line" == *"Download complete"* ]]; then
        echo "✅ iOS platform downloaded successfully!"
        break
    elif [[ "$line" == *"Error"* ]] || [[ "$line" == *"failed"* ]]; then
        echo "⚠️ Download issue detected, trying alternative method..."
        break
    fi
done

# 3. Alternative: Use xcrun to install simulator runtime
echo ""
echo "📲 Installing iOS Simulator runtime..."
xcrun simctl runtime add "iOS 18.2" 2>/dev/null || {
    echo "Trying to install available iOS runtime..."
    
    # List available runtimes
    echo "Available runtimes:"
    xcrun simctl list runtimes
    
    # Try to install iOS 17 as fallback
    xcrun simctl runtime add "iOS 17.5" 2>/dev/null || {
        echo "⚠️ Could not install via xcrun"
    }
}

# 4. Open Xcode to trigger automatic download
echo ""
echo "🚀 Opening Xcode to trigger automatic component installation..."
open -a Xcode /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens.xcodeproj

# Wait for Xcode to open
sleep 3

# 5. Use AppleScript to handle any dialogs
osascript <<EOF
tell application "Xcode"
    activate
end tell

tell application "System Events"
    tell process "Xcode"
        set frontmost to true
        delay 2
        
        -- Check for download components dialog
        if exists window "Install Additional Components" then
            click button "Install" of window "Install Additional Components"
            delay 1
        end if
        
        -- Check for any other install dialogs
        if exists sheet 1 of window 1 then
            if exists button "Download" of sheet 1 of window 1 then
                click button "Download" of sheet 1 of window 1
            else if exists button "Install" of sheet 1 of window 1 then
                click button "Install" of sheet 1 of window 1
            else if exists button "Get" of sheet 1 of window 1 then
                click button "Get" of sheet 1 of window 1
            end if
        end if
    end tell
end tell
EOF

echo ""
echo "📋 Status check..."

# 6. Check installed SDKs
echo ""
echo "Installed SDKs:"
xcodebuild -showsdks | grep -i ios

# 7. Check simulator runtimes
echo ""
echo "Installed Simulator Runtimes:"
xcrun simctl list runtimes | grep iOS

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Wait for Xcode to finish downloading components (check progress in Xcode)"
echo "2. Once download is complete, run: ./build_simulator_fixed.sh"
echo ""
echo "If Xcode shows a download dialog, click 'Download' or 'Install'"