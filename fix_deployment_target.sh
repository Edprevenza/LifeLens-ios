#!/bin/bash

echo "=== Fixing iOS Deployment Target Issues ==="
echo "This will ensure all configurations use iOS 17.0"

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Update project.pbxproj to force iOS 17.0 everywhere
echo "📝 Updating project settings..."

# Convert to XML for easier editing
plutil -convert xml1 LifeLens.xcodeproj/project.pbxproj

# Replace any iOS 18.x references with 17.0
sed -i '' 's/18\.[0-9]/17.0/g' LifeLens.xcodeproj/project.pbxproj

# Convert back to binary plist
plutil -convert binary1 LifeLens.xcodeproj/project.pbxproj

echo "✅ Project updated to iOS 17.0"

# Create a build configuration that forces iOS 17.0
cat > Force17.xcconfig << 'EOF'
// Force iOS 17.0 for all builds
IPHONEOS_DEPLOYMENT_TARGET = 17.0
TARGETED_DEVICE_FAMILY = 1,2
SDKROOT = iphoneos
SUPPORTED_PLATFORMS = iphonesimulator iphoneos
CODE_SIGN_IDENTITY = 
CODE_SIGNING_REQUIRED = NO
CODE_SIGNING_ALLOWED = NO
DEVELOPMENT_TEAM = 
ONLY_ACTIVE_ARCH = NO
VALID_ARCHS = arm64 x86_64
ARCHS = $(ARCHS_STANDARD)
PRODUCT_BUNDLE_IDENTIFIER = com.lifelens.LifeLens
ENABLE_BITCODE = NO
EOF

echo "✅ Created Force17.xcconfig"

# Now try to build with these settings
echo ""
echo "🔨 Attempting build with fixed settings..."

# Get first iPhone simulator
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -o -E '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No simulator found"
    exit 1
fi

# Boot simulator
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true

# Build with forced config
xcodebuild \
    -project LifeLens.xcodeproj \
    -scheme LifeLens \
    -configuration Debug \
    -sdk iphonesimulator17.0 \
    -destination "id=$SIMULATOR_ID" \
    -xcconfig Force17.xcconfig \
    -derivedDataPath ./build \
    build 2>&1 | tail -20

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find and install app
    APP_PATH=$(find ./build -name "LifeLens.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        xcrun simctl launch "$SIMULATOR_ID" com.lifelens.LifeLens
        echo "✅ App launched!"
    fi
else
    echo ""
    echo "⚠️  Build still failing. Opening Xcode for manual fix..."
    open LifeLens.xcodeproj
    echo ""
    echo "In Xcode:"
    echo "1. Select LifeLens project in navigator"
    echo "2. Select LifeLens TARGET"
    echo "3. Build Settings tab → search 'deployment'"
    echo "4. Change iOS Deployment Target to 17.0"
    echo "5. Try building with Cmd+B"
fi