#!/bin/bash

# Fix Xcode build settings for iOS compatibility
echo "======================================"
echo "🔧 Fixing Xcode Build Configuration"
echo "======================================"

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "\n${YELLOW}1. Updating project settings...${NC}"

# Update the project file to use iOS 17.0 as minimum deployment target
# This ensures compatibility with current Xcode
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 16.0/IPHONEOS_DEPLOYMENT_TARGET = 17.0/g' LifeLens.xcodeproj/project.pbxproj

echo -e "${GREEN}✓${NC} Updated deployment target to iOS 17.0"

echo -e "\n${YELLOW}2. Creating xcconfig file for build settings...${NC}"

# Create a configuration file to override build settings
cat > LifeLens.xcconfig << 'EOF'
// Build Configuration for LifeLens
// This file ensures compatibility with available SDK

// Deployment Target
IPHONEOS_DEPLOYMENT_TARGET = 17.0
TARGETED_DEVICE_FAMILY = 1,2

// SDK Settings
SDKROOT = iphoneos
SUPPORTED_PLATFORMS = iphonesimulator iphoneos

// Swift Settings
SWIFT_VERSION = 5.0
SWIFT_OPTIMIZATION_LEVEL = -Onone

// Code Signing (for development)
CODE_SIGN_IDENTITY = 
CODE_SIGNING_REQUIRED = NO
CODE_SIGNING_ALLOWED = NO
CODE_SIGN_ENTITLEMENTS = 
DEVELOPMENT_TEAM = 

// Architecture Settings
ONLY_ACTIVE_ARCH = NO
VALID_ARCHS = arm64 x86_64
ARCHS = $(ARCHS_STANDARD)

// Other Settings
PRODUCT_BUNDLE_IDENTIFIER = com.lifelens.LifeLens
PRODUCT_NAME = LifeLens
ENABLE_BITCODE = NO
ENABLE_TESTABILITY = YES

// Fix for iOS 18.5 compatibility
SUPPORTS_MACCATALYST = NO
SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO
EOF

echo -e "${GREEN}✓${NC} Created LifeLens.xcconfig"

echo -e "\n${YELLOW}3. Updating Info.plist for compatibility...${NC}"

# Ensure Info.plist has the correct minimum iOS version
/usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 17.0" LifeLens/Info.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string 17.0" LifeLens/Info.plist 2>/dev/null

echo -e "${GREEN}✓${NC} Updated Info.plist"

echo -e "\n${YELLOW}4. Creating build script for command line...${NC}"

cat > build-cli.sh << 'EOF'
#!/bin/bash

# Build LifeLens from command line
echo "Building LifeLens..."

# Clean previous builds
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/*LifeLens*

# Build for simulator
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 15' \
    -derivedDataPath build/ \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "App location: $(pwd)/build/Build/Products/Debug-iphonesimulator/LifeLens.app"
else
    echo "❌ Build failed"
    exit 1
fi
EOF

chmod +x build-cli.sh
echo -e "${GREEN}✓${NC} Created build-cli.sh"

echo -e "\n${YELLOW}5. Clearing Xcode caches...${NC}"

# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*LifeLens*
echo -e "${GREEN}✓${NC} Cleared derived data"

# Clear module cache
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache
echo -e "${GREEN}✓${NC} Cleared module cache"

echo -e "\n======================================"
echo -e "${GREEN}✅ Configuration Fixed!${NC}"
echo "======================================"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Close Xcode completely"
echo "2. Reopen Xcode with the project:"
echo "   open LifeLens.xcodeproj"
echo ""
echo "3. In Xcode:"
echo "   a. Select 'LifeLens' scheme (top bar)"
echo "   b. Select 'iPhone 15' or 'iPhone 14' simulator"
echo "   c. Go to Product → Destination → Choose 'iPhone 15 - iOS 17.5'"
echo "   d. Press ⌘B to build"
echo ""
echo "4. If asked about iOS 18.5:"
echo "   - Click 'Cancel'"
echo "   - Change destination to iOS 17.x simulator"
echo ""
echo "5. Alternative: Build from terminal:"
echo "   ./build-cli.sh"

echo -e "\n${YELLOW}Troubleshooting:${NC}"
echo "If you still see iOS 18.5 requirement:"
echo "1. In Xcode, go to: Product → Destination → Destination Architectures"
echo "2. Select 'Show All Run Destinations'"
echo "3. Choose an iOS 17.x simulator"
echo ""
echo "To download iOS 17.x simulators:"
echo "1. Xcode → Settings → Platforms"
echo "2. Click '+' and add iOS 17.5 Simulator"