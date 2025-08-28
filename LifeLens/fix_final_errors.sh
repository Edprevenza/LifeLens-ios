#!/bin/bash

echo "Fixing final compilation errors..."

# 1. Fix HealthRecommendation missing type in CloudMLResponseHandler
echo "Adding HealthRecommendation to SharedTypes..."
cat >> /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/models/SharedTypes.swift << 'EOFTYPE'

// MARK: - Health Recommendation
public struct HealthRecommendation: Codable, Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let priority: Priority
    public let category: String
    public let actionItems: [String]
    
    public enum Priority: String, Codable {
        case low, medium, high, urgent
    }
    
    public init(title: String, description: String, priority: Priority = .medium, 
                category: String, actionItems: [String] = []) {
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.actionItems = actionItems
    }
}
EOFTYPE

# 2. Remove duplicate HealthInsight from MockDataService
echo "Removing duplicate HealthInsight from MockDataService..."
sed -i '' '/^struct HealthInsight/,/^}/d' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Services/MockDataService.swift

# 3. Remove duplicate HealthInsight from MLHealthCoordinator
echo "Removing duplicate HealthInsight from MLHealthCoordinator..."
sed -i '' '/^struct HealthInsight/,/^}/d' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/MLHealthCoordinator.swift

# 4. Fix ProfileSetupView - remove duplicate code at bottom
echo "Fixing ProfileSetupView..."
# Remove the problematic code at the bottom of the file (lines after the main struct)
sed -i '' '386,$d' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/View/ProfileSetupView.swift

# 5. Fix LocationManager - remove duplicate code
echo "Fixing LocationManager..."
# The file seems to have duplicate content, let's check and fix
head -n 56 /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Managers/LocationManager.swift > /tmp/loc_fix.swift
mv /tmp/loc_fix.swift /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Managers/LocationManager.swift

# 6. Remove duplicate LiveIndicator from ECGMonitorView
echo "Removing duplicate LiveIndicator..."
sed -i '' '/struct LiveIndicator: View {/,/^}/d' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Views/ECGMonitorView.swift

# 7. Remove duplicate PasswordStrengthIndicator from ModernAuthenticationViews
echo "Removing duplicate PasswordStrengthIndicator..."
sed -i '' '/struct PasswordStrengthIndicator: View {/,/^}/d' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Views/ModernAuthenticationViews.swift

# 8. Fix HealthAlert.Severity references in MLHealthService
echo "Fixing HealthAlert severity references..."
sed -i '' 's/HealthAlert\.Severity/HealthAlert.AlertSeverity/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/MLHealthService.swift

# 9. Fix SharedTypes reference in APIService
echo "Fixing SharedTypes reference in APIService..."
sed -i '' 's/SharedTypes\.HealthAlert/HealthAlert/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Services/APIService.swift

echo "All fixes applied!"
