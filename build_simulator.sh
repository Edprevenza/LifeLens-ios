#!/bin/bash

echo "=== LifeLens iOS Simulator Build Script ==="
echo "Building for iOS Simulator with explicit SDK settings"

# Change to project directory
cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean everything first
echo "🧹 Cleaning all build artifacts..."
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*
xcodebuild clean -project LifeLens.xcodeproj -alltargets 2>/dev/null

# Get the first available iPhone simulator
echo "🔍 Finding iPhone simulator..."
SIMULATOR_INFO=$(xcrun simctl list devices available | grep "iPhone" | head -1)
SIMULATOR_ID=$(echo "$SIMULATOR_INFO" | grep -o -E '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')
SIMULATOR_NAME=$(echo "$SIMULATOR_INFO" | sed 's/ (.*//')

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No iPhone simulator found!"
    echo "Available simulators:"
    xcrun simctl list devices available
    exit 1
fi

echo "✅ Using simulator: $SIMULATOR_NAME"
echo "   ID: $SIMULATOR_ID"

# Boot the simulator
echo "🚀 Booting simulator..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "   Simulator may already be booted"

# Open Simulator app
open -a Simulator

# Wait for simulator to be ready
sleep 3

# Build using explicit SDK path
echo "🔨 Building LifeLens..."
echo "   Using iOS Simulator SDK"

xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath ./build \
    ONLY_ACTIVE_ARCH=NO \
    ARCHS="x86_64 arm64" \
    VALID_ARCHS="x86_64 arm64" \
    IPHONEOS_DEPLOYMENT_TARGET=17.0 \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    DEVELOPMENT_TEAM="" \
    build

BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
    echo "❌ Build failed! Trying alternative build method..."
    
    # Try with generic destination
    echo "🔨 Attempting generic simulator build..."
    xcodebuild \
        -project LifeLens.xcodeproj \
        -scheme LifeLens \
        -configuration Debug \
        -sdk iphonesimulator \
        -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath ./build \
        ONLY_ACTIVE_ARCH=NO \
        IPHONEOS_DEPLOYMENT_TARGET=17.0 \
        CODE_SIGNING_REQUIRED=NO \
        build
    
    BUILD_RESULT=$?
fi

if [ $BUILD_RESULT -ne 0 ]; then
    echo "❌ Build failed!"
    echo "Try opening the project in Xcode and building manually:"
    echo "  1. Open LifeLens.xcodeproj in Xcode"
    echo "  2. Select iPhone simulator from the device menu"
    echo "  3. Press Cmd+B to build"
    exit 1
fi

echo "✅ Build successful!"

# Find the app
APP_PATH=$(find ./build -name "LifeLens.app" -type d | grep -v "\.xctest" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built app!"
    echo "Searching in build directory:"
    find ./build -name "*.app" -type d
    exit 1
fi

echo "📱 Found app at: $APP_PATH"

# Install the app
echo "📲 Installing app..."
xcrun simctl uninstall "$SIMULATOR_ID" com.lifelens.LifeLens 2>/dev/null || true
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

if [ $? -ne 0 ]; then
    echo "❌ Installation failed!"
    exit 1
fi

# Launch the app
echo "🚀 Launching LifeLens..."
xcrun simctl launch --console "$SIMULATOR_ID" com.lifelens.LifeLens

echo "✅ LifeLens is running on the simulator!"
echo ""
echo "Simulator: $SIMULATOR_NAME"
echo "Bundle ID: com.lifelens.LifeLens"
echo ""
echo "If the app doesn't appear, check the simulator screen or try:"
echo "  xcrun simctl launch $SIMULATOR_ID com.lifelens.LifeLens"