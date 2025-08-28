#!/bin/bash

echo "Building LifeLens iOS App..."
echo "============================"

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean
echo "Cleaning..."
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*

# Build with explicit settings
echo "Building app..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -target LifeLens \
    -configuration Debug \
    -sdk iphonesimulator \
    SYMROOT=build \
    CONFIGURATION_BUILD_DIR=build/Debug-iphonesimulator \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    
    APP_PATH="build/Debug-iphonesimulator/LifeLens.app"
    
    if [ -d "$APP_PATH" ]; then
        echo "App location: $APP_PATH"
        
        # Check app bundle
        if [ -f "$APP_PATH/Info.plist" ]; then
            echo "✅ Info.plist found"
        else
            echo "⚠️ Info.plist missing"
        fi
        
        # Find a simulator
        DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 15" | head -1 | awk -F'[()]' '{print $2}')
        
        if [ -n "$DEVICE_ID" ]; then
            echo "Using simulator: $DEVICE_ID"
            
            # Boot simulator
            xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
            sleep 3
            
            # Open Simulator
            open -a Simulator
            
            # Install app
            echo "Installing app..."
            xcrun simctl install "$DEVICE_ID" "$APP_PATH"
            
            if [ $? -eq 0 ]; then
                # Launch app
                echo "Launching LifeLens..."
                xcrun simctl launch "$DEVICE_ID" com.Prevenza.LifeLens || xcrun simctl launch "$DEVICE_ID" com.lifelens.app
                
                echo "✅ App is running!"
            else
                echo "❌ Failed to install app"
            fi
        else
            echo "❌ No simulator found"
        fi
    else
        echo "❌ App bundle not found"
        find build -name "*.app" -type d
    fi
else
    echo "❌ Build failed"
fi