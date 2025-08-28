// SharedTypes.swift
// Central location for shared type definitions to avoid naming conflicts

import Foundation
import CoreML
import UIKit

// MARK: - Health Alert Types
public struct HealthAlert: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let message: String
    public let type: AlertType
    public let severity: AlertSeverity
    public let timestamp: Date
    public let source: String
    public let isRead: Bool
    public let actionRequired: Bool
    
    public enum AlertType: String, Codable, CaseIterable {
        case emergency = "Emergency"
        case warning = "Warning"
        case notification = "Notification"
        case reminder = "Reminder"
        case insight = "Insight"
        case prediction = "Prediction"
    }
    
    public enum AlertSeverity: String, Codable, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case info = "Info"
    }
    
    public init(id: UUID = UUID(),
                title: String,
                message: String,
                type: AlertType,
                severity: AlertSeverity,
                timestamp: Date = Date(),
                source: String,
                isRead: Bool = false,
                actionRequired: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.severity = severity
        self.timestamp = timestamp
        self.source = source
        self.isRead = isRead
        self.actionRequired = actionRequired
    }
}

// MARK: - Health Data Types
public struct HealthDataPoint: Codable, Identifiable {
    public let id: UUID
    public let type: String
    public let value: Double
    public let unit: String
    public let timestamp: Date
    public let source: String
    public let confidence: Double
    
    public init(id: UUID = UUID(),
                type: String,
                value: Double,
                unit: String,
                timestamp: Date = Date(),
                source: String,
                confidence: Double = 1.0) {
        self.id = id
        self.type = type
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.source = source
        self.confidence = confidence
    }
}

// MARK: - Demographics Types
public struct Demographics: Codable {
    public let age: Int
    public let gender: String
    public let height: Double // in cm
    public let weight: Double // in kg
    public let ethnicity: String?
    public let medicalHistory: [String]?
    
    public init(age: Int, gender: String, height: Double, weight: Double,
                ethnicity: String? = nil, medicalHistory: [String]? = nil) {
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.ethnicity = ethnicity
        self.medicalHistory = medicalHistory
    }
}

// MARK: - Health Metrics Types
public struct HealthMetric: Codable {
    public let name: String
    public let value: Double
    public let unit: String
    public let timestamp: Date
    public let normalRange: Range?
    
    public struct Range: Codable {
        public let min: Double
        public let max: Double
    }
    
    public init(name: String, value: Double, unit: String,
                timestamp: Date = Date(), normalRange: Range? = nil) {
        self.name = name
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.normalRange = normalRange
    }
}

// MARK: - Performance Metrics
public struct PerformanceMetrics: Codable {
    public let inferenceTime: Double // milliseconds
    public let memoryUsage: Double // MB
    public let batteryImpact: Double // percentage
    public let accuracy: Double // percentage
    public let modelVersion: String
    
    public init(inferenceTime: Double, memoryUsage: Double,
                batteryImpact: Double, accuracy: Double, modelVersion: String) {
        self.inferenceTime = inferenceTime
        self.memoryUsage = memoryUsage
        self.batteryImpact = batteryImpact
        self.accuracy = accuracy
        self.modelVersion = modelVersion
    }
}

// MARK: - Emergency Contact
public struct EmergencyContact: Codable {
    public let name: String
    public let relationship: String
    public let phone: String
    public let email: String?
    
    public init(name: String, relationship: String, phone: String, email: String? = nil) {
        self.name = name
        self.relationship = relationship
        self.phone = phone
        self.email = email
    }
}

// MARK: - Active Prediction
public struct ActivePrediction: Codable, Identifiable {
    public let id: UUID
    public let type: String
    public let confidence: Double
    public let prediction: String
    public let explanation: String?
    public let recommendedAction: String?
    public let timestamp: Date
    
    public init(id: UUID = UUID(),
                type: String,
                confidence: Double,
                prediction: String,
                explanation: String? = nil,
                recommendedAction: String? = nil,
                timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.confidence = confidence
        self.prediction = prediction
        self.explanation = explanation
        self.recommendedAction = recommendedAction
        self.timestamp = timestamp
    }
}

// MARK: - ECG Types
public struct ECGReading: Codable {
    public let timestamp: Date
    public let samples: [Double]
    public let sampleRate: Double
    public let classification: ECGClassification
    
    public enum ECGClassification: String, Codable {
        case normal = "Normal"
        case afib = "Atrial Fibrillation"
        case bradycardia = "Bradycardia"
        case tachycardia = "Tachycardia"
        case inconclusive = "Inconclusive"
    }
    
    public init(timestamp: Date, samples: [Double], 
                sampleRate: Double, classification: ECGClassification) {
        self.timestamp = timestamp
        self.samples = samples
        self.sampleRate = sampleRate
        self.classification = classification
    }
}

// MARK: - Blood Pressure Types
public struct BloodPressureReading: Codable {
    public let systolic: Double
    public let diastolic: Double
    public let timestamp: Date
    public let position: MeasurementPosition
    
    public enum MeasurementPosition: String, Codable {
        case sitting = "Sitting"
        case standing = "Standing"
        case lying = "Lying"
    }
    
    public init(systolic: Double, diastolic: Double,
                timestamp: Date = Date(), position: MeasurementPosition = .sitting) {
        self.systolic = systolic
        self.diastolic = diastolic
        self.timestamp = timestamp
        self.position = position
    }
}

// MARK: - Health Snapshot
public struct HealthSnapshot: Codable {
    public let timestamp: Date
    public let heartRate: Double?
    public let bloodPressure: BloodPressureReading?
    public let bloodOxygen: Double?
    public let temperature: Double?
    public let respiratoryRate: Double?
    public let bloodGlucose: Double?
    public let steps: Int?
    public let activeCalories: Double?
    public let alerts: [HealthAlert]
    
    public init(timestamp: Date = Date(),
                heartRate: Double? = nil,
                bloodPressure: BloodPressureReading? = nil,
                bloodOxygen: Double? = nil,
                temperature: Double? = nil,
                respiratoryRate: Double? = nil,
                bloodGlucose: Double? = nil,
                steps: Int? = nil,
                activeCalories: Double? = nil,
                alerts: [HealthAlert] = []) {
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.bloodPressure = bloodPressure
        self.bloodOxygen = bloodOxygen
        self.temperature = temperature
        self.respiratoryRate = respiratoryRate
        self.bloodGlucose = bloodGlucose
        self.steps = steps
        self.activeCalories = activeCalories
        self.alerts = alerts
    }
}
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
