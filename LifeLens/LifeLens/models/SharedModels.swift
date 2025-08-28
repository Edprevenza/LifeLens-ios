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
