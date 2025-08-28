#!/bin/bash

# Remove ALL specific iOS version requirements
echo "Removing all iOS version requirements..."

# Set to iOS 17.0 minimum (works with any iOS 17+)
find . -name "*.pbxproj" -exec sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9][0-9]\.[0-9]/IPHONEOS_DEPLOYMENT_TARGET = 17.0/g' {} \;

# Remove SDK version specifications
find . -name "*.pbxproj" -exec sed -i '' 's/SDKROOT = iphoneos[0-9][0-9]\.[0-9]/SDKROOT = iphoneos/g' {} \;
find . -name "*.pbxproj" -exec sed -i '' 's/SDKROOT = iphonesimulator[0-9][0-9]\.[0-9]/SDKROOT = iphonesimulator/g' {} \;

# Fix Base SDK
find . -name "*.pbxproj" -exec sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 18.5/IPHONEOS_DEPLOYMENT_TARGET = 17.0/g' {} \;

# Remove LastUpgradeCheck that might force iOS 18.5
find . -name "*.pbxproj" -exec sed -i '' 's/LastUpgradeCheck = [0-9]*/LastUpgradeCheck = 1540/g' {} \;

echo "Fixed! Now reopening Xcode..."
