// ML/MLHealthService.swift
import Foundation
import Combine
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// Forward declarations to ensure types are available
typealias MLEdgeMLModels = EdgeMLModels
typealias MLLocalPatternDetection = LocalPatternDetection
typealias MLSensorDataProcessor = SensorDataProcessor
typealias MLAPIService = APIService
typealias MLAppLogger = AppLogger

/**
 * ML Health Service for LifeLens iOS
 * Orchestrates all ML components for real-time health monitoring
 * Manages edge processing, pattern detection, and cloud synchronization
 */
class MLHealthService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentRiskLevel: LocalPatternDetection.RiskLevel = .normal
    @Published var activeAlerts: [HealthAlert] = []
    @Published var latestPredictions: PredictionResults?
    @Published var processingStatus: String = "idle"
    @Published var lastProcessingTime: Date?
    @Published var batteryLevel: Float = 1.0
    
    // MARK: - ML Components
    private let edgeMLModels = EdgeMLModels()
    private let patternDetection = LocalPatternDetection()
    private let dataProcessor = SensorDataProcessor()
    
    // MARK: - Battery-Aware Processing Configuration
    private var EDGE_PROCESSING_INTERVAL: TimeInterval {
        // Adaptive processing based on battery level and risk
        if batteryLevel < 0.2 {
            return 5.0  // Slower processing when battery low
        } else if currentRiskLevel == .critical {
            return 0.5  // Faster processing for critical situations
        } else {
            return 2.0  // Normal processing
        }
    }
    
    private var PATTERN_DETECTION_INTERVAL: TimeInterval {
        return batteryLevel < 0.3 ? 15.0 : 5.0
    }
    
    private var CLOUD_SYNC_INTERVAL: TimeInterval {
        return batteryLevel < 0.2 ? 300.0 : 60.0  // 5 minutes vs 1 minute
    }
    
    // MARK: - Service Properties
    private var edgeProcessingTimer: Timer?
    private var patternDetectionTimer: Timer?
    private var cloudSyncTimer: Timer?
    private var batteryMonitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    
    // Data buffers with size limits
    private var ecgBuffer: [Float] = []
    private var glucoseReadings: [(value: Double, timestamp: Date)] = []
    private var spo2Buffer: [Float] = []
    private var heartRateBuffer: [Int] = []
    private var bloodPressureBuffer: [(systolic: Int, diastolic: Int)] = []
    
    // Buffer size limits based on battery
    private var maxECGBufferSize: Int {
        return batteryLevel < 0.3 ? 1000 : 2500
    }
    
    private var maxGlucoseReadings: Int {
        return batteryLevel < 0.3 ? 10 : 20
    }
    
    // MARK: - Types
    
    enum ProcessingStatus {
        case idle
        case processing
        case error(String)
    }
    
    struct PredictionResults {
        var afibDetected: Bool
        var afibConfidence: Float
        var hypoglycemiaRisk: EdgeMLModels.HypoglycemiaRisk
        var vtachDetected: Bool
        var stemiDetected: Bool
        var patternRisk: LocalPatternDetection.RiskLevel
        let timestamp: Date
        let miRisk6h: Double
        let glucoseTrend: String
        let bpTrend: String
        let confidence: Double
    }
    
    struct HealthAlert: Identifiable {
        let id = UUID()
        let type: AlertType
        let severity: Severity
        let title: String
        let message: String
        let timestamp: Date
        let actionRequired: Bool
        
        enum AlertType {
            case cardiac
            case glucose
            case oxygen
            case bloodPressure
            case pattern
        }
        
        enum Severity {
            case critical
            case high
            case moderate
            case low
        }
    }
    
    // MARK: - Initialization
    
    init() {
        startProcessingPipeline()
        setupNotifications()
    }
    
    deinit {
        stopProcessingPipeline()
    }
    
    // MARK: - Service Control
    
    func startProcessingPipeline() {
        startBatteryMonitoring()
        startAdaptiveTimers()
    }
    
    private func startBatteryMonitoring() {
        batteryMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.updateBatteryLevel()
        }
        updateBatteryLevel() // Initial update
    }
    
    private func updateBatteryLevel() {
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let newBatteryLevel = UIDevice.current.batteryLevel
        if newBatteryLevel != batteryLevel {
            batteryLevel = newBatteryLevel
            AppLogger.shared.info("Battery level changed to: \(batteryLevel)")
            startAdaptiveTimers() // Restart timers with new intervals
        }
        #endif
    }
    
    private func startAdaptiveTimers() {
        // Stop existing timers
        stopProcessingPipeline()
        
        // Start edge ML processing with adaptive interval
        edgeProcessingTimer = Timer.scheduledTimer(withTimeInterval: EDGE_PROCESSING_INTERVAL, repeats: true) { _ in
            Task { @MainActor in
                await self.processEdgeML()
            }
        }
        
        // Start pattern detection with adaptive interval
        patternDetectionTimer = Timer.scheduledTimer(withTimeInterval: PATTERN_DETECTION_INTERVAL, repeats: true) { _ in
            Task { @MainActor in
                await self.detectPatterns()
            }
        }
        
        // Start cloud sync with adaptive interval
        cloudSyncTimer = Timer.scheduledTimer(withTimeInterval: CLOUD_SYNC_INTERVAL, repeats: true) { _ in
            Task { @MainActor in
                await self.syncToCloud()
            }
        }
        
        AppLogger.shared.info("Timers restarted - Edge: \(EDGE_PROCESSING_INTERVAL)s, Pattern: \(PATTERN_DETECTION_INTERVAL)s, Sync: \(CLOUD_SYNC_INTERVAL)s")
    }
    
    func stopProcessingPipeline() {
        edgeProcessingTimer?.invalidate()
        patternDetectionTimer?.invalidate()
        cloudSyncTimer?.invalidate()
        batteryMonitoringTimer?.invalidate()
    }
    
    // MARK: - Data Input
    
    func updateECGData(_ data: [Float]) {
        ecgBuffer.append(contentsOf: data)
        // Keep buffer size manageable based on battery level
        if ecgBuffer.count > maxECGBufferSize {
            ecgBuffer = Array(ecgBuffer.suffix(maxECGBufferSize / 2))
        }
    }
    func updateGlucoseReading(_ value: Double) {
        let reading = (value: value, timestamp: Date())
        glucoseReadings.append(reading)
        // Keep readings based on battery level
        if glucoseReadings.count > maxGlucoseReadings {
            glucoseReadings = Array(glucoseReadings.suffix(maxGlucoseReadings))
        }
    }
    
    func updateSpO2Data(_ data: [Float]) {
        spo2Buffer.append(contentsOf: data)
        if spo2Buffer.count > 100 {
            spo2Buffer = Array(spo2Buffer.suffix(100))
        }
    }
    
    func updateHeartRate(_ rate: Int) {
        heartRateBuffer.append(rate)
        if heartRateBuffer.count > 60 {
            heartRateBuffer = Array(heartRateBuffer.suffix(60))
        }
    }
    
    func updateBloodPressure(systolic: Int, diastolic: Int) {
        bloodPressureBuffer.append((systolic: systolic, diastolic: diastolic))
        if bloodPressureBuffer.count > 20 {
            bloodPressureBuffer = Array(bloodPressureBuffer.suffix(20))
        }
    }
    
    // MARK: - Edge ML Processing
    
    @MainActor
    private func processEdgeML() async {
        processingStatus = "processing"
        lastProcessingTime = Date()
        
        var predictions = PredictionResults(
            afibDetected: false,
            afibConfidence: 0,
            hypoglycemiaRisk: EdgeMLModels.HypoglycemiaRisk.low,
            vtachDetected: false,
            stemiDetected: false,
            patternRisk: LocalPatternDetection.RiskLevel.normal,
            timestamp: Date(),
            miRisk6h: 0.0,
            glucoseTrend: "Stable",
            bpTrend: "Stable",
            confidence: 0.0
        )
        
        // Process ECG data for AFib, VTach, and STEMI
        if !ecgBuffer.isEmpty {
            // AFib detection
            let afibResult = edgeMLModels.detectAtrialFibrillation(ecgData: ecgBuffer)
            predictions.afibDetected = afibResult.detected
            predictions.afibConfidence = afibResult.confidence
            
            if afibResult.detected {
                createAlert(
                    type: .cardiac,
                    severity: .high,
                    title: "Atrial Fibrillation Detected",
                    message: afibResult.message,
                    actionRequired: true
                )
            }
            
            // VTach detection
            if let currentHR = heartRateBuffer.last {
                let vtachResult = edgeMLModels.detectVentricularTachycardia(
                    ecgData: ecgBuffer,
                    heartRate: currentHR
                )
                predictions.vtachDetected = vtachResult.detected
                
                if vtachResult.detected {
                    createAlert(
                        type: .cardiac,
                        severity: .critical,
                        title: "Ventricular Tachycardia",
                        message: vtachResult.message,
                        actionRequired: true
                    )
                }
            }
            
            // STEMI detection
            let stemiResult = edgeMLModels.detectSTElevation(ecgData: ecgBuffer)
            predictions.stemiDetected = stemiResult.detected
            
            if stemiResult.detected {
                createAlert(
                    type: .cardiac,
                    severity: .critical,
                    title: "STEMI Detected",
                    message: stemiResult.message,
                    actionRequired: true
                )
            }
        }
        
        // Process glucose for hypoglycemia prediction
        if !glucoseReadings.isEmpty, let currentGlucose = glucoseReadings.last?.value {
            let convertedReadings = glucoseReadings.map { 
                EdgeMLModels.GlucoseReading(value: $0.value, timestamp: $0.timestamp)
            }
            let hypoglycemiaRisk = edgeMLModels.predictHypoglycemia(
                glucoseReadings: convertedReadings,
                currentValue: currentGlucose
            )
            predictions.hypoglycemiaRisk = hypoglycemiaRisk
            
            switch hypoglycemiaRisk {
            case .critical:
                createAlert(
                    type: .glucose,
                    severity: .critical,
                    title: "Critical Hypoglycemia",
                    message: "Blood glucose critically low. Immediate action required!",
                    actionRequired: true
                )
            case .high:
                createAlert(
                    type: .glucose,
                    severity: .high,
                    title: "Hypoglycemia Risk",
                    message: "Blood glucose dropping rapidly. Monitor closely.",
                    actionRequired: false
                )
            default:
                break
            }
        }
        
        // Process SpO2 for critical drops
        if !spo2Buffer.isEmpty {
            if let spo2Alert = edgeMLModels.detectSpO2CriticalDrop(spo2Values: spo2Buffer) {
                switch spo2Alert.severity {
                case .critical:
                    createAlert(
                        type: .oxygen,
                        severity: .critical,
                        title: "Critical SpO2 Level",
                        message: spo2Alert.message,
                        actionRequired: true
                    )
                case .warning:
                    createAlert(
                        type: .oxygen,
                        severity: .moderate,
                        title: "Low SpO2 Warning",
                        message: spo2Alert.message,
                        actionRequired: false
                    )
                default:
                    break
                }
            }
        }
        
        latestPredictions = predictions
        processingStatus = "idle"
    }
    
    // MARK: - Pattern Detection
    
    @MainActor
    private func detectPatterns() async {
        guard !glucoseReadings.isEmpty || !bloodPressureBuffer.isEmpty else { return }
        
        let sensorReadings = LocalPatternDetection.SensorReadings(
            glucoseValues: glucoseReadings.map { $0.value },
            bloodPressureValues: bloodPressureBuffer,
            heartRateValues: heartRateBuffer,
            spo2Values: spo2Buffer,
            timestamps: glucoseReadings.map { $0.timestamp }
        )
        
        let riskAssessment = patternDetection.detectDangerousPatterns(readings: sensorReadings)
        currentRiskLevel = riskAssessment.level
        
        if riskAssessment.level.priority >= LocalPatternDetection.RiskLevel.high.priority {
            createAlert(
                type: .pattern,
                severity: mapRiskLevelToSeverity(riskAssessment.level),
                title: "Health Pattern Alert",
                message: riskAssessment.recommendation,
                actionRequired: riskAssessment.level == .critical
            )
        }
        
        // Check for specific patterns
        if !spo2Buffer.isEmpty {
                    let spo2Readings = spo2Buffer.enumerated().map { index, value in
            LocalPatternDetection.SpO2Reading(value: value, timestamp: Date().addingTimeInterval(Double(index)))
        }
            
            let desaturationAnalysis = patternDetection.detectSpO2Drops(readings: spo2Readings)
            if desaturationAnalysis.severity == "Severe" {
                createAlert(
                    type: .oxygen,
                    severity: .high,
                    title: "Frequent Desaturations",
                    message: "Multiple oxygen desaturation events detected. \(desaturationAnalysis.pattern)",
                    actionRequired: false
                )
            }
        }
        
        // Check cardiac coherence
        if !heartRateBuffer.isEmpty {
            let coherenceAnalysis = patternDetection.detectCardiacCoherence(heartRates: heartRateBuffer)
            if coherenceAnalysis.stressLevel == "High stress" {
                createAlert(
                    type: .cardiac,
                    severity: .low,
                    title: "High Stress Detected",
                    message: "Heart rate patterns indicate high stress. Consider stress reduction techniques.",
                    actionRequired: false
                )
            }
        }
    }
    
    // MARK: - Cloud Synchronization
    
    @MainActor
    private func syncToCloud() async {
        guard !ecgBuffer.isEmpty || !glucoseReadings.isEmpty else { return }
        
        // Prepare raw sensor data
        let rawData = SensorDataProcessor.RawSensorData(
            deviceId: "LIFELENS_IOS_001",
            deviceModel: "iPhone",
            firmwareVersion: "1.0.0",
            batteryLevel: 85,
            ecgData: ecgBuffer.isEmpty ? nil : ecgBuffer,
            ppgData: nil, // PPG data would come from connected device
            glucoseData: glucoseReadings.isEmpty ? nil : glucoseReadings.map { $0.value },
            bloodPressure: bloodPressureBuffer.isEmpty ? nil : bloodPressureBuffer.map {
                SensorDataProcessor.BPReading(systolic: $0.systolic, diastolic: $0.diastolic, pulse: 0, timestamp: Date())
            },
            spo2Data: spo2Buffer.isEmpty ? nil : spo2Buffer.map { Int($0) },
            heartRateData: heartRateBuffer.isEmpty ? nil : heartRateBuffer,
            temperature: nil,
            respiratoryRate: nil
        )
        
        // Process data for cloud
        let processedData = dataProcessor.preprocessForCloud(raw: rawData)
        
        // Send to API
        await sendProcessedDataToAPI(processedData)
        
        // Clear old data after successful sync
        if ecgBuffer.count > 5000 {
            ecgBuffer = Array(ecgBuffer.suffix(2500))
        }
        if glucoseReadings.count > 50 {
            glucoseReadings = Array(glucoseReadings.suffix(20))
        }
    }
    
    // MARK: - Alert Management
    
    private func createAlert(
        type: HealthAlert.AlertType,
        severity: HealthAlert.Severity,
        title: String,
        message: String,
        actionRequired: Bool
    ) {
        let alert = HealthAlert(
            type: type,
            severity: severity,
            title: title,
            message: message,
            timestamp: Date(),
            actionRequired: actionRequired
        )
        
        // Add to active alerts
        DispatchQueue.main.async {
            self.activeAlerts.append(alert)
            
            // Keep only recent alerts (last 20)
            if self.activeAlerts.count > 20 {
                self.activeAlerts = Array(self.activeAlerts.suffix(20))
            }
        }
        
        // Send critical alerts to API immediately
        if severity == .critical {
            Task {
                await sendCriticalAlertToAPI(alert)
            }
        }
        
        // Trigger local notification for critical alerts
        if actionRequired {
            triggerLocalNotification(for: alert)
        }
    }
    
    func dismissAlert(at index: Int) {
        guard index < activeAlerts.count else { return }
        activeAlerts.remove(at: index)
    }
    
    func clearAllAlerts() {
        activeAlerts.removeAll()
    }
    
    // MARK: - API Communication
    
    private func sendProcessedDataToAPI(_ data: SensorDataProcessor.ProcessedData) async {
        // Convert processed data to API format
        let apiData: [String: Any] = [
            "device_id": data.deviceId,
            "timestamp": ISO8601DateFormatter().string(from: data.timestamp),
            "features": convertFeaturesToDict(data.features),
            "quality_score": data.qualityScore,
            "metadata": [
                "device_model": data.metadata.deviceModel,
                "firmware_version": data.metadata.firmwareVersion,
                "battery_level": data.metadata.batteryLevel,
                "signal_quality": data.metadata.signalQuality
            ]
        ]
        
        // Send to API
        _ = apiService.sendProcessedMLData(apiData)
    }
    
    private func sendCriticalAlertToAPI(_ alert: HealthAlert) async {
        let alertData: [String: Any] = [
            "type": String(describing: alert.type),
            "severity": String(describing: alert.severity),
            "title": alert.title,
            "message": alert.message,
            "timestamp": ISO8601DateFormatter().string(from: alert.timestamp),
            "action_required": alert.actionRequired
        ]
        
        _ = apiService.sendCriticalAlert(alertData)
    }
    
    // MARK: - Helper Functions
    
    private func mapRiskLevelToSeverity(_ level: LocalPatternDetection.RiskLevel) -> HealthAlert.Severity {
        switch level {
        case .critical:
            return .critical
        case .high:
            return .high
        case .moderate:
            return .moderate
        case .low, .normal:
            return .low
        }
    }
    
    private func convertFeaturesToDict(_ features: SensorDataProcessor.FeatureSet) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        if let ecg = features.ecgFeatures {
            dict["ecg"] = [
                "hrv": ecg.heartRateVariability,
                "qt_interval": ecg.qtInterval,
                "pr_interval": ecg.prInterval,
                "qrs_width": ecg.qrsWidth,
                "st_level": ecg.stLevel,
                "t_wave": ecg.tWaveAmplitude
            ]
        }
        
        if let glucose = features.glucoseFeatures {
            dict["glucose"] = [
                "mean": glucose.mean,
                "std": glucose.std,
                "cv": glucose.cv,
                "trend": glucose.trend,
                "time_in_range": glucose.timeInRange
            ]
        }
        
        return dict
    }
    
    private func triggerLocalNotification(for alert: HealthAlert) {
        // In production, use UserNotifications framework
        print("🚨 CRITICAL ALERT: \(alert.title) - \(alert.message)")
    }
    
    private func setupNotifications() {
        // Setup notification observers for data updates
        NotificationCenter.default.publisher(for: NSNotification.Name("HealthDataUpdated"))
            .sink { [weak self] notification in
                if let data = notification.userInfo?["ecgData"] as? [Float] {
                    self?.updateECGData(data)
                }
                if let glucose = notification.userInfo?["glucose"] as? Double {
                    self?.updateGlucoseReading(glucose)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Shared Instance

extension MLHealthService {
    static let shared = MLHealthService()
}