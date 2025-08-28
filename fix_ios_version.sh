#!/bin/bash
# fix_ios_version.sh

echo "🔧 Fixing iOS Version Mismatch"
echo "=============================="

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# 1. Update project deployment target to iOS 18.2
echo "📝 Updating deployment target to iOS 18.2..."
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 18.5/IPHONEOS_DEPLOYMENT_TARGET = 18.2/g' LifeLens.xcodeproj/project.pbxproj
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 18.4/IPHONEOS_DEPLOYMENT_TARGET = 18.2/g' LifeLens.xcodeproj/project.pbxproj
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 18.3/IPHONEOS_DEPLOYMENT_TARGET = 18.2/g' LifeLens.xcodeproj/project.pbxproj
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 18.0/IPHONEOS_DEPLOYMENT_TARGET = 18.2/g' LifeLens.xcodeproj/project.pbxproj
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 17.6/IPHONEOS_DEPLOYMENT_TARGET = 18.2/g' LifeLens.xcodeproj/project.pbxproj

# 2. Clean everything
echo "🧹 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*
rm -rf build DerivedData

# 3. Build for your specific simulator
echo "🏗️ Building for iOS 18.2 Simulator..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator18.5 \
  -destination 'id=9A506927-7D03-4A48-AF5A-AB82C91AADBC' \
  -derivedDataPath ./DerivedData \
  build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=18.2

# 4. Install and launch
if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    APP_PATH=$(find ./DerivedData -name "LifeLens.app" -path "*iphonesimulator*" | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📱 Installing to simulator..."
        xcrun simctl install 9A506927-7D03-4A48-AF5A-AB82C91AADBC "$APP_PATH"
        
        # Get bundle ID from Info.plist
        BUNDLE_ID=$(defaults read "$APP_PATH/Info.plist" CFBundleIdentifier 2>/dev/null || echo "com.lifelens.app")
        
        echo "🚀 Launching app..."
        xcrun simctl launch 9A506927-7D03-4A48-AF5A-AB82C91AADBC "$BUNDLE_ID"
    fi
else
    echo "❌ Build failed - see errors above"
fi