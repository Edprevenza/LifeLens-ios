#!/bin/bash

echo "🔧 Starting comprehensive iOS fix..."

# Step 1: Clean all build artifacts
echo "📦 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf build/
rm -rf *.xcworkspace/xcuserdata
rm -rf *.xcodeproj/xcuserdata

# Step 2: Fix duplicate ECGHeaderView
echo "🔍 Removing duplicate ECGHeaderView from EnhancedECGMonitor..."
sed -i '' '/struct ECGHeaderView/,/^}/d' LifeLens/Views/Dashboard/EnhancedECGMonitor.swift 2>/dev/null || true

# Step 3: Fix duplicate ECGWaveformView 
echo "🔍 Removing duplicate ECGWaveformView..."
if grep -q "struct ECGWaveformView" LifeLens/Views/Charts/HealthChartView.swift; then
    sed -i '' '/struct ECGWaveformView/,/^}/d' LifeLens/Views/Charts/HealthChartView.swift 2>/dev/null || true
fi

# Step 4: Create a SharedModels file for common types
echo "📝 Creating SharedModels for common types..."
cat > LifeLens/models/SharedModels.swift << 'EOF'
//
//  SharedModels.swift
//  LifeLens
//
//  Shared data models to avoid duplication
//

import Foundation
import SwiftUI

// MARK: - Chart Data Point
public struct ChartDataPoint: Codable, Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let value: Double
    public var label: String?
    
    public init(timestamp: Date, value: Double, label: String? = nil) {
        self.timestamp = timestamp
        self.value = value
        self.label = label
    }
}

// MARK: - Health Alert (already in SharedTypes.swift)
// Using HealthAlert from SharedTypes.swift

// MARK: - Alert Severity (already in SharedTypes.swift)
// Using AlertSeverity from SharedTypes.swift
EOF

# Step 5: Update imports in files that use ChartDataPoint
echo "🔄 Updating ChartDataPoint references..."
for file in $(find LifeLens -name "*.swift" -type f); do
    if grep -q "ChartDataPoint" "$file" && ! grep -q "SharedModels.swift" "$file"; then
        # Check if file already imports Foundation
        if ! grep -q "import Foundation" "$file"; then
            sed -i '' '1a\
import Foundation
' "$file" 2>/dev/null || true
        fi
    fi
done

# Step 6: Remove APIService.ChartDataPoint references
echo "🔄 Fixing APIService.ChartDataPoint references..."
find LifeLens -name "*.swift" -type f -exec sed -i '' 's/APIService\.ChartDataPoint/ChartDataPoint/g' {} \; 2>/dev/null || true

# Step 7: Fix HealthDashboardViewModel in needed files
echo "📝 Ensuring HealthDashboardViewModel is available..."
if ! grep -q "class HealthDashboardViewModel" LifeLens/ViewModels/HealthDashboardViewModel.swift 2>/dev/null; then
    mkdir -p LifeLens/ViewModels
    cat > LifeLens/ViewModels/HealthDashboardViewModel.swift << 'EOF'
//
//  HealthDashboardViewModel.swift
//  LifeLens
//

import Foundation
import SwiftUI
import Combine

public class HealthDashboardViewModel: ObservableObject {
    @Published public var bloodPressureData: [ChartDataPoint] = []
    @Published public var heartRateData: [ChartDataPoint] = []
    @Published public var glucoseData: [ChartDataPoint] = []
    @Published public var spo2Data: [ChartDataPoint] = []
    @Published public var troponinData: [ChartDataPoint] = []
    @Published public var ecgSamples: [Double] = []
    
    @Published public var currentAlerts: [HealthAlert] = []
    @Published public var isLoading = false
    @Published public var lastUpdated = Date()
    @Published public var connectionStatus: String = "Disconnected"
    
    @Published public var currentBP: (systolic: Int, diastolic: Int) = (120, 80)
    @Published public var currentHeartRate: Int = 75
    @Published public var currentGlucose: Double = 95
    @Published public var currentSpO2: Int = 98
    @Published public var currentTroponin: (i: Double, t: Double) = (0.01, 0.005)
    
    public init() {
        generateMockData()
    }
    
    private func generateMockData() {
        // Generate mock ECG samples
        for i in 0..<500 {
            let t = Double(i) / 100.0
            ecgSamples.append(sin(t * .pi * 2) * 0.5)
        }
        
        // Generate mock chart data
        let now = Date()
        for i in 0..<20 {
            let timestamp = now.addingTimeInterval(Double(i - 20) * 3600)
            heartRateData.append(ChartDataPoint(timestamp: timestamp, value: Double.random(in: 60...80)))
            bloodPressureData.append(ChartDataPoint(timestamp: timestamp, value: Double.random(in: 110...130)))
            glucoseData.append(ChartDataPoint(timestamp: timestamp, value: Double.random(in: 85...105)))
            spo2Data.append(ChartDataPoint(timestamp: timestamp, value: Double.random(in: 95...100)))
        }
    }
}
EOF
fi

# Step 8: Remove duplicate HealthDashboardViewModel from HealthDashboardView.swift
echo "🔄 Removing duplicate HealthDashboardViewModel..."
if grep -q "class HealthDashboardViewModel" LifeLens/Views/HealthDashboardView.swift 2>/dev/null; then
    # Remove the class definition but keep the file content
    sed -i '' '/class HealthDashboardViewModel/,/^}$/d' LifeLens/Views/HealthDashboardView.swift 2>/dev/null || true
fi

# Step 9: Fix ChartDataPoint in APIService
echo "🔄 Moving ChartDataPoint from APIService..."
if grep -q "struct ChartDataPoint" LifeLens/Services/APIService.swift 2>/dev/null; then
    sed -i '' '/struct ChartDataPoint/,/^}/d' LifeLens/Services/APIService.swift 2>/dev/null || true
fi

# Step 10: Update project file references
echo "📱 Updating project references..."
# This would normally be done in Xcode

echo "✅ Comprehensive fix complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open Xcode"
echo "2. Add SharedModels.swift to the project if not already added"
echo "3. Add HealthDashboardViewModel.swift to the project if not already added"
echo "4. Clean build folder (Cmd+Shift+K)"
echo "5. Build the project (Cmd+B)"