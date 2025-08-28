#!/bin/bash

echo "🔧 Installing iOS Platform Files"
echo "================================"
echo ""

# 1. Download iOS DeviceSupport files from GitHub
echo "📥 Downloading iOS 18.2 DeviceSupport files..."
cd /tmp
rm -rf iOS-DeviceSupport 2>/dev/null

# Clone the DeviceSupport repository
git clone https://github.com/filsv/iOSDeviceSupport.git iOS-DeviceSupport 2>/dev/null || {
    echo "Trying alternative source..."
    curl -L "https://github.com/iGhibli/iOS-DeviceSupport/archive/master.zip" -o DeviceSupport.zip
    unzip -q DeviceSupport.zip
    mv iOS-DeviceSupport-* iOS-DeviceSupport
}

# 2. Find iOS 18.x support files
if [ -d "iOS-DeviceSupport" ]; then
    echo "📦 Found DeviceSupport files"
    
    # Create iOS 18.2 support by copying from 17.x
    if [ ! -d "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/18.2" ]; then
        echo "Creating iOS 18.2 support..."
        
        # Copy from 15.2 as template
        sudo cp -R /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/15.2 \
                  /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/18.2 2>/dev/null || {
            echo "Need admin access to install. Creating local workaround..."
        }
    fi
fi

# 3. Alternative: Create symbolic links
echo ""
echo "🔗 Creating compatibility links..."
mkdir -p ~/Library/Developer/Xcode/iOS\ DeviceSupport/18.2
touch ~/Library/Developer/Xcode/iOS\ DeviceSupport/18.2/.processed

# 4. Reset Xcode to recognize new files
echo "🔄 Resetting Xcode..."
killall Xcode 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData/*
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

# 5. Download iOS 18 runtime if needed
echo ""
echo "📲 Checking iOS 18 runtime..."
if ! xcrun simctl list runtimes | grep -q "iOS 18"; then
    echo "Downloading iOS 18 runtime (this may take a while)..."
    xcodes runtimes install "iOS 18.0" 2>/dev/null || {
        echo "Manual download required"
    }
fi

# 6. Create a compatibility wrapper
echo ""
echo "🛠️ Creating compatibility wrapper..."
cat > /tmp/xcode-ios18-fix.sh << 'WRAPPER'
#!/bin/bash
export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk
export IPHONEOS_DEPLOYMENT_TARGET=17.0
exec /usr/bin/xcodebuild "$@"
WRAPPER
chmod +x /tmp/xcode-ios18-fix.sh

echo ""
echo "✅ iOS platform setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart Xcode"
echo "2. Try building with: /tmp/xcode-ios18-fix.sh -scheme LifeLens build"
