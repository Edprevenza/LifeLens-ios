#!/bin/bash

echo "=== LifeLens iOS Build Script ==="
echo "This script dynamically selects simulator and ensures proper build"

# Change to project directory
cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*

# Get first available iPhone simulator
echo "🔍 Finding available iPhone simulator..."
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -o -E '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No iPhone simulator found!"
    exit 1
fi

SIMULATOR_NAME=$(xcrun simctl list devices available | grep "$SIMULATOR_ID" | sed 's/.*(\(.*\)).*/\1/' | cut -d' ' -f1-3)
echo "✅ Found simulator: $SIMULATOR_NAME ($SIMULATOR_ID)"

# Boot simulator if not already booted
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -o "(Booted)" || echo "")
if [ -z "$SIMULATOR_STATE" ]; then
    echo "🚀 Booting simulator..."
    xcrun simctl boot "$SIMULATOR_ID"
    sleep 5
else
    echo "✅ Simulator already booted"
fi

# Build the app
echo "🔨 Building LifeLens app..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -destination "id=$SIMULATOR_ID" \
    -derivedDataPath ./build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    IPHONEOS_DEPLOYMENT_TARGET=17.0 \
    clean build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Find the built app
APP_PATH=$(find ./build -name "LifeLens.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built app!"
    exit 1
fi

echo "📱 Found app at: $APP_PATH"

# Uninstall previous version if exists
echo "🗑️  Uninstalling previous version..."
xcrun simctl uninstall "$SIMULATOR_ID" com.lifelens.LifeLens 2>/dev/null || true

# Install the app
echo "📲 Installing app on simulator..."
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

if [ $? -ne 0 ]; then
    echo "❌ Installation failed!"
    exit 1
fi

# Launch the app
echo "🚀 Launching LifeLens..."
xcrun simctl launch "$SIMULATOR_ID" com.lifelens.LifeLens

if [ $? -eq 0 ]; then
    echo "✅ LifeLens successfully launched on simulator!"
    echo "Simulator ID: $SIMULATOR_ID"
    echo "App Bundle: com.lifelens.LifeLens"
else
    echo "⚠️  App installed but launch failed. Try launching manually from simulator."
fi