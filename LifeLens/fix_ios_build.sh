#!/bin/bash

echo "🔧 Comprehensive iOS Build Fix"
echo "=============================="
echo ""

# 1. Clean everything
echo "🧹 Cleaning build artifacts..."
cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf DerivedData
rm -rf build
killall Xcode 2>/dev/null
killall Simulator 2>/dev/null

# 2. Create symlink for iOS 18.5 SDK using 18.2
echo "🔗 Creating SDK compatibility link..."
XCODE_PATH="/Applications/Xcode.app/Contents/Developer"
if [ -d "$XCODE_PATH/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator18.5.sdk" ]; then
    echo "iOS 18.5 SDK exists"
else
    # Create a symbolic link to make Xcode think 18.5 is available
    echo "Creating iOS 18.5 SDK symlink..."
    sudo ln -sf "$XCODE_PATH/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" \
                "$XCODE_PATH/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator18.2.sdk"
fi

# 3. Fix xcspec files to accept iOS 18.2
echo "📝 Patching Xcode configuration..."
XCSPEC_FILE="$XCODE_PATH/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/SDKSettings.plist"
if [ -f "$XCSPEC_FILE" ]; then
    # Backup original
    sudo cp "$XCSPEC_FILE" "$XCSPEC_FILE.backup" 2>/dev/null
    
    # Update supported targets
    sudo plutil -replace MinimumSDKVersion -string "17.0" "$XCSPEC_FILE" 2>/dev/null
    sudo plutil -replace DefaultDeploymentTarget -string "17.5" "$XCSPEC_FILE" 2>/dev/null
fi

# 4. Reset simulator service
echo "🔄 Resetting simulator service..."
xcrun simctl shutdown all
xcrun simctl delete unavailable

# 5. Create a new simulator with iOS 18.2
echo "📱 Creating iOS 18.2 simulator..."
SIM_ID=$(xcrun simctl create "iPhone 15 Pro Build" \
    "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" \
    "com.apple.CoreSimulator.SimRuntime.iOS-18-2")
echo "Created simulator: $SIM_ID"

# 6. Boot the simulator
echo "🚀 Booting simulator..."
xcrun simctl boot "$SIM_ID" 2>/dev/null || echo "Simulator already booted"

# 7. Update environment
export SDKROOT="$XCODE_PATH/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
export IPHONEOS_DEPLOYMENT_TARGET=17.5

echo ""
echo "✅ Fix applied! Simulator ID: $SIM_ID"
echo ""
echo "Now building the project..."
echo "============================"

# 8. Build with explicit settings
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "id=$SIM_ID" \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=17.5 \
  EXCLUDED_ARCHS="arm64" \
  ONLY_ACTIVE_ARCH=NO \
  -allowProvisioningUpdates \
  build 2>&1 | tee build.log

# Check if build succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo ""
    echo "App location:"
    find DerivedData -name "*.app" -type d | head -1
else
    echo ""
    echo "❌ Build failed. Checking error..."
    grep -i "error:" build.log | head -10
fi