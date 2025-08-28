#!/bin/bash

echo "🚀 Building with iOS 18.2 Runtime"
echo "================================="
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean
echo "🧹 Cleaning..."
rm -rf DerivedData build
killall Simulator 2>/dev/null

# Use the iOS 18.2 simulator we already created
SIM_ID="7B9E7A7A-ECEB-4E9D-823F-1578F856F0FF"
echo "📱 Using iOS 18.2 Simulator: $SIM_ID"

# Boot the simulator
echo "🔄 Booting simulator..."
xcrun simctl boot "$SIM_ID" 2>/dev/null || echo "Already booted"

# Open simulator app
open -a Simulator

# Wait for simulator to be ready
sleep 3

# Build specifically for iOS 18.2
echo ""
echo "🔨 Building for iOS 18.2..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=17.5 \
  SUPPORTED_PLATFORMS="iphonesimulator" \
  SUPPORTS_MACCATALYST=NO \
  VALID_ARCHS="x86_64 arm64" \
  build 2>&1 | tee build_18_2.log

# Check result
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    APP_PATH=$(find DerivedData -name "*.app" -type d | head -1)
    echo "App at: $APP_PATH"
    
    # Install and launch
    echo "📲 Installing app..."
    xcrun simctl install "$SIM_ID" "$APP_PATH"
    
    echo "🚀 Launching app..."
    xcrun simctl launch "$SIM_ID" com.lifelens.LifeLens
else
    echo ""
    echo "❌ Build failed. Key errors:"
    grep -E "(error:|failed:|iOS.*not installed)" build_18_2.log | head -10
    
    echo ""
    echo "Trying alternative approach..."
    
    # Try with generic simulator destination
    xcodebuild \
      -project LifeLens.xcodeproj \
      -scheme LifeLens \
      -configuration Debug \
      -sdk iphonesimulator \
      -destination "platform=iOS Simulator,OS=latest" \
      -derivedDataPath ./DerivedData \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      IPHONEOS_DEPLOYMENT_TARGET=17.5 \
      build 2>&1 | tail -20
fi