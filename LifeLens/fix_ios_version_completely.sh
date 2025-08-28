#!/bin/bash

echo "Fixing iOS version requirements..."

# Update project file to use iOS 17.0 (works with any iOS 17+)
perl -pi -e 's/IPHONEOS_DEPLOYMENT_TARGET = \d+\.\d+/IPHONEOS_DEPLOYMENT_TARGET = 17.0/g' LifeLens.xcodeproj/project.pbxproj

# Remove specific SDK versions
perl -pi -e 's/SDKROOT = iphoneos\d+\.\d+/SDKROOT = iphoneos/g' LifeLens.xcodeproj/project.pbxproj
perl -pi -e 's/SDKROOT = iphonesimulator\d+\.\d+/SDKROOT = iphonesimulator/g' LifeLens.xcodeproj/project.pbxproj

# Fix any LastUpgradeCheck references
perl -pi -e 's/LastUpgradeCheck = \d+/LastUpgradeCheck = 1540/g' LifeLens.xcodeproj/project.pbxproj

echo "Changes made. Cleaning..."

# Clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf build
rm -rf DerivedData

echo "Done! Now open Xcode and run."
