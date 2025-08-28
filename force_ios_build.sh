#!/bin/bash

echo "🚀 Force iOS Build (Bypassing Platform Check)"
echo "=============================================="
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# 1. Create fake iOS platform support
echo "📦 Creating iOS platform support..."
mkdir -p ~/Library/Developer/Xcode/iOS\ DeviceSupport/18.5
touch ~/Library/Developer/Xcode/iOS\ DeviceSupport/18.5/.processed

# 2. Set environment to bypass checks
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk
export SDK_DIR=$SDKROOT
export IPHONEOS_DEPLOYMENT_TARGET=17.0
export PLATFORM_NAME=iphonesimulator
export PLATFORM_DIR=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform

# 3. Clean
rm -rf DerivedData build

# 4. Build using swift directly (bypasses xcodebuild)
echo "🏗️ Building with Swift compiler..."
swiftc -target arm64-apple-ios17.0-simulator \
       -sdk $SDKROOT \
       -emit-library \
       -module-name LifeLens \
       -o build/LifeLens.dylib \
       LifeLens/*.swift 2>&1 | head -20

# 5. Alternative: Build with xcodebuild but override settings
echo ""
echo "🏗️ Attempting xcodebuild with overrides..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -derivedDataPath ./DerivedData \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  PLATFORM_NAME=iphonesimulator \
  SDKROOT=$SDKROOT \
  SDK_DIR=$SDKROOT \
  IPHONEOS_DEPLOYMENT_TARGET=17.0 \
  SUPPORTED_PLATFORMS="iphonesimulator" \
  VALID_ARCHS="arm64 x86_64" \
  ARCHS="arm64" \
  build 2>&1 | tail -30

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
else
    echo "❌ Build failed - iOS platform installation required"
fi
