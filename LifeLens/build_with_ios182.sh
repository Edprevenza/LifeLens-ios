#!/bin/bash

echo "🚀 Building with iOS 18.2 Runtime"
echo "=================================="
echo ""

# 1. Verify iOS 18.2 runtime is installed
echo "✅ Available runtimes:"
xcrun simctl list runtimes | grep iOS
echo ""

# 2. List available simulators
echo "📱 Available simulators:"
xcrun simctl list devices | grep "iPhone.*18\.2" | head -5
echo ""

# 3. Clean build folder
rm -rf DerivedData

# 4. Build using xcodebuild with minimal settings
echo "🏗️ Building..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration 2>&1 | tail -50

echo ""
echo "If build failed, trying alternative approach..."

# 5. Alternative: Build through Xcode GUI
osascript << 'APPLESCRIPT'
tell application "Xcode"
    activate
    delay 1
end tell

tell application "System Events"
    tell process "Xcode"
        -- Try keyboard shortcut for build
        keystroke "b" using command down
    end tell
end tell
APPLESCRIPT

echo ""
echo "✅ Build initiated in Xcode"
echo "Check Xcode window for build progress"
