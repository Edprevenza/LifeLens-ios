#!/bin/bash

echo "🔄 Starting iOS rebuild process..."

# Kill any running simulators
echo "📱 Shutting down simulators..."
xcrun simctl shutdown all 2>/dev/null || true
killall Simulator 2>/dev/null || true

# Clean build artifacts
echo "🧹 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf build/

# Get available simulator
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone 15 Pro" | head -1 | awk -F'[()]' '{print $2}')
if [ -z "$SIMULATOR_ID" ]; then
    SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | awk -F'[()]' '{print $2}')
fi

echo "📦 Building app for simulator: $SIMULATOR_ID"

# Build the app
xcodebuild \
    -workspace LifeLens.xcworkspace \
    -scheme LifeLens \
    -sdk iphonesimulator \
    -configuration Debug \
    -derivedDataPath build \
    -destination "id=$SIMULATOR_ID" \
    build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the app
    APP_PATH=$(find build/Build/Products -name "*.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📱 Found app at: $APP_PATH"
        
        # Boot simulator
        echo "🚀 Booting simulator..."
        xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
        
        # Install app
        echo "📲 Installing app..."
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        
        # Launch app
        echo "🎯 Launching app..."
        xcrun simctl launch "$SIMULATOR_ID" com.lifelens.LifeLens
        
        # Open simulator
        open -a Simulator
        
        echo "✨ App successfully rebooted and reinstalled!"
    else
        echo "❌ Could not find built app"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi