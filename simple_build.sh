#!/bin/bash

echo "🔧 Simple iOS Build"
echo "==================="

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens || exit 1

# Clean
echo "🧹 Cleaning..."
rm -rf DerivedData

# Build without destination (let Xcode figure it out)
echo "🏗️ Building..."
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -derivedDataPath ./DerivedData \
  build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  ONLY_ACTIVE_ARCH=NO

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    find ./DerivedData -name "*.app" -type d | head -1
else
    echo "❌ Build failed"
fi
