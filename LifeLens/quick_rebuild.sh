#!/bin/bash

# Quick iOS app rebuild script
echo "🔄 Quick iOS Rebuild..."

# Kill simulators
xcrun simctl shutdown all 2>/dev/null || true

# Clean
rm -rf build/ ~/Library/Developer/Xcode/DerivedData/*

# Build for generic simulator
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -sdk iphonesimulator \
    -derivedDataPath build \
    -destination 'generic/platform=iOS Simulator' \
    build \
    CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    
    # Find and install app
    APP_PATH=$(find build -name "LifeLens.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | awk -F'[()]' '{print $2}')
        
        xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
        xcrun simctl install "$DEVICE_ID" "$APP_PATH"
        xcrun simctl launch "$DEVICE_ID" com.lifelens.LifeLens
        open -a Simulator
        
        echo "✨ App installed and launched!"
    fi
else
    echo "❌ Build failed - checking errors..."
fi