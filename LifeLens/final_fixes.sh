#!/bin/bash

echo "Applying final fixes..."

# Fix AppLogger calls in OfflineHealthStorage.swift
if [ -f "LifeLens/ML/OfflineHealthStorage.swift" ]; then
    echo "Fixing AppLogger calls in OfflineHealthStorage.swift..."
    sed -i '' 's/, category: \.storage//g' LifeLens/ML/OfflineHealthStorage.swift
    sed -i '' 's/, category: \.sync//g' LifeLens/ML/OfflineHealthStorage.swift
fi

# Fix ambiguous HealthAlert references
files_with_health_alert=(
    "LifeLens/Services/APIService.swift"
    "LifeLens/Managers/BluetoothManager.swift"
)

for file in "${files_with_health_alert[@]}"; do
    if [ -f "$file" ]; then
        echo "Fixing HealthAlert references in $file..."
        # Add SharedTypes prefix
        sed -i '' 's/: HealthAlert/: SharedTypes.HealthAlert/g' "$file"
        sed -i '' 's/\[HealthAlert\]/[SharedTypes.HealthAlert]/g' "$file"
        sed -i '' 's/HealthAlert(/SharedTypes.HealthAlert(/g' "$file"
    fi
done

echo "Final fixes completed!"
