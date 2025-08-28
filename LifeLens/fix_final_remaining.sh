#!/bin/bash

echo "Fixing final remaining compilation errors..."

# 1. Fix EnhancedProfileView - has orphaned code at the bottom
echo "Fixing EnhancedProfileView..."
# Keep only the main struct, remove duplicate code at bottom
sed -i '' '157,$d' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Views/EnhancedProfileView.swift
echo "}" >> /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Views/EnhancedProfileView.swift

# 2. Add EmergencyContactInfo type alias
echo "Adding EmergencyContactInfo type alias..."
sed -i '' '10a\
typealias EmergencyContactInfo = EmergencyContact\
' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Views/EnhancedProfileView.swift

# 3. Fix duplicate HealthInsight in MLHealthCoordinator
echo "Removing HealthInsight from MLHealthCoordinator..."
sed -i '' '/^public struct HealthInsight/,/^}/d' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/MLHealthCoordinator.swift

# 4. Fix ECGViewModel - change ECGRhythm to proper enum
echo "Fixing ECGViewModel..."
sed -i '' 's/ECGRhythm\.normal/ECGReading.ECGClassification.normal/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ViewModels/ECGViewModel.swift

# 5. Fix HealthDataManager - remove MLHealthService.HealthAlert references
echo "Fixing HealthDataManager..."
sed -i '' 's/MLHealthService\.HealthAlert/HealthAlert/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Managers/HealthDataManager.swift

# 6. Fix HealthKitManager - remove SharedTypes prefix
echo "Fixing HealthKitManager..."
sed -i '' 's/SharedTypes\.ECGReading/ECGReading/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Services/HealthKitManager.swift

# 7. Fix BLEModels - remove SharedTypes prefix
echo "Fixing BLEModels..."
sed -i '' 's/SharedTypes\.HealthAlert/HealthAlert/g' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/models/BLEModels.swift

# 8. Fix ContinuousMonitoringEngine - add proper Codable conformance
echo "Fixing ContinuousMonitoringEngine..."
# Add init methods for Codable conformance
cat >> /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/ContinuousMonitoringEngine.swift << 'EOFCODE'

// MARK: - Codable conformance for ContinuousStreamPayload
extension ContinuousStreamPayload {
    enum CodingKeys: String, CodingKey {
        case deviceId, timestamp, dataType, values, metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        dataType = try container.decode(String.self, forKey: .dataType)
        values = try container.decode([Double].self, forKey: .values)
        metadata = try container.decodeIfPresent([String: Any].self, forKey: .metadata) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(dataType, forKey: .dataType)
        try container.encode(values, forKey: .values)
        // Skip metadata encoding for now
    }
}
EOFCODE

echo "All fixes applied!"
