#!/bin/bash

echo "=== LifeLens iOS 18.2 Build Script ==="
echo "Building for iOS Simulator with iOS 18.2 SDK"

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean everything
echo "🧹 Cleaning build artifacts..."
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*

# Get available iPhone simulator
echo "🔍 Finding iOS 18.2 simulator..."
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iOS 18.2" -A 20 | grep "iPhone" | head -1 | grep -o -E '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')

if [ -z "$SIMULATOR_ID" ]; then
    echo "⚠️  No iOS 18.2 iPhone simulator found. Using any available iPhone..."
    SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -o -E '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')
fi

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No iPhone simulator found!"
    exit 1
fi

SIMULATOR_NAME=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | sed 's/ (.*//' | sed 's/^[[:space:]]*//')
echo "✅ Using simulator: $SIMULATOR_NAME"
echo "   ID: $SIMULATOR_ID"

# Boot simulator
echo "🚀 Booting simulator..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "   Simulator already booted"
open -a Simulator

# Wait for simulator
sleep 3

# Build with iOS 18.2 settings
echo "🔨 Building LifeLens for iOS 18.2..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath ./build \
    IPHONEOS_DEPLOYMENT_TARGET=18.2 \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    DEVELOPMENT_TEAM="" \
    ONLY_ACTIVE_ARCH=NO \
    VALID_ARCHS="x86_64 arm64" \
    build

BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
    echo "❌ Build failed!"
    echo ""
    echo "Trying with generic platform..."
    
    xcodebuild \
        -project LifeLens.xcodeproj \
        -scheme LifeLens \
        -configuration Debug \
        -sdk iphonesimulator \
        -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath ./build \
        IPHONEOS_DEPLOYMENT_TARGET=18.2 \
        CODE_SIGNING_REQUIRED=NO \
        build
    
    BUILD_RESULT=$?
fi

if [ $BUILD_RESULT -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find app
    APP_PATH=$(find ./build -name "LifeLens.app" -type d | grep -v "\.xctest" | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📱 Found app at: $APP_PATH"
        
        # Uninstall old version
        xcrun simctl uninstall "$SIMULATOR_ID" com.lifelens.LifeLens 2>/dev/null || true
        
        # Install new version
        echo "📲 Installing app..."
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        
        # Launch app
        echo "🚀 Launching LifeLens..."
        xcrun simctl launch "$SIMULATOR_ID" com.lifelens.LifeLens
        
        echo ""
        echo "✅ LifeLens is running on iOS 18.2 simulator!"
        echo "Simulator: $SIMULATOR_NAME"
        echo "Bundle ID: com.lifelens.LifeLens"
    else
        echo "❌ Could not find built app"
    fi
else
    echo "❌ Build failed. Check the error messages above."
    echo ""
    echo "You may need to open Xcode and:"
    echo "1. Select LifeLens project"
    echo "2. Go to Build Settings"
    echo "3. Set iOS Deployment Target to 18.2"
    echo "4. Try building with Cmd+B"
fi