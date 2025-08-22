#!/bin/bash

echo "Building LifeLens for iOS Simulator..."
cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Use xcodebuild with destination flag
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
    -derivedDataPath ./build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    IPHONEOS_DEPLOYMENT_TARGET=17.0 \
    clean build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the app
    APP_PATH=$(find ./build -name "LifeLens.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "Found app at: $APP_PATH"
        
        # Install on simulator
        echo "Installing on simulator..."
        xcrun simctl install 9A506927-7D03-4A48-AF5A-AB82C91AADBC "$APP_PATH"
        
        # Launch the app
        echo "Launching app..."
        xcrun simctl launch 9A506927-7D03-4A48-AF5A-AB82C91AADBC com.yourcompany.LifeLens
        
        echo "✅ App installed and launched!"
    fi
else
    echo "❌ Build failed"
fi