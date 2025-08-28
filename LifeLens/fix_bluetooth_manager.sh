#!/bin/bash

echo "Fixing BluetoothManager SharedTypes references..."

# Remove SharedTypes prefix since types are defined at top level
sed -i '' 's/SharedTypes\.HealthAlert/HealthAlert/g' LifeLens/Managers/BluetoothManager.swift
sed -i '' 's/SharedTypes\.//g' LifeLens/Managers/BluetoothManager.swift

# Fix PrivacyManager Bundle.main issue
sed -i '' 's/Bundle\.main/Bundle(for: type(of: self))/g' LifeLens/Utilities/PrivacyManager.swift

echo "Fixes completed!"
