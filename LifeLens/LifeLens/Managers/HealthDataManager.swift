// Managers/HealthDataManager.swift
import Foundation
import Combine
import CoreBluetooth
import SwiftUI

class HealthDataManager: ObservableObject {
    @Published var currentVitals = HealthVitals()
    @Published var riskLevel: RiskLevel = .normal
    @Published var isConnectedToDevice = false
    @Published var predictions: HealthPredictions?
    @Published var mlAlerts: [MLHealthService.HealthAlert] = []
    @Published var mlRiskLevel: LocalPatternDetection.RiskLevel = .normal
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    private let mlHealthService = MLHealthService.shared
    
    // Data buffers for ML processing
    private var ecgBuffer: [Float] = []
    private var glucoseHistory: [EdgeMLModels.GlucoseReading] = []
    
    struct HealthVitals {
        var troponinI: Double = 0.0
        var systolicBP: Int = 120
        var diastolicBP: Int = 80
        var heartRate: Int = 72
        var glucose: Double = 95.0
        var spO2: Double = 98.0
        var temperature: Double = 37.0
        var timestamp = Date()
    }
    
    struct HealthPredictions {
        let miRisk6h: Double
        let glucoseTrend: String
        let bpTrend: String
        let confidence: Double
        let afibDetected: Bool
        let afibConfidence: Float
        let hypoglycemiaRisk: EdgeMLModels.HypoglycemiaRisk
        let vtachDetected: Bool
        let stemiDetected: Bool
    }
    
    enum RiskLevel: String, CaseIterable {
        case normal = "NORMAL"
        case elevated = "ELEVATED"
        case high = "HIGH"
        case critical = "CRITICAL"
        
        var color: Color {
            switch self {
            case .normal: return .green
            case .elevated: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    init() {
        setupMLIntegration()
    }
    
    private func setupMLIntegration() {
        // Observe ML service updates
        mlHealthService.$currentRiskLevel
            .sink { [weak self] riskLevel in
                self?.mlRiskLevel = riskLevel
                self?.updateOverallRiskLevel()
            }
            .store(in: &cancellables)
        
        mlHealthService.$activeAlerts
            .sink { [weak self] alerts in
                self?.mlAlerts = alerts
                self?.handleMLAlerts(alerts)
            }
            .store(in: &cancellables)
        
        mlHealthService.$latestPredictions
            .sink { [weak self] mlPredictions in
                self?.updatePredictionsWithML(mlPredictions)
            }
            .store(in: &cancellables)
    }
    
    func processVitalsData(_ data: Data) {
        // Parse incoming BLE data from LifeLens device
        guard data.count >= 28 else { return } // Expected data size
        
        let vitals = HealthVitals(
            troponinI: data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Double.self) },
            systolicBP: Int(data.withUnsafeBytes { $0.load(fromByteOffset: 8, as: UInt16.self) }),
            diastolicBP: Int(data.withUnsafeBytes { $0.load(fromByteOffset: 10, as: UInt16.self) }),
            heartRate: Int(data.withUnsafeBytes { $0.load(fromByteOffset: 12, as: UInt16.self) }),
            glucose: data.withUnsafeBytes { $0.load(fromByteOffset: 14, as: Double.self) },
            spO2: data.withUnsafeBytes { $0.load(fromByteOffset: 22, as: Double.self) },
            temperature: data.withUnsafeBytes { $0.load(fromByteOffset: 24, as: Double.self) }
        )
        
        DispatchQueue.main.async {
            self.currentVitals = vitals
            self.sendVitalsToAPI(vitals)
            self.sendVitalsToMLService(vitals)
        }
    }
    
    private func sendVitalsToAPI(_ vitals: HealthVitals) {
        let vitalsData: [String: Any] = [
            "vitals": [
                "troponin_i": vitals.troponinI,
                "systolic_bp": vitals.systolicBP,
                "diastolic_bp": vitals.diastolicBP,
                "heart_rate": vitals.heartRate,
                "glucose": vitals.glucose,
                "spo2": vitals.spO2,
                "temperature": vitals.temperature
            ],
            "timestamp": ISO8601DateFormatter().string(from: vitals.timestamp),
            "device_id": "LIFELENS_001"
        ]
        
        // Send vitals to API
        _ = apiService.sendVitals(vitalsData)
        
        // Perform local risk assessment
        performLocalRiskAssessment(vitals)
    }
    
    private func sendVitalsToMLService(_ vitals: HealthVitals) {
        // Update ML service with new vitals
        mlHealthService.updateHeartRate(vitals.heartRate)
        mlHealthService.updateBloodPressure(systolic: vitals.systolicBP, diastolic: vitals.diastolicBP)
        mlHealthService.updateGlucoseReading(vitals.glucose)
        mlHealthService.updateSpO2Data([Float(vitals.spO2)])
        
        // Store glucose history for trend analysis
        let glucoseReading = EdgeMLModels.GlucoseReading(value: vitals.glucose, timestamp: Date())
        glucoseHistory.append(glucoseReading)
        if glucoseHistory.count > 20 {
            glucoseHistory.removeFirst()
        }
    }
    
    func processECGData(_ ecgData: [Float]) {
        // Process incoming ECG data
        ecgBuffer.append(contentsOf: ecgData)
        if ecgBuffer.count > 5000 {
            ecgBuffer = Array(ecgBuffer.suffix(2500))
        }
        
        // Send to ML service
        mlHealthService.updateECGData(ecgData)
    }
    
    private func performLocalRiskAssessment(_ vitals: HealthVitals) {
        // Enhanced risk assessment combining traditional and ML approaches
        var traditionalRisk: RiskLevel = .normal
        
        if vitals.troponinI > 0.04 {
            traditionalRisk = .critical
            triggerEmergencyAlert()
        } else if vitals.systolicBP > 180 || vitals.diastolicBP > 120 {
            traditionalRisk = .high
        } else if vitals.heartRate > 100 || vitals.heartRate < 50 {
            traditionalRisk = .elevated
        } else if vitals.glucose < 70 || vitals.glucose > 250 {
            traditionalRisk = .elevated
        } else if vitals.spO2 < 92 {
            traditionalRisk = .elevated
        }
        
        // Combine with ML risk assessment
        updateOverallRiskLevel(traditionalRisk: traditionalRisk)
    }
    
    private func updateOverallRiskLevel(traditionalRisk: RiskLevel? = nil) {
        // Combine traditional and ML risk assessments
        let traditional = traditionalRisk ?? riskLevel
        let mlRisk = mapMLRiskToRiskLevel(mlRiskLevel)
        
        // Take the higher risk level
        if traditional == .critical || mlRisk == .critical {
            riskLevel = .critical
        } else if traditional == .high || mlRisk == .high {
            riskLevel = .high
        } else if traditional == .elevated || mlRisk == .elevated {
            riskLevel = .elevated
        } else {
            riskLevel = .normal
        }
    }
    
    private func mapMLRiskToRiskLevel(_ mlRisk: LocalPatternDetection.RiskLevel) -> RiskLevel {
        switch mlRisk {
        case .critical:
            return .critical
        case .high:
            return .high
        case .moderate:
            return .elevated
        case .low, .normal:
            return .normal
        }
    }
    
    private func handleMLAlerts(_ alerts: [MLHealthService.HealthAlert]) {
        // Process critical ML alerts
        for alert in alerts where alert.severity == .critical && alert.actionRequired {
            triggerEmergencyAlert(message: alert.message)
        }
    }
    
    private func updatePredictionsWithML(_ mlPredictions: MLHealthService.PredictionResults?) {
        guard let mlPredictions = mlPredictions else { return }
        
        // Combine API predictions with ML predictions
        let combinedPredictions = HealthPredictions(
            miRisk6h: predictions?.miRisk6h ?? 0.0,
            glucoseTrend: predictions?.glucoseTrend ?? "Stable",
            bpTrend: predictions?.bpTrend ?? "Stable",
            confidence: Double(mlPredictions.afibConfidence),
            afibDetected: mlPredictions.afibDetected,
            afibConfidence: mlPredictions.afibConfidence,
            hypoglycemiaRisk: mlPredictions.hypoglycemiaRisk,
            vtachDetected: mlPredictions.vtachDetected,
            stemiDetected: mlPredictions.stemiDetected
        )
        
        self.predictions = combinedPredictions
    }
    
    private func triggerEmergencyAlert(message: String = "Critical health event detected") {
        NotificationCenter.default.post(
            name: .emergencyAlert,
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    // MARK: - Public ML Methods
    
    func dismissMLAlert(id: UUID) {
        if let index = mlHealthService.activeAlerts.firstIndex(where: { $0.id == id }) {
            mlHealthService.dismissAlert(at: index)
        }
    }
    
    func clearAllMLAlerts() {
        mlHealthService.clearAllAlerts()
    }
    
    func getMLProcessingStatus() -> String {
        return mlHealthService.processingStatus
    }
    
    func getLastMLProcessingTime() -> Date? {
        return mlHealthService.lastProcessingTime
    }
}

extension Notification.Name {
    static let emergencyAlert = Notification.Name("emergencyAlert")
}//
//  HealthDataManager.swift
//  LifeLens
//
//  Created by Basorge on 15/08/2025.
//

