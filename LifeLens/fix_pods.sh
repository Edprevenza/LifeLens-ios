#!/bin/bash

echo "Fixing CocoaPods installation..."

# Remove old installations
rm -rf Pods Podfile.lock *.xcworkspace

# Reinstall pods
pod install --repo-update

echo "Pod installation complete!"