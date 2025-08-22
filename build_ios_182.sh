#!/bin/bash

echo "Building iOS app for simulator with iOS 18.2 runtime"
echo "======================================================"

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*

# Build for generic iOS simulator
echo "Building app..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -derivedDataPath build \
    -sdk iphonesimulator \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO \
    build

# Find the built app
APP_PATH=$(find build -name "LifeLens.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Build failed - app not found"
    exit 1
fi

echo "✅ App built successfully at: $APP_PATH"

# Get the booted simulator
BOOTED_SIM=$(xcrun simctl list devices | grep "(Booted)" | head -1 | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')

if [ -z "$BOOTED_SIM" ]; then
    echo "No booted simulator found. Booting iPhone 16 Pro..."
    BOOTED_SIM="9A506927-7D03-4A48-AF5A-AB82C91AADBC"
    xcrun simctl boot $BOOTED_SIM 2>/dev/null || true
    sleep 5
fi

# Install the app
echo "Installing app on simulator..."
xcrun simctl install $BOOTED_SIM "$APP_PATH"

# Launch the app
echo "Launching app..."
xcrun simctl launch $BOOTED_SIM com.lifelens.LifeLens

echo "✅ App installed and launched successfully!"