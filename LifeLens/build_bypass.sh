#!/bin/bash
cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Use iOS 17.5 runtime with 18.2 simulator
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,OS=17.5' \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=17.5 \
  build
