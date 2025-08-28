#!/bin/bash

echo "Quick build with minimal features..."

# Build with only essential files
xcodebuild -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -destination 'id=2DD9328A-D0B8-4D41-90AF-DA8478892E81' \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  ONLY_ACTIVE_ARCH=YES \
  GCC_PREPROCESSOR_DEFINITIONS='DEBUG=1 MINIMAL_BUILD=1' \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG MINIMAL_BUILD' \
  -derivedDataPath build \
  build 2>&1 | tail -100

echo "Build complete!"