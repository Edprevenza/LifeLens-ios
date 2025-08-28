#!/bin/bash

echo "Building LifeLens with custom iOS 18.5 SDK..."

# Set custom SDK path
CUSTOM_SDK="/Users/basorge/Downloads/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"

# Clean previous builds
rm -rf build DerivedData

# Build using custom SDK
xcodebuild \
    -workspace LifeLens.xcworkspace \
    -scheme LifeLens \
    -configuration Debug \
    -sdk "$CUSTOM_SDK" \
    -derivedDataPath ./build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    IPHONEOS_DEPLOYMENT_TARGET=18.0 \
    -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.2' \
    build

if [ $? -eq 0 ]; then
    echo "Build succeeded!"
    
    # Find the app bundle
    APP_PATH=$(find build/Build/Products -name "*.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "Installing app: $APP_PATH"
        
        # Install to simulator
        xcrun simctl install booted "$APP_PATH"
        
        # Launch the app
        xcrun simctl launch booted com.prevenza.LifeLens
    else
        echo "Could not find built app"
    fi
else
    echo "Build failed"
fi