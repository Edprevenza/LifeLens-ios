#!/bin/bash

echo "🚀 Final Build Attempt with iOS 18.5 SDK"
echo "========================================="
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean everything first
echo "🧹 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf DerivedData
rm -rf build
killall Simulator 2>/dev/null

# List available simulators
echo "📱 Available simulators:"
xcrun simctl list devices available | grep iPhone | head -5

# Create a fresh iOS 18.2 simulator
echo ""
echo "📱 Creating fresh simulator..."
SIM_ID=$(xcrun simctl create "iPhone 15 Pro Final" \
    "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" \
    "com.apple.CoreSimulator.SimRuntime.iOS-18-2" 2>/dev/null || \
    xcrun simctl list devices | grep "iPhone 15 Pro" | grep "18\.2" | head -1 | grep -o "[A-F0-9-]*)" | tr -d ')')

echo "Simulator ID: $SIM_ID"

# Boot the simulator
echo "🔄 Booting simulator..."
xcrun simctl boot "$SIM_ID" 2>/dev/null || echo "Already booted"

# Build with the simulator
echo ""
echo "🔨 Building..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator18.5 \
  -destination "id=$SIM_ID" \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=17.5 \
  build 2>&1 | tee build_final.log

# Check if build succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo ""
    APP_PATH=$(find DerivedData -name "*.app" -type d | head -1)
    echo "📦 App location: $APP_PATH"
    
    # Install to simulator
    echo "📲 Installing app to simulator..."
    xcrun simctl install "$SIM_ID" "$APP_PATH"
    
    # Launch the app
    echo "🚀 Launching app..."
    xcrun simctl launch "$SIM_ID" com.lifelens.LifeLens
    
    # Open Simulator app
    open -a Simulator
else
    echo ""
    echo "❌ Build failed. Checking errors..."
    grep -E "(error:|failed:|cannot find)" build_final.log | head -10
    
    echo ""
    echo "Trying alternative: Build for generic simulator..."
    xcodebuild \
      -project LifeLens.xcodeproj \
      -scheme LifeLens \
      -configuration Debug \
      -sdk iphonesimulator \
      -destination "generic/platform=iOS Simulator" \
      -derivedDataPath ./DerivedData \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      IPHONEOS_DEPLOYMENT_TARGET=17.5 \
      build 2>&1 | tail -20
fi