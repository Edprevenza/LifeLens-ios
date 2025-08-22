#!/bin/bash

echo "🚀 Deploying LifeLens to iOS 18.2 Simulator"
echo "==========================================="

# Configuration
PROJECT_DIR="/Users/basorge/Desktop/LifeLens/Ios/LifeLens"
DEVICE_ID="5B940E66-0B42-46AD-B289-31C38A9A8DFC"  # iPhone 16 Pro Max

cd "$PROJECT_DIR"

# Clean everything
echo "🧹 Cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*
rm -rf build DerivedData

# Build using iOS 16 minimum (compatible with iOS 18.2)
echo "🔨 Building for iOS 18.2..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -target LifeLens \
    -configuration Debug \
    -sdk iphonesimulator \
    IPHONEOS_DEPLOYMENT_TARGET=16.0 \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO \
    VALID_ARCHS="x86_64 arm64" \
    ARCHS="x86_64 arm64" \
    build 2>&1 | grep -E "BUILD|error" | tail -20

# Check result
if [ -d "build/Debug-iphonesimulator/LifeLens.app" ]; then
    echo "✅ Build successful!"
    APP_PATH="build/Debug-iphonesimulator/LifeLens.app"
    
    # Ensure simulator is booted
    echo "📱 Starting simulator..."
    xcrun simctl boot $DEVICE_ID 2>/dev/null || true
    open -a Simulator
    
    # Uninstall old version
    xcrun simctl uninstall $DEVICE_ID com.prevenza.LifeLens 2>/dev/null || true
    
    # Install new version
    echo "📲 Installing app..."
    xcrun simctl install $DEVICE_ID "$APP_PATH"
    
    # Launch app
    echo "🎯 Launching LifeLens..."
    xcrun simctl launch $DEVICE_ID com.prevenza.LifeLens
    
    echo "✨ Success! LifeLens is running on iOS 18.2"
else
    echo "❌ Build failed. Trying alternative approach..."
    
    # Alternative: Try to compile just the Swift files
    echo "🔧 Attempting direct Swift compilation..."
    
    mkdir -p build/alt
    
    # Compile Swift files directly
    xcrun swiftc \
        -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
        -target x86_64-apple-ios16.0-simulator \
        -emit-executable \
        -o build/alt/LifeLens \
        LifeLens/*.swift \
        LifeLens/**/*.swift 2>&1 | head -20 || true
        
    echo "Check Xcode directly or use: open $PROJECT_DIR/LifeLens.xcodeproj"
fi