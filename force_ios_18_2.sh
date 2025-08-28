#!/bin/bash
# force_ios_18_2.sh

echo "🔧 FORCE Updating to iOS 18.2"
echo "=============================="

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# 1. More aggressive replacement of iOS versions
echo "📝 Force updating all iOS references to 18.2..."
find . -name "*.pbxproj" -exec sed -i '' 's/18\.[3-9]/18.2/g' {} \;
find . -name "*.xcscheme" -exec sed -i '' 's/18\.[3-9]/18.2/g' {} \; 2>/dev/null
find . -name "*.plist" -exec sed -i '' 's/18\.[3-9]/18.2/g' {} \; 2>/dev/null
find . -name "*.xcconfig" -exec sed -i '' 's/18\.[3-9]/18.2/g' {} \; 2>/dev/null

# 2. Specifically target IPHONEOS_DEPLOYMENT_TARGET
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9][0-9]\.[0-9]/IPHONEOS_DEPLOYMENT_TARGET = 18.2/g' LifeLens.xcodeproj/project.pbxproj

# 3. Clean EVERYTHING
echo "🧹 Deep cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf build DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# 4. Reset simulator
echo "🔄 Resetting simulators..."
xcrun simctl shutdown all 2>/dev/null
xcrun simctl erase all 2>/dev/null

# 5. Build without specifying OS version
echo "🏗️ Building with generic destination..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=18.2 \
  TARGETED_DEVICE_FAMILY="1,2" \
  VALID_ARCHS="x86_64 arm64" \
  build

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Build still failing. Trying alternative approach..."
    echo ""
    
    # Try building without any destination
    xcodebuild \
      -project LifeLens.xcodeproj \
      -scheme LifeLens \
      -configuration Debug \
      -sdk iphonesimulator \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      ONLY_ACTIVE_ARCH=NO \
      IPHONEOS_DEPLOYMENT_TARGET=18.2 \
      build
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build succeeded!"
    
    # Find the app
    APP_PATH=$(find . -name "LifeLens.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        echo "📱 App found at: $APP_PATH"
        
        # Try to install to available simulator
        SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | grep "18.2" | head -1 | grep -o "[A-F0-9-]\{36\}")
        if [ -n "$SIMULATOR_ID" ]; then
            echo "📲 Installing to simulator $SIMULATOR_ID..."
            xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
            
            # Launch
            BUNDLE_ID=$(defaults read "$APP_PATH/Info.plist" CFBundleIdentifier 2>/dev/null)
            if [ -n "$BUNDLE_ID" ]; then
                xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"
            fi
        fi
    fi
else
    echo ""
    echo "❌ Build failed. The issue is likely that iOS platform files are not installed."
    echo ""
    echo "📋 Current iOS versions in project:"
    grep -h "IPHONEOS_DEPLOYMENT_TARGET" LifeLens.xcodeproj/project.pbxproj | sort -u
    echo ""
    echo "🔧 Manual fix required:"
    echo "1. Open Xcode"
    echo "2. Go to Settings > Platforms"
    echo "3. Install iOS platform files"
    echo "4. Or open the project in Xcode and let it download required components"
fi