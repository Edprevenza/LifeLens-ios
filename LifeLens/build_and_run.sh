#!/bin/bash

echo "======================================"
echo "🔨 Building LifeLens for iOS"
echo "======================================"

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*LifeLens*
rm -rf build/

# Set build directory
BUILD_DIR="build"

# Build for iPhone 16 Pro Max with iOS 18.2
echo "Building for iPhone 16 Pro Max (iOS 18.2)..."

# First, let's create a simple build without specifying iOS version
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -sdk iphonesimulator \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    IPHONEOS_DEPLOYMENT_TARGET=17.0 \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    
    # Find the app
    APP_PATH=$(find "$BUILD_DIR" -name "LifeLens.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📱 App built at: $APP_PATH"
        
        # Boot simulator if needed
        DEVICE_ID="5B940E66-0B42-46AD-B289-31C38A9A8DFC"
        echo "Booting simulator..."
        xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
        
        # Install and launch
        echo "Installing app..."
        xcrun simctl install "$DEVICE_ID" "$APP_PATH"
        
        echo "Launching app..."
        xcrun simctl launch "$DEVICE_ID" com.prevenza.LifeLens
        
        echo "✅ App is running!"
    else
        echo "⚠️ Could not find built app"
    fi
else
    echo "❌ Build failed"
    echo ""
    echo "Try these steps in Xcode:"
    echo "1. Open LifeLens.xcodeproj"
    echo "2. When prompted about iOS 18.5, click 'Cancel'"
    echo "3. Select Product → Scheme → Edit Scheme"
    echo "4. Under 'Run' → 'Info' → 'Executable', select 'LifeLens.app'"
    echo "5. Under 'Run' → 'Info' → 'Build Configuration', select 'Debug'"
    echo "6. Close scheme editor"
    echo "7. Select 'Any iOS Simulator Device' from the device menu"
    echo "8. Press ⌘B to build"
fi