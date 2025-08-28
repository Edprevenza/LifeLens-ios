#!/bin/bash

echo "🚀 Build Workaround - Using Installed Runtime"
echo "============================================="
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean
rm -rf DerivedData build
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Export environment to use the iOS 18.2 runtime as 18.5
export DYLD_ROOT_PATH="/Library/Developer/CoreSimulator/Volumes/iOS_22C150/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 18.2.simruntime/Contents/Resources/RuntimeRoot"
export SDKROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
export IPHONEOS_DEPLOYMENT_TARGET="17.5"

# Create a new Xcode workspace settings file to override SDK version
mkdir -p LifeLens.xcodeproj/project.xcworkspace/xcshareddata
cat > LifeLens.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BuildSystemType</key>
    <string>Latest</string>
    <key>DisableBuildSystemDeprecationDiagnostic</key>
    <true/>
</dict>
</plist>
EOF

# Create xcconfig file to override build settings
cat > override.xcconfig << 'EOF'
IPHONEOS_DEPLOYMENT_TARGET = 17.5
TARGETED_DEVICE_FAMILY = 1,2
SDKROOT = iphonesimulator
SUPPORTED_PLATFORMS = iphonesimulator
VALID_ARCHS = x86_64 arm64
EXCLUDED_ARCHS[sdk=iphonesimulator*] = 
CODE_SIGN_IDENTITY = 
CODE_SIGNING_REQUIRED = NO
CODE_SIGNING_ALLOWED = NO
ENABLE_BITCODE = NO
EOF

echo "📱 Using iOS 18.2 runtime directly..."

# Find or create an iOS 18.2 simulator
SIM_ID=$(xcrun simctl list devices | grep "iPhone.*18\.2" | head -1 | grep -o "[A-F0-9-]*)" | tr -d ')')

if [ -z "$SIM_ID" ]; then
    echo "Creating new iOS 18.2 simulator..."
    SIM_ID=$(xcrun simctl create "iPhone 15 Direct" \
        "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" \
        "com.apple.CoreSimulator.SimRuntime.iOS-18-2")
fi

echo "Using simulator: $SIM_ID"
xcrun simctl boot "$SIM_ID" 2>/dev/null || true

# Build using xcodebuild with config file
echo ""
echo "🔨 Building with override config..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -xcconfig override.xcconfig \
  -destination "id=$SIM_ID" \
  -derivedDataPath ./DerivedData \
  -UseModernBuildSystem=YES \
  build 2>&1 | tee build_workaround.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    APP_PATH=$(find DerivedData -name "*.app" -type d | head -1)
    echo "App: $APP_PATH"
    
    xcrun simctl install "$SIM_ID" "$APP_PATH"
    xcrun simctl launch "$SIM_ID" com.lifelens.LifeLens
else
    echo ""
    echo "❌ Build failed. Trying command line compilation..."
    
    # Try building with Swift directly
    echo ""
    echo "🔨 Direct Swift compilation..."
    
    mkdir -p build
    
    # Get SDK path
    SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
    
    # Find main Swift files (not test files)
    MAIN_FILES=$(find . -name "*.swift" -not -path "./LifeLensTests/*" -not -path "./LifeLensUITests/*" -not -path "./DerivedData/*" -not -path "./build/*" | head -10)
    
    if [ -n "$MAIN_FILES" ]; then
        echo "Compiling Swift files..."
        xcrun -sdk iphonesimulator swiftc \
            -target x86_64-apple-ios17.5-simulator \
            -sdk "$SDK_PATH" \
            $MAIN_FILES \
            -o build/LifeLens 2>&1 | head -20
    else
        echo "No Swift files found in main project"
    fi
fi

# Clean up
rm -f override.xcconfig