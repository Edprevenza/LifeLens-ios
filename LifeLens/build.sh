#!/bin/bash

echo "Building LifeLens without code signing..."

# Clean build folder
rm -rf build/

# Build for simulator without code signing
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath ./build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGN_ENTITLEMENTS="" \
  EXPANDED_CODE_SIGN_IDENTITY="" \
  EXPANDED_CODE_SIGN_IDENTITY_NAME=""

echo "Build complete!"