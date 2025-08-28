#!/bin/bash

echo "🔧 iOS 17.5 Download and Fix Script"
echo "===================================="
echo ""

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# 1. Update project to iOS 17.5
echo "📝 Updating project to iOS 17.5..."
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9][0-9]\.[0-9]/IPHONEOS_DEPLOYMENT_TARGET = 17.5/g' LifeLens.xcodeproj/project.pbxproj

# 2. Check current iOS versions
echo ""
echo "📋 Current deployment targets:"
grep "IPHONEOS_DEPLOYMENT_TARGET" LifeLens.xcodeproj/project.pbxproj | head -3

# 3. Clean everything
echo ""
echo "🧹 Deep cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf build DerivedData
killall Simulator 2>/dev/null

# 4. Try to download iOS 17.5 using brew xcodes
echo ""
echo "📥 Attempting to install iOS 17.5..."

# Install xcodes if not present
if ! command -v xcodes &> /dev/null; then
    echo "Installing xcodes tool..."
    brew install xcodesorg/made/xcodes
fi

# List available runtimes
echo ""
echo "Available iOS runtimes:"
xcodes runtimes list | grep -i ios | head -10

# Try to install iOS 17.5
echo ""
echo "Downloading iOS 17.5 runtime (this may take a while)..."
xcodes runtimes install "iOS 17.5" 2>&1 | head -20 || {
    echo "Direct download failed, trying alternative..."
    
    # Alternative: Download from Apple
    echo "Downloading from Apple servers..."
    curl -L "https://download.developer.apple.com/Developer_Tools/iOS_17.5_Simulator_Runtime/iOS_17.5_Simulator_Runtime.dmg" \
         -o ~/Downloads/iOS_17.5_Simulator.dmg \
         --progress-bar \
         --max-time 300 2>&1 | head -10 || echo "Download failed"
    
    if [ -f ~/Downloads/iOS_17.5_Simulator.dmg ]; then
        echo "Installing iOS 17.5 from DMG..."
        hdiutil attach ~/Downloads/iOS_17.5_Simulator.dmg
        sudo installer -pkg /Volumes/iOS*.simruntime/*.pkg -target / 2>/dev/null
        hdiutil detach /Volumes/iOS* 2>/dev/null
    fi
}

# 5. List installed runtimes
echo ""
echo "✅ Installed Simulator Runtimes:"
xcrun simctl list runtimes | grep iOS

# 6. Try building with whatever we have
echo ""
echo "🏗️ Attempting build with iOS 17.5..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=17.5 \
  build 2>&1 | tail -20

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build succeeded!"
    APP_PATH=$(find ./DerivedData -name "LifeLens.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        echo "📱 App built at: $APP_PATH"
    fi
else
    echo ""
    echo "❌ Build still failing"
    echo ""
    echo "Manual steps required:"
    echo "1. Open Xcode"
    echo "2. Go to Settings → Platforms"
    echo "3. Click + and select iOS 17.5"
    echo "4. Wait for download to complete"
    echo "5. Run this script again"
fi