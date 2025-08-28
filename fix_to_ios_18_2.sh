#!/bin/bash
# fix_to_ios_18_2.sh

echo "🔧 Updating Project to iOS 18.2"
echo "================================"

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# 1. Update ALL iOS version references in project file
echo "📝 Updating all iOS deployment targets to 18.2..."
sed -i '' 's/18\.5/18.2/g' LifeLens.xcodeproj/project.pbxproj
sed -i '' 's/18\.6/18.2/g' LifeLens.xcodeproj/project.pbxproj
sed -i '' 's/18\.4/18.2/g' LifeLens.xcodeproj/project.pbxproj
sed -i '' 's/18\.3/18.2/g' LifeLens.xcodeproj/project.pbxproj

# 2. Update xcscheme files if they exist
echo "📝 Updating scheme files..."
find . -name "*.xcscheme" -exec sed -i '' 's/18\.5/18.2/g' {} \; 2>/dev/null
find . -name "*.xcscheme" -exec sed -i '' 's/18\.6/18.2/g' {} \; 2>/dev/null

# 3. Clean everything
echo "🧹 Cleaning all build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*
rm -rf build DerivedData
xcodebuild clean -quiet 2>/dev/null || true

# 4. Build using the iOS 18.2 SDK
echo "🏗️ Building for iOS 18.2 Simulator..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=18.2 \
  build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    
    # Find the app
    APP_PATH=$(find ./DerivedData -name "LifeLens.app" -path "*iphonesimulator*" | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📱 App built at: $APP_PATH"
        
        # Install to simulator
        echo "📲 Installing to simulator..."
        SIMULATOR_ID="9A506927-7D03-4A48-AF5A-AB82C91AADBC"
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        
        # Get bundle ID
        BUNDLE_ID=$(defaults read "$APP_PATH/Info.plist" CFBundleIdentifier 2>/dev/null)
        
        if [ -n "$BUNDLE_ID" ]; then
            echo "🚀 Launching $BUNDLE_ID..."
            xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"
        else
            echo "⚠️ Could not determine bundle ID"
        fi
    fi
else
    echo "❌ Build failed"
    echo ""
    echo "🔄 Trying alternative approach without specific destination..."
    
    xcodebuild \
      -project LifeLens.xcodeproj \
      -scheme LifeLens \
      -configuration Debug \
      -sdk iphonesimulator \
      -derivedDataPath ./DerivedData \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      ONLY_ACTIVE_ARCH=NO \
      IPHONEOS_DEPLOYMENT_TARGET=18.2 \
      build
    
    if [ $? -eq 0 ]; then
        echo "✅ Alternative build succeeded!"
        APP_PATH=$(find ./DerivedData -name "LifeLens.app" -type d | head -1)
        if [ -n "$APP_PATH" ]; then
            echo "📱 App built at: $APP_PATH"
        fi
    else
        echo ""
        echo "Alternative: Open Xcode and manually change:"
        echo "1. Select project in navigator"
        echo "2. Go to Build Settings"
        echo "3. Search for 'iOS Deployment Target'"
        echo "4. Change to 18.2"
        echo "5. Clean and build"
    fi
fi