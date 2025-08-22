#!/bin/bash

echo "Building LifeLens iOS App with recent changes..."
echo "=============================================="

# Clean build folder
echo "Cleaning build folder..."
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*

# Navigate to project directory
cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Build for generic iOS simulator device
echo "Building for iOS Simulator..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination generic/platform=iOS\ Simulator \
    IPHONEOS_DEPLOYMENT_TARGET=17.0 \
    build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ iOS app built successfully!"
    echo ""
    echo "Key changes included in this build:"
    echo "- ✅ Unauthorized access dialog added"
    echo "- ✅ 'Registration Required' alert for new users"
    echo "- ✅ Clear benefits messaging"
    echo "- ✅ Register Now and Sign In buttons"
    echo "- ✅ Session expiry handling"
    echo ""
    echo "Build location: ~/Library/Developer/Xcode/DerivedData/LifeLens-*/Build/Products/Debug-iphonesimulator/"
else
    echo "❌ Build failed. Please check the error messages above."
fi