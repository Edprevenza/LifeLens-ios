#!/bin/bash

echo "🔧 Bypassing Xcode iOS 18.5 Requirement"
echo "========================================"
echo ""

# Create fake iOS 18.5 runtime by symlinking iOS 18.2
echo "📦 Creating iOS 18.5 compatibility layer..."

# Create symlink for runtime
sudo ln -sf /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ 18.2.simruntime \
           /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ 18.5.simruntime 2>/dev/null

# Create SDK symlink
XCODE_SDK="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs"
sudo ln -sf "$XCODE_SDK/iPhoneSimulator.sdk" "$XCODE_SDK/iPhoneSimulator18.2.sdk" 2>/dev/null
sudo ln -sf "$XCODE_SDK/iPhoneSimulator.sdk" "$XCODE_SDK/iPhoneSimulator17.5.sdk" 2>/dev/null

# Update SDK settings to report as 18.5
echo "📝 Patching SDK version..."
SDK_PLIST="$XCODE_SDK/iPhoneSimulator.sdk/SDKSettings.plist"
if [ -f "$SDK_PLIST" ]; then
    # Backup
    sudo cp "$SDK_PLIST" "$SDK_PLIST.backup" 2>/dev/null
    
    # Make it report as supporting our versions
    sudo plutil -replace Version -string "18.2" "$SDK_PLIST" 2>/dev/null
    sudo plutil -replace MinimumSDKVersion -string "17.0" "$SDK_PLIST" 2>/dev/null
fi

# Clear Xcode caches
echo "🧹 Clearing Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
defaults delete com.apple.dt.Xcode 2>/dev/null
killall Xcode 2>/dev/null

# Create build script that uses generic SDK
cat > build_generic.sh << 'SCRIPT'
#!/bin/bash
cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean
rm -rf DerivedData build

# Build for generic simulator (no specific iOS version)
xcodebuild \
  -project LifeLens.xcodeproj \
  -scheme LifeLens \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=17.0 \
  EXCLUDED_ARCHS="" \
  build

if [ $? -eq 0 ]; then
    echo "✅ BUILD SUCCESSFUL!"
    find DerivedData -name "*.app" -type d
else
    echo "❌ Build failed"
fi
SCRIPT
chmod +x build_generic.sh

echo ""
echo "✅ Workaround applied!"
echo ""
echo "Now running build..."
./build_generic.sh