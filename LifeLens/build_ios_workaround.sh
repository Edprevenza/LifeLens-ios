#!/bin/bash

echo "🚀 iOS Build Workaround - Using iOS 17.5"
echo "========================================="
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean everything
echo "🧹 Cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf DerivedData build

# Update project to iOS 17.5 everywhere
echo "📝 Forcing iOS 17.5 in project..."
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9][0-9]\.[0-9]/IPHONEOS_DEPLOYMENT_TARGET = 17.5/g' \
    LifeLens.xcodeproj/project.pbxproj

# Use iOS 17.5 simulator
echo "📱 Creating iOS 17.5 simulator..."
SIM_ID=$(xcrun simctl list devices | grep "iPhone.*17\.5" | head -1 | grep -o "[A-F0-9-]*)" | tr -d ')')

if [ -z "$SIM_ID" ]; then
    SIM_ID=$(xcrun simctl create "iPhone 15 Build" \
        "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" \
        "com.apple.CoreSimulator.SimRuntime.iOS-17-5")
    echo "Created new simulator: $SIM_ID"
else
    echo "Using existing simulator: $SIM_ID"
fi

# Boot simulator
xcrun simctl boot "$SIM_ID" 2>/dev/null || true

# Build with iOS 17.5
echo ""
echo "🔨 Building with iOS 17.5..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -destination "id=$SIM_ID" \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=17.5 \
  -quiet \
  build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    APP_PATH=$(find DerivedData -name "*.app" -type d | head -1)
    echo "App: $APP_PATH"
    
    # Install and run
    xcrun simctl install "$SIM_ID" "$APP_PATH"
    xcrun simctl launch "$SIM_ID" com.lifelens.LifeLens
else
    echo "❌ Build failed with iOS 17.5"
    
    # Try iOS 18.2 as fallback
    echo ""
    echo "🔨 Trying iOS 18.2..."
    SIM_18=$(xcrun simctl list devices | grep "iPhone.*18\.2" | head -1 | grep -o "[A-F0-9-]*)" | tr -d ')')
    
    if [ -z "$SIM_18" ]; then
        SIM_18=$(xcrun simctl create "iPhone 15 iOS18" \
            "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" \
            "com.apple.CoreSimulator.SimRuntime.iOS-18-2")
    fi
    
    xcrun simctl boot "$SIM_18" 2>/dev/null || true
    
    xcodebuild \
      -project LifeLens.xcodeproj \
      -scheme LifeLens \
      -configuration Debug \
      -destination "id=$SIM_18" \
      -derivedDataPath ./DerivedData \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      IPHONEOS_DEPLOYMENT_TARGET=17.5 \
      build 2>&1 | tail -30
fi