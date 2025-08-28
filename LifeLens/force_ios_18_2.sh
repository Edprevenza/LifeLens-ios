#!/bin/bash
echo "Forcing project to use iOS 18.2..."

# Change any iOS deployment target to 18.2
perl -pi -e 's/IPHONEOS_DEPLOYMENT_TARGET = 18\.[3-9]/IPHONEOS_DEPLOYMENT_TARGET = 18.2/g' LifeLens.xcodeproj/project.pbxproj
perl -pi -e 's/IPHONEOS_DEPLOYMENT_TARGET = 17\.[0-9]/IPHONEOS_DEPLOYMENT_TARGET = 18.2/g' LifeLens.xcodeproj/project.pbxproj

# Remove specific SDK versions
perl -pi -e 's/SDKROOT = iphoneos18\.[3-9]/SDKROOT = iphoneos18.2/g' LifeLens.xcodeproj/project.pbxproj
perl -pi -e 's/SDKROOT = iphonesimulator18\.[3-9]/SDKROOT = iphonesimulator18.2/g' LifeLens.xcodeproj/project.pbxproj

echo "Done! Project now uses iOS 18.2"
