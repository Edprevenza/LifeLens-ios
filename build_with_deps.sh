#!/bin/bash

echo "=== LifeLens Build with Dependencies ==="
echo "This script ensures all dependencies are properly resolved and builds the app"

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean build folder
echo "🧹 Cleaning build folder..."
rm -rf build

# Resolve dependencies first
echo "📦 Resolving package dependencies..."
xcodebuild -resolvePackageDependencies \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -clonedSourcePackagesDirPath ./SourcePackages \
    -derivedDataPath ./build

if [ $? -ne 0 ]; then
    echo "❌ Failed to resolve dependencies"
    exit 1
fi

echo "✅ Dependencies resolved successfully"

# Get simulator
echo "🔍 Finding simulator..."
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -o -E '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No iPhone simulator found"
    exit 1
fi

SIMULATOR_NAME=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | sed 's/ (.*//' | sed 's/^[[:space:]]*//')
echo "✅ Using: $SIMULATOR_NAME ($SIMULATOR_ID)"

# Boot simulator
echo "🚀 Booting simulator..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
open -a Simulator

# Build the app
echo "🔨 Building LifeLens..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath ./build \
    -clonedSourcePackagesDirPath ./SourcePackages \
    IPHONEOS_DEPLOYMENT_TARGET=18.2 \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO \
    build 2>&1 | tee build.log | grep -E "^(=== |Build |Compiling |Linking |Touch |Create |Copy |Sign |Process |PhaseScript |CodeSign |▸ |✓ |⚠ |❌ |error:|warning:|note:|\*\*)"

BUILD_RESULT=${PIPESTATUS[0]}

if [ $BUILD_RESULT -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the app
    APP_PATH=$(find ./build -name "LifeLens.app" -type d | grep -v "\.xctest" | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📱 Installing app..."
        
        # Uninstall old version
        xcrun simctl uninstall "$SIMULATOR_ID" com.lifelens.LifeLens 2>/dev/null || true
        
        # Install new version
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        
        # Launch
        echo "🚀 Launching LifeLens..."
        xcrun simctl launch "$SIMULATOR_ID" com.lifelens.LifeLens
        
        echo ""
        echo "✅ Success! LifeLens is running"
        echo "   Simulator: $SIMULATOR_NAME"
        echo "   Bundle ID: com.lifelens.LifeLens"
    else
        echo "❌ App not found in build directory"
    fi
else
    echo ""
    echo "❌ Build failed. Check build.log for details"
    echo "Common issues:"
    echo "  • iOS deployment target mismatch"
    echo "  • Missing dependencies"
    echo "  • Code signing issues"
    echo ""
    echo "Last 20 lines of error:"
    tail -20 build.log | grep -E "error:|warning:"
fi