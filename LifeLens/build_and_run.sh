#!/bin/bash
echo "Building LifeLens iOS app..."
xcodebuild -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath ./DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  build

echo "Installing and launching..."
xcrun simctl terminate booted com.Prevenza.LifeLens 2>/dev/null
xcrun simctl install booted ./DerivedData/Build/Products/Debug-iphonesimulator/LifeLens.app
xcrun simctl launch booted com.Prevenza.LifeLens
