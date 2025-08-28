#!/bin/bash

echo "🚀 Building for iOS 18.2 Simulator"
echo "===================================="

# Clean
rm -rf DerivedData

# Get the first available iOS 18.2 simulator
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep "18.2" | head -1 | grep -o "[A-F0-9-]\{36\}" || echo "9A506927-7D03-4A48-AF5A-AB82C91AADBC")

echo "Using Simulator: $SIMULATOR_ID"

# Build specifically for iOS 18.2
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -destination "id=$SIMULATOR_ID" \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=18.2 \
  build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    
    # Install and run
    APP_PATH=$(find ./DerivedData -name "LifeLens.app" -path "*iphonesimulator*" | head -1)
    if [ -n "$APP_PATH" ]; then
        xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        xcrun simctl launch "$SIMULATOR_ID" "com.prevenza.LifeLens"
        open -a Simulator
    fi
else
    echo "❌ Build failed"
fi
