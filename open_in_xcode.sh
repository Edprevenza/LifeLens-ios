#!/bin/bash

echo "=== Opening LifeLens in Xcode with Correct Settings ==="
echo ""
echo "This script will open the project in Xcode with the simulator ready."

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Clean DerivedData
echo "🧹 Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeLens-*

# Get first available iPhone simulator
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -o -E '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')
SIMULATOR_NAME=$(xcrun simctl list devices available | grep "$SIMULATOR_ID" | sed 's/ (.*//')

echo "📱 Found simulator: $SIMULATOR_NAME"

# Boot the simulator
echo "🚀 Booting simulator..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "   Simulator may already be booted"
open -a Simulator

# Open Xcode
echo "📂 Opening project in Xcode..."
open LifeLens.xcodeproj

echo ""
echo "✅ Xcode is opening. Please follow these steps:"
echo ""
echo "1. Wait for Xcode to fully load the project"
echo "2. In the top toolbar, you'll see a device selector"
echo "3. Click on it and select: $SIMULATOR_NAME"
echo "4. Press the Play button (▶) or Cmd+R to build and run"
echo ""
echo "If you see an error about iOS 18.5:"
echo "  • Go to LifeLens project settings (click LifeLens in left sidebar)"
echo "  • Select the LifeLens TARGET"
echo "  • In General tab, set Minimum Deployments → iOS to 17.0"
echo "  • In Build Settings tab, search for 'deployment'"
echo "  • Set iOS Deployment Target to 17.0"
echo ""
echo "The simulator is ready and waiting for your app!"