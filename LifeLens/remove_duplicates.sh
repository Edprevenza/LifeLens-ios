#!/bin/bash

echo "Removing duplicate type definitions..."

# Remove duplicate HealthAlert from APIService.swift
if grep -q "^struct HealthAlert: Codable, Identifiable {" LifeLens/Services/APIService.swift; then
    echo "Removing duplicate HealthAlert from APIService.swift"
    sed -i '' '/^struct HealthAlert: Codable, Identifiable {/,/^}/d' LifeLens/Services/APIService.swift
fi

# Remove duplicate HealthAlert from MLHealthService.swift  
if grep -q "struct HealthAlert: Identifiable {" LifeLens/ML/MLHealthService.swift; then
    echo "Removing duplicate HealthAlert from MLHealthService.swift"
    sed -i '' '/struct HealthAlert: Identifiable {/,/^    }/d' LifeLens/ML/MLHealthService.swift
fi

# Find and remove other duplicates
echo "Checking for duplicate HealthMetric..."
if grep -q "^struct HealthMetric: Codable, Identifiable {" LifeLens/**/*.swift 2>/dev/null; then
    files=$(grep -l "^struct HealthMetric: Codable, Identifiable {" LifeLens/**/*.swift 2>/dev/null | grep -v SharedTypes.swift)
    for file in $files; do
        echo "Removing duplicate HealthMetric from $file"
        sed -i '' '/^struct HealthMetric: Codable, Identifiable {/,/^}/d' "$file"
    done
fi

echo "Checking for duplicate ECGReading..."
if grep -q "^struct ECGReading:" LifeLens/**/*.swift 2>/dev/null; then
    files=$(grep -l "^struct ECGReading:" LifeLens/**/*.swift 2>/dev/null | grep -v SharedTypes.swift)
    for file in $files; do
        echo "Removing duplicate ECGReading from $file"
        sed -i '' '/^struct ECGReading:/,/^}/d' "$file"
    done
fi

# Fix BLEModels to use proper reference
echo "Fixing BLEModels references..."
sed -i '' 's/\[HealthAlert\]/[SharedTypes.HealthAlert]/g' LifeLens/models/BLEModels.swift 2>/dev/null || true

echo "Duplicates removed!"
