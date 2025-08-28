#!/bin/bash

echo "🔧 Force iOS 18.2 Build"
echo "======================="
echo ""

# Clean first
rm -rf DerivedData build

# List available simulators with iOS 18.2
echo "📱 Finding iOS 18.2 simulators..."
SIM_ID=$(xcrun simctl list devices available | grep "iPhone.*18\.2" | head -1 | grep -o "[A-F0-9-]*)")

if [ -z "$SIM_ID" ]; then
    echo "Creating new iOS 18.2 simulator..."
    # Use the iOS 18.2 runtime we have
    SIM_ID=$(xcrun simctl create "iPhone 15 Pro iOS 18.2" \
        "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" \
        "com.apple.CoreSimulator.SimRuntime.iOS-18-2")
fi

echo "Using simulator: $SIM_ID"

# Boot simulator
xcrun simctl boot "$SIM_ID" 2>/dev/null || true

# Build with generic iOS simulator SDK (not version specific)
echo ""
echo "🔨 Building with generic SDK..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=17.5 \
  EXCLUDED_ARCHS="" \
  ARCHS="x86_64" \
  VALID_ARCHS="x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  build 2>&1 | tee build_generic.log

# Check result
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    APP_PATH=$(find DerivedData -name "*.app" -type d | head -1)
    echo "App built at: $APP_PATH"
    
    # Install to simulator
    if [ -n "$APP_PATH" ] && [ -n "$SIM_ID" ]; then
        echo "Installing to simulator..."
        xcrun simctl install "$SIM_ID" "$APP_PATH"
        echo "Launching app..."
        xcrun simctl launch "$SIM_ID" com.lifelens.app
    fi
else
    echo ""
    echo "❌ Generic build failed. Trying direct compilation..."
    
    # Try direct Swift compilation as last resort
    echo ""
    echo "🔨 Attempting direct Swift build..."
    
    cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens
    
    # Create build directory
    mkdir -p build/Debug-iphonesimulator
    
    # Compile Swift files directly
    swiftc -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) \
           -target x86_64-apple-ios17.5-simulator \
           -emit-executable \
           -o build/Debug-iphonesimulator/LifeLens \
           -I /Users/basorge/Desktop/LifeLens/Ios/LifeLens \
           -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks \
           LifeLens/*.swift 2>&1 | head -20
fi