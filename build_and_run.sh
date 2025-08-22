#!/bin/bash

echo "🔨 Building LifeLens iOS App (iOS 18.2 Compatible)"
echo "================================================="

# Configuration
PROJECT_DIR="/Users/basorge/Desktop/LifeLens/Ios/LifeLens"
SIMULATOR_ID="5B940E66-0B42-46AD-B289-31C38A9A8DFC"  # iPhone 16 Pro Max

cd "$PROJECT_DIR"

# Clean everything
echo "🧹 Cleaning previous builds..."
rm -rf build DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*

# Create minimal Assets.xcassets if needed
if [ ! -f "LifeLens/Assets.xcassets/Contents.json" ]; then
    echo "📦 Creating minimal assets..."
    mkdir -p LifeLens/Assets.xcassets/AppIcon.appiconset
    mkdir -p LifeLens/Assets.xcassets/AccentColor.colorset
    
    cat > LifeLens/Assets.xcassets/Contents.json << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

    cat > LifeLens/Assets.xcassets/AppIcon.appiconset/Contents.json << 'EOF'
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

    cat > LifeLens/Assets.xcassets/AccentColor.colorset/Contents.json << 'EOF'
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.575",
          "green" : "0.106",
          "red" : "0.324"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
fi

# Build the app
echo "🔨 Building app..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -sdk iphonesimulator \
    -derivedDataPath ./DerivedData \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    COMPILER_INDEX_STORE_ENABLE=NO \
    build 2>&1 | grep -E "(BUILD|Compiling|Succeeded|Failed|error:)" | tail -100

# Check if build succeeded
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Build failed. Trying alternative approach..."
    
    # Try building without asset catalog
    echo "🔨 Building without asset catalog..."
    xcodebuild \
        -project LifeLens.xcodeproj \
        -target LifeLens \
        -configuration Debug \
        -sdk iphonesimulator \
        -derivedDataPath ./DerivedData \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        ASSETCATALOG_COMPILER_SKIP_APP_STORE_DEPLOYMENT=YES \
        build
fi

# Find the built app
APP_PATH=$(find DerivedData -name "LifeLens.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    # Try alternative location
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/LifeLens-*/Build/Products -name "LifeLens.app" -type d 2>/dev/null | head -1)
fi

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built app"
    exit 1
fi

echo "✅ App built at: $APP_PATH"

# Create Info.plist if missing
if [ ! -f "$APP_PATH/Info.plist" ]; then
    echo "📝 Creating Info.plist..."
    cat > "$APP_PATH/Info.plist" << 'EOF'
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
    <key>CFBundleDisplayName</key>
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
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>NSHealthShareUsageDescription</key>
    <string>Read health data for comprehensive monitoring</string>
    <key>NSHealthUpdateUsageDescription</key>
    <string>Update health data for comprehensive monitoring</string>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Connect to LifeLens wearable device for health monitoring</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Location access is required for emergency services</string>
</dict>
</plist>
EOF
fi

# Copy executable if missing
if [ ! -f "$APP_PATH/LifeLens" ]; then
    echo "📦 Looking for executable..."
    EXEC_PATH=$(find DerivedData -name "LifeLens" -type f -perm +111 | grep -v ".app" | head -1)
    if [ -n "$EXEC_PATH" ]; then
        cp "$EXEC_PATH" "$APP_PATH/LifeLens"
        chmod +x "$APP_PATH/LifeLens"
    fi
fi

# Boot simulator
echo "📱 Booting iPhone 16 Pro Max simulator..."
xcrun simctl boot $SIMULATOR_ID 2>/dev/null || true

# Open Simulator app
open -a Simulator

# Wait for simulator to be ready
echo "⏳ Waiting for simulator..."
sleep 3

# Uninstall old version if exists
echo "🗑️ Removing old app version..."
xcrun simctl uninstall $SIMULATOR_ID com.prevenza.LifeLens 2>/dev/null || true

# Install the app
echo "📲 Installing app on simulator..."
xcrun simctl install $SIMULATOR_ID "$APP_PATH"

# Launch the app
echo "🚀 Launching LifeLens..."
xcrun simctl launch --console $SIMULATOR_ID com.prevenza.LifeLens

echo "✨ LifeLens iOS app is running!"
echo "📱 Simulator: iPhone 16 Pro Max (iOS 18.2)"
echo "🔍 Check the Simulator window to see the app"