#!/bin/bash

# Build and test the iOS app
echo "======================================"
echo "Building LifeLens iOS App"
echo "======================================"

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean build folder
echo "Cleaning build folder..."
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/*LifeLens*

# Build for generic iOS device (no simulator needed)
echo "Building for iOS..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -sdk iphoneos18.5 \
    -derivedDataPath build/ \
    -destination 'generic/platform=iOS' \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO \
    -quiet \
    build 2>&1 | tee build.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Build successful!"
    echo "Build artifacts available in: build/"
else
    echo "❌ Build failed. Check build.log for details"
    echo ""
    echo "Common errors found:"
    grep -E "error:|warning:" build.log | head -20
    exit 1
fi

# Try to build for simulator if available
echo ""
echo "Attempting simulator build..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -sdk iphonesimulator18.5 \
    -derivedDataPath build-sim/ \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO \
    -quiet \
    build 2>&1 | tee build-sim.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Simulator build successful!"
else
    echo "⚠️  Simulator build failed (this is okay if you don't have the right simulator installed)"
fi

echo ""
echo "======================================"
echo "Build Summary"
echo "======================================"
echo "✅ iOS Device Build: SUCCESS"
echo "📁 Build Location: $(pwd)/build/"
echo ""
echo "To run on a device:"
echo "1. Open Xcode"
echo "2. Select your device"
echo "3. Run the app"