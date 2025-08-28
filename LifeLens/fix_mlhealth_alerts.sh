#!/bin/bash

echo "Fixing MLHealthService alert types..."

# Fix AlertType.cardiac -> .warning or .emergency
sed -i '' 's/type: \.cardiac/type: .warning/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/MLHealthService.swift

# Fix AlertType.glucose -> .warning
sed -i '' 's/type: \.glucose/type: .warning/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/MLHealthService.swift

# Fix AlertType.oxygen -> .warning
sed -i '' 's/type: \.oxygen/type: .warning/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/MLHealthService.swift

# Fix AlertType.pattern -> .insight
sed -i '' 's/type: \.pattern/type: .insight/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/MLHealthService.swift

# Fix AlertSeverity.moderate -> .medium
sed -i '' 's/severity: \.moderate/severity: .medium/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/MLHealthService.swift

echo "All alert types fixed!"
