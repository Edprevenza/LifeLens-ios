#!/bin/bash

echo "🔧 iOS Build Script - Fixed Version"
echo "===================================="
echo ""

# Navigate to project directory
cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# Clean build directories
echo "🧹 Cleaning build directories..."
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*
rm -rf build DerivedData
echo ""

# Build for generic iOS device (works without simulator runtime)
echo "🏗️ Building for generic iOS device..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath ./DerivedData \
  build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM="" \
  ONLY_ACTIVE_ARCH=NO

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build completed successfully!"
    
    # Find the app
    APP_PATH=$(find ./DerivedData -name "*.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        echo "📱 App built at: $APP_PATH"
        echo ""
        echo "📂 App contents:"
        ls -la "$APP_PATH" | head -10
    else
        echo "⚠️ Build succeeded but app bundle not found"
    fi
else
    echo ""
    echo "❌ Build failed"
    
    # Alternative: Try building without any destination
    echo ""
    echo "🔄 Attempting alternative build approach..."
    xcodebuild \
      -project LifeLens.xcodeproj \
      -scheme LifeLens \
      -configuration Debug \
      -derivedDataPath ./DerivedData \
      build \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      ONLY_ACTIVE_ARCH=NO \
      -destination 'platform=iOS,name=Any iOS Device'
fi

echo ""
echo "🏁 Build script completed"