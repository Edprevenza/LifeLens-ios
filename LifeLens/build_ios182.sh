#!/bin/bash

# Build LifeLens for iOS 18.2 Simulator

echo "Building LifeLens for iOS 18.2..."

# Clean build directory
rm -rf build
mkdir -p build

# Set environment
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
export SDKROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"

# Build using xcodebuild with specific settings
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -sdk iphonesimulator \
    -derivedDataPath ./build \
    -destination 'generic/platform=iOS Simulator' \
    IPHONEOS_DEPLOYMENT_TARGET=16.0 \
    TARGETED_DEVICE_FAMILY="1,2" \
    ONLY_ACTIVE_ARCH=YES \
    VALID_ARCHS="x86_64 arm64" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    DEVELOPMENT_TEAM="" \
    -allowProvisioningUpdates \
    build

if [ $? -eq 0 ]; then
    echo "Build succeeded!"
    APP_PATH=$(find ./build -name "LifeLens.app" | head -1)
    echo "App built at: $APP_PATH"
    
    # Install to simulator
    DEVICE_ID="5B940E66-0B42-46AD-B289-31C38A9A8DFC"
    echo "Installing to iPhone 16 Pro Max..."
    xcrun simctl install $DEVICE_ID "$APP_PATH"
    
    echo "Launching app..."
    xcrun simctl launch $DEVICE_ID com.lifelens.app
else
    echo "Build failed!"
    exit 1
fi