#!/bin/bash

echo "🔧 Building with Available SDK"
echo "==============================="
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# 1. Check what we actually have
echo "📱 Available SDKs:"
xcodebuild -showsdks | grep -i simulator
echo ""

# 2. Update project to use lower iOS version
echo "📝 Updating project to iOS 17.0 (more compatible)..."
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9][0-9]\.[0-9]/IPHONEOS_DEPLOYMENT_TARGET = 17.0/g' LifeLens.xcodeproj/project.pbxproj

# 3. Clean
echo "🧹 Cleaning..."
rm -rf DerivedData build

# 4. Build for macOS (Designed for iPad) - this avoids iOS simulator requirement
echo "🏗️ Building for macOS (Designed for iPad)..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  SUPPORTS_MACCATALYST=YES \
  build

if [ $? -ne 0 ]; then
    echo ""
    echo "🔄 Trying alternative: Build for generic iOS device..."
    
    # This builds an iOS app that can be installed on a real device
    xcodebuild \
      -project LifeLens.xcodeproj \
      -scheme LifeLens \
      -configuration Debug \
      -sdk iphoneos \
      -destination 'generic/platform=iOS' \
      -derivedDataPath ./DerivedData \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      build
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build succeeded!"
    
    # Find the app
    APP_PATH=$(find ./DerivedData -name "*.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        echo "📱 App built at: $APP_PATH"
        
        # If it's a Mac Catalyst app, we can run it directly
        if [[ "$APP_PATH" == *"maccatalyst"* ]]; then
            echo "🚀 Opening Mac Catalyst app..."
            open "$APP_PATH"
        fi
    fi
else
    echo ""
    echo "❌ Build failed"
    echo ""
    echo "🔧 Workaround options:"
    echo "1. Use Xcode Cloud to build (no local SDK needed)"
    echo "2. Build on a different Mac with iOS SDKs installed"
    echo "3. Try reinstalling Xcode completely"
    echo "4. Download Xcode from developer.apple.com instead of App Store"
fi