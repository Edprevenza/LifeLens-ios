#!/bin/bash

echo "======================================"
echo "🔧 Fixing iOS Version Requirement"
echo "======================================"

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Backup the original project file
cp LifeLens.xcodeproj/project.pbxproj LifeLens.xcodeproj/project.pbxproj.backup

# Update all iOS deployment targets to 18.2
echo "Updating deployment targets to iOS 18.2..."
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 17.0/IPHONEOS_DEPLOYMENT_TARGET = 18.2/g' LifeLens.xcodeproj/project.pbxproj

# Also update any SDK references
sed -i '' 's/iphoneos18.5/iphoneos18.2/g' LifeLens.xcodeproj/project.pbxproj
sed -i '' 's/iphonesimulator18.5/iphonesimulator18.2/g' LifeLens.xcodeproj/project.pbxproj

# Update Info.plist
/usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 18.2" LifeLens/Info.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string 18.2" LifeLens/Info.plist

echo "✅ Updated to iOS 18.2"

# Create an override configuration
cat > ios18.2.xcconfig << 'EOF'
// iOS 18.2 Configuration Override
IPHONEOS_DEPLOYMENT_TARGET = 18.2
SDKROOT = iphoneos
SUPPORTED_PLATFORMS = iphonesimulator iphoneos
VALID_ARCHS = arm64 x86_64
ARCHS = $(ARCHS_STANDARD)
CODE_SIGN_IDENTITY = 
CODE_SIGNING_REQUIRED = NO
CODE_SIGNING_ALLOWED = NO
DEVELOPMENT_TEAM = 
PRODUCT_BUNDLE_IDENTIFIER = com.lifelens.LifeLens
EOF

echo "✅ Created iOS 18.2 configuration file"

# Clear derived data
echo "Clearing caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*LifeLens*

# Try to build with iOS 18.2
echo ""
echo "Attempting build with iOS 18.2..."
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -sdk iphonesimulator18.2 \
    -configuration Debug \
    -xcconfig ios18.2.xcconfig \
    -derivedDataPath build \
    CODE_SIGNING_REQUIRED=NO \
    build 2>&1 | tail -20

echo ""
echo "======================================"
echo "Next Steps in Xcode:"
echo "======================================"
echo "1. Close Xcode completely"
echo "2. Run: open LifeLens.xcodeproj"
echo "3. When Xcode opens:"
echo "   - The project should now use iOS 18.2"
echo "   - Select 'iPhone 16 Pro Max' as the destination"
echo "   - Press ⌘B to build"
echo ""
echo "The iOS 18.5 requirement has been replaced with iOS 18.2"