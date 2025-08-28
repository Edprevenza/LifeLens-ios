#!/bin/bash

echo "🔧 Fixing Xcode Components"
echo "==========================="
echo ""

# 1. Kill Xcode and related processes
echo "🛑 Stopping Xcode..."
killall Xcode 2>/dev/null
killall Simulator 2>/dev/null

# 2. Clear Xcode caches
echo "🧹 Clearing Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Developer/CoreSimulator/Caches

# 3. Reset simulator
echo "🔄 Resetting simulator..."
xcrun simctl shutdown all 2>/dev/null
xcrun simctl erase all 2>/dev/null

# 4. Clear MobileAsset cache (this might fix the download issue)
echo "📦 Clearing MobileAsset cache..."
sudo rm -rf /Library/Developer/CoreSimulator/Cryptexes 2>/dev/null
sudo rm -rf ~/Library/Developer/CoreSimulator/Cryptexes 2>/dev/null

# 5. Reset Xcode preferences
echo "⚙️ Resetting Xcode preferences..."
defaults delete com.apple.dt.Xcode 2>/dev/null

# 6. Try downloading via xcodes tool (alternative method)
echo "📥 Installing xcodes tool for better download management..."
if ! command -v xcodes &> /dev/null; then
    brew install xcodesorg/made/xcodes 2>/dev/null || {
        echo "⚠️ Couldn't install xcodes tool"
    }
fi

# 7. Restart Xcode and let it re-download
echo "🚀 Restarting Xcode..."
open -a Xcode

echo ""
echo "✅ Xcode reset complete!"
echo ""
echo "Next steps:"
echo "1. When Xcode opens, it should prompt to install components"
echo "2. Click 'Install' on any dialog that appears"
echo "3. If no dialog appears, go to Xcode > Settings > Platforms"
echo "4. Try downloading iOS 17.5 or any older version that's available"
echo ""
echo "Alternative: Download Xcode 15 which includes iOS 17 by default"
