#!/bin/bash

echo "Direct iOS Simulator Installation"
echo "================================="

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Try to build with minimal settings
echo "Building app..."
xcodebuild \
    -target LifeLens \
    -configuration Debug \
    -sdk iphonesimulator \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    IPHONEOS_DEPLOYMENT_TARGET=17.0 \
    -derivedDataPath ./DerivedData \
    build 2>&1 | tail -5

# Find the app
APP=$(find ./DerivedData -name "LifeLens.app" -type d 2>/dev/null | head -1)

if [ -n "$APP" ]; then
    echo "Found app at: $APP"
    
    # Install on simulator
    echo "Installing on simulator..."
    xcrun simctl install booted "$APP"
    
    # Launch
    echo "Launching app..."
    xcrun simctl launch booted com.prevenza.LifeLens || xcrun simctl launch booted com.Prevenza.LifeLens || xcrun simctl launch booted com.yourcompany.LifeLens
    
    echo "✅ Done!"
else
    echo "❌ Could not find built app"
    
    # Try alternative locations
    echo "Searching for app in other locations..."
    find ~/Library/Developer/Xcode -name "LifeLens.app" -type d 2>/dev/null | head -3
fi