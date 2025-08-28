#!/bin/bash

echo "🚀 iOS App Builder"
echo "=================="
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# Clean build folder
echo "🧹 Cleaning build artifacts..."
rm -rf DerivedData build

# Build for iOS Simulator using the available SDK
echo "🏗️ Building iOS app..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=18.2 \
  build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build succeeded!"
    
    # Find the app
    APP_PATH=$(find ./DerivedData -name "LifeLens.app" -path "*iphonesimulator*" | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📱 App built at: $APP_PATH"
        
        # Get the booted simulator
        BOOTED_SIM=$(xcrun simctl list devices | grep "Booted" | grep -o "[A-F0-9-]\{36\}" | head -1)
        
        if [ -n "$BOOTED_SIM" ]; then
            echo "📲 Installing to simulator $BOOTED_SIM..."
            xcrun simctl install "$BOOTED_SIM" "$APP_PATH"
            
            # Get bundle ID and launch
            BUNDLE_ID=$(defaults read "$APP_PATH/Info.plist" CFBundleIdentifier 2>/dev/null || echo "com.prevenza.LifeLens")
            
            echo "🚀 Launching $BUNDLE_ID..."
            xcrun simctl launch "$BOOTED_SIM" "$BUNDLE_ID"
            
            echo ""
            echo "✅ App launched successfully!"
        else
            echo "⚠️ No booted simulator found. Boot one with:"
            echo "   xcrun simctl boot [device-id]"
        fi
    else
        echo "⚠️ App bundle not found"
    fi
else
    echo ""
    echo "❌ Build failed"
    echo ""
    echo "Trying without destination specification..."
    
    xcodebuild \
      -project LifeLens.xcodeproj \
      -scheme LifeLens \
      -configuration Debug \
      -sdk iphonesimulator \
      -derivedDataPath ./DerivedData \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      IPHONEOS_DEPLOYMENT_TARGET=18.2 \
      build
fi
