#!/bin/bash

echo "🔧 iOS Simulator Build - Final Solution"
echo "========================================"
echo ""

# Navigate to project directory  
cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# Clean everything
echo "🧹 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*
rm -rf build DerivedData
echo ""

echo "⚠️  IMPORTANT: iOS 18.5 platform is not installed on this system."
echo "    The build requires iOS 18.5 SDK to be installed."
echo ""
echo "    To fix this issue, you have two options:"
echo ""
echo "    Option 1: Install iOS 18.5 platform (recommended)"
echo "    ------------------------------------------------"
echo "    Open Xcode > Settings > Platforms > + button > iOS 18.5"
echo "    Or run: sudo xcodebuild -downloadPlatform iOS"
echo ""
echo "    Option 2: Modify project to use older iOS version"
echo "    -------------------------------------------------"
echo "    Open LifeLens.xcodeproj in Xcode"
echo "    Change iOS Deployment Target to 17.0 or lower"
echo "    Change Base SDK to 'Latest iOS'"
echo ""

# Try one more build attempt with forced SDK override
echo "🔄 Attempting build with SDK override..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphoneos \
  -derivedDataPath ./DerivedData \
  build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=NO \
  IPHONEOS_DEPLOYMENT_TARGET=17.0 \
  -destination 'generic/platform=iOS' 2>&1 | tail -20

echo ""
echo "❌ Build cannot proceed without iOS 18.5 platform installed."
echo "   Please install the iOS platform using one of the methods above."