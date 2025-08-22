#!/bin/bash

# Build LifeLens from command line
echo "Building LifeLens..."

# Clean previous builds
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/*LifeLens*

# Build for simulator
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 15' \
    -derivedDataPath build/ \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "App location: $(pwd)/build/Build/Products/Debug-iphonesimulator/LifeLens.app"
else
    echo "❌ Build failed"
    exit 1
fi
