#!/bin/bash

echo "Fixing all remaining errors..."

# 1. Fix ECGViewModel SharedTypes references
echo "Fixing ECGViewModel..."
sed -i '' 's/SharedTypes\.ECGReading/ECGReading/g' LifeLens/ViewModels/ECGViewModel.swift
sed -i '' 's/SharedTypes\.ECGRhythm/ECGRhythm/g' LifeLens/ViewModels/ECGViewModel.swift
sed -i '' 's/SharedTypes\.HealthAlert/HealthAlert/g' LifeLens/ViewModels/ECGViewModel.swift
sed -i '' 's/SharedTypes\.//' LifeLens/ViewModels/ECGViewModel.swift

# 2. Remove duplicate ECGReading definitions
echo "Finding and removing duplicate ECGReading..."
files=$(grep -l "struct ECGReading" LifeLens/**/*.swift 2>/dev/null | grep -v SharedTypes.swift)
for file in $files; do
    echo "  Removing from $file"
    sed -i '' '/^struct ECGReading/,/^}/d' "$file"
done

# 3. Fix PasswordValidator duplicate
echo "Fixing PasswordValidator..."
if grep -q "struct PasswordStrengthIndicator" LifeLens/Utilities/PasswordValidator.swift; then
    # Keep only the first definition
    awk '/struct PasswordStrengthIndicator/ {if (++count == 2) {skip=1}} 
         /^}/ {if (skip) {skip=0; next}} 
         !skip' LifeLens/Utilities/PasswordValidator.swift > temp && mv temp LifeLens/Utilities/PasswordValidator.swift
fi

# 4. Fix CloudMLResponseHandler issues
echo "Fixing CloudMLResponseHandler..."
# Fix incomplete lines at end of file
if [ -f "LifeLens/ML/CloudMLResponseHandler.swift" ]; then
    # Check if file ends improperly
    tail -5 LifeLens/ML/CloudMLResponseHandler.swift | grep -q "^    let name: String$" && {
        sed -i '' '975,977d' LifeLens/ML/CloudMLResponseHandler.swift
    }
fi

# 5. Fix HealthKitManager ECGReading reference
echo "Fixing HealthKitManager..."
sed -i '' 's/\[ECGReading\]/[SharedTypes.ECGReading]/g' LifeLens/Services/HealthKitManager.swift 2>/dev/null || true

# 6. Fix MockDataService HealthInsight
echo "Fixing MockDataService..."
# Find and check if HealthInsight is defined in SharedTypes
if ! grep -q "struct HealthInsight" LifeLens/models/SharedTypes.swift; then
    # Add HealthInsight to SharedTypes if missing
    echo "Adding HealthInsight to SharedTypes..."
    cat >> LifeLens/models/SharedTypes.swift << 'HEALTHINSIGHT'

// MARK: - Health Insight
public struct HealthInsight: Identifiable, Codable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let category: String
    public let importance: InsightImportance
    public let timestamp: Date
    
    public enum InsightImportance: String, Codable {
        case low, medium, high, critical
    }
    
    public init(title: String, description: String, category: String, importance: InsightImportance = .medium, timestamp: Date = Date()) {
        self.title = title
        self.description = description
        self.category = category
        self.importance = importance
        self.timestamp = timestamp
    }
}
HEALTHINSIGHT
fi

# 7. Fix APIConfiguration if needed
if ! grep -q "static let baseURL" LifeLens/Utilities/APIConfiguration.swift; then
    sed -i '' '/struct APIConfiguration/a\
    static let baseURL = "https://api.lifelens.io/v1"\
    static let apiKey = "API_ID_gud4ddne42"' LifeLens/Utilities/APIConfiguration.swift
fi

echo "All fixes completed!"
