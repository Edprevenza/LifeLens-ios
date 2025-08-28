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
    
    // Additional properties for ModernHealthDashboard
    @Published public var heartRate: Int = 74
    @Published public var spo2: Int = 98
    @Published public var systolic: Int = 120
    @Published public var diastolic: Int = 80
    @Published public var glucose: Int = 112
    @Published public var trendData: [Double] = []
    
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
            
            // Add trend data for ModernHealthDashboard
            trendData.append(Double.random(in: 110...140))
        }
    }
}
