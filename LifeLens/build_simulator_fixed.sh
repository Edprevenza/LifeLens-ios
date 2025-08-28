#!/bin/bash

echo "🚀 iOS Simulator Build"
echo "====================="
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# Clean
echo "🧹 Cleaning..."
rm -rf DerivedData build

# Use the specific iOS 18.2 simulator we created
SIMULATOR_ID="F10CE7AB-1129-4B78-91B1-1A7E1F9C68A3"
echo "📱 Using Simulator: $SIMULATOR_ID"

# Build with specific destination
echo "🏗️ Building for iOS Simulator..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "id=$SIMULATOR_ID" \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=NO \
  build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    
    # Find app
    APP_PATH=$(find ./DerivedData -name "LifeLens.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        echo "📱 App built at: $APP_PATH"
        
        # Install to simulator
        DEVICE_ID=$(xcrun simctl list devices booted | grep -o "[A-F0-9-]\{36\}" | head -1)
        if [ -n "$DEVICE_ID" ]; then
            xcrun simctl install "$DEVICE_ID" "$APP_PATH"
            xcrun simctl launch "$DEVICE_ID" "com.prevenza.LifeLens"
            echo "🚀 App launched in simulator!"
        else
            echo "Boot a simulator first with: xcrun simctl boot [device-id]"
        fi
    fi
else
    echo "❌ Build failed"
fi