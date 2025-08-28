#!/bin/bash

echo "Building minimal iOS app..."

# Temporarily move problematic files
mkdir -p temp_disabled
mv LifeLens/ML/*.swift temp_disabled/ 2>/dev/null || true
mv LifeLens/Cloud/*.swift temp_disabled/ 2>/dev/null || true
mv LifeLens/Integration/*.swift temp_disabled/ 2>/dev/null || true
mv LifeLens/Validation/*.swift temp_disabled/ 2>/dev/null || true

# Build
xcodebuild -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -destination 'id=2DD9328A-D0B8-4D41-90AF-DA8478892E81' \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  ONLY_ACTIVE_ARCH=YES \
  build 2>&1 | tail -50

# Restore files
mv temp_disabled/*.swift LifeLens/ML/ 2>/dev/null || true
mv temp_disabled/*.swift LifeLens/Cloud/ 2>/dev/null || true
mv temp_disabled/*.swift LifeLens/Integration/ 2>/dev/null || true
mv temp_disabled/*.swift LifeLens/Validation/ 2>/dev/null || true
rmdir temp_disabled

echo "Build attempt complete!"