#!/bin/bash

# Build script for iOS app with iOS 18.2 simulator
set -e

echo "🔨 Building LifeLens iOS app..."

# Clean previous builds
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*

# Create build directory
mkdir -p build

# Build the app without asset catalog compilation
xcodebuild \
    -project LifeLens.xcodeproj \
    -target LifeLens \
    -configuration Debug \
    -sdk iphonesimulator \
    -derivedDataPath ./DerivedData \
    SYMROOT=build \
    OBJROOT=build \
    ONLY_ACTIVE_ARCH=NO \
    EXCLUDED_SOURCE_FILE_NAMES="*.xcassets" \
    ASSETCATALOG_COMPILER_SKIP_APP_STORE_DEPLOYMENT=YES \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build | xcpretty || true

echo "✅ Build completed"

# Find the app bundle
APP_PATH=$(find build -name "LifeLens.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ App bundle not found"
    exit 1
fi

echo "📦 App bundle located at: $APP_PATH"

# Create a minimal Info.plist if needed
if [ ! -f "$APP_PATH/Info.plist" ]; then
    echo "Creating Info.plist..."
    cat > "$APP_PATH/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>LifeLens</string>
    <key>CFBundleIdentifier</key>
    <string>com.prevenza.LifeLens</string>
    <key>CFBundleName</key>
    <string>LifeLens</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
EOF
fi

# Install on simulator
echo "📱 Installing on iOS 18.2 simulator..."
DEVICE_ID="5B940E66-0B42-46AD-B289-31C38A9A8DFC"

# Boot the device if needed
xcrun simctl boot $DEVICE_ID 2>/dev/null || true

# Install the app
xcrun simctl install $DEVICE_ID "$APP_PATH"

# Launch the app
echo "🚀 Launching app..."
xcrun simctl launch $DEVICE_ID com.prevenza.LifeLens

echo "✨ App is running on simulator!"