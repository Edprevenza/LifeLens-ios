#!/bin/bash

echo "🚀 Direct iOS Simulator Install"
echo "================================"
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# 1. Boot the iOS 18.2 simulator
echo "📱 Booting iOS 18.2 simulator..."
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep -o "[A-F0-9-]\{36\}" | head -1)

if [ -z "$DEVICE_ID" ]; then
    echo "Creating new iPhone 16 Pro simulator..."
    DEVICE_ID=$(xcrun simctl create "iPhone 16 Pro" "iPhone 16 Pro" "iOS18.2")
fi

echo "Device ID: $DEVICE_ID"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || echo "Simulator already booted"

# 2. Build for that specific device
echo ""
echo "🏗️ Building for device $DEVICE_ID..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build succeeded!"
    
    # Find and install the app
    APP_PATH=$(find ./DerivedData -name "LifeLens.app" -path "*iphonesimulator*" | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📱 Installing app to simulator..."
        xcrun simctl install "$DEVICE_ID" "$APP_PATH"
        
        # Launch the app
        BUNDLE_ID=$(defaults read "$APP_PATH/Info.plist" CFBundleIdentifier 2>/dev/null || echo "com.prevenza.LifeLens")
        echo "🚀 Launching $BUNDLE_ID..."
        xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"
        
        # Open the simulator app
        open -a Simulator
        
        echo ""
        echo "✅ App is running in the simulator!"
    fi
else
    echo ""
    echo "❌ Build failed. Check the error messages above."
fi
