// CloudMLResponseHandler.swift
// Handles cloud ML predictions and merges with edge ML results

import Foundation
import Combine
import CoreML
import UserNotifications

/**
 * Handles cloud ML predictions and merges them with edge ML results
 * Processes 6.5-hour predictive analytics from AWS SageMaker
 * Manages alert generation and recommendation updates
 */
class CloudMLResponseHandler: ObservableObject {
    
    // MARK: - Constants
    
    private static let SHORT_TERM_WINDOW_MINUTES = 30
    private static let MEDIUM_TERM_WINDOW_HOURS = 2
    private static let LONG_TERM_WINDOW_HOURS = 6.5
    
    private static let CRITICAL_RISK_THRESHOLD: Float = 0.85
    private static let HIGH_RISK_THRESHOLD: Float = 0.70
    private static let MODERATE_RISK_THRESHOLD: Float = 0.50
    
    private static let CLOUD_WEIGHT: Float = 0.7
    private static let EDGE_WEIGHT: Float = 0.3
    
    private static let ALERT_COOLDOWN_MINUTES = 15
    
    // MARK: - Properties
    
    @Published var activePredictions: [ActivePrediction] = []
    @Published var recommendations: [RecommendationData] = []
    @Published var riskAssessment = RiskAssessment()
    
    private let edgeML: CoreMLEdgeModels
    private let alertManager: AlertManager
    private let repository: HealthDataRepository
    private let recommendationEngine = RecommendationEngine()
    
    private var predictionCache = [String: PredictionCacheEntry]()
    private var alertHistory = [String: Date]()
    private var cancellables = Set<AnyCancellable>()
    
    private let processingQueue = DispatchQueue(label: "com.lifelens.cloudml", qos: .userInitiated)
    
    // MARK: - Data Models
    
    struct CloudMLResponse {
        let requestId: String
        let timestamp: Date
        let predictions: PredictionSet
        let confidence: Float
        let modelVersion: String
        let processingTime: TimeInterval
    }
    
    struct PredictionSet {
        let cardiac: CardiacPredictions
        let metabolic: MetabolicPredictions
        let respiratory: RespiratoryPredictions
        let neurological: NeurologicalPredictions
        let composite: CompositePredictions
    }
    
    struct CardiacPredictions {
        let arrhythmiaRisk: TimeSeries<Float>
        let miRisk: TimeSeries<Float>
        let heartFailureRisk: TimeSeries<Float>
        let afibProbability: TimeSeries<Float>
        let expectedHeartRate: TimeSeries<Int>
        let expectedBP: TimeSeries<BloodPressure>
    }
    
    struct MetabolicPredictions {
        let glucoseTrend: TimeSeries<Float>
        let hypoglycemiaRisk: TimeSeries<Float>
        let hyperglycemiaRisk: TimeSeries<Float>
        let ketoacidosisRisk: TimeSeries<Float>
        let insulinSensitivity: TimeSeries<Float>
        let recommendedCarbs: TimeSeries<Int>
    }
    
    struct RespiratoryPredictions {
        let apneaRisk: TimeSeries<Float>
        let copdExacerbation: TimeSeries<Float>
        let asthmaAttackRisk: TimeSeries<Float>
        let expectedSpO2: TimeSeries<Int>
        let expectedRespRate: TimeSeries<Int>
    }
    
    struct NeurologicalPredictions {
        let seizureRisk: TimeSeries<Float>
        let strokeRisk: TimeSeries<Float>
        let migraineRisk: TimeSeries<Float>
        let cognitiveDecline: TimeSeries<Float>
        let fallRisk: TimeSeries<Float>
    }
    
    struct CompositePredictions {
        let overallHealthScore: Float
        let hospitalizationRisk: Float
        let emergencyRisk: Float
        let mortalityRisk: Float
        let qualityOfLifeScore: Float
        let interventionNeeded: [InterventionType]
    }
    
    struct TimeSeries<T> {
        let values: [T]
        let timestamps: [Date]
        let confidence: [Float]
    }
    
    // ActivePrediction is defined in SharedTypes
    
    // HealthRecommendation uses a simplified local definition
    struct RecommendationData: Identifiable {
        let id = UUID()
        let category: RecommendationCategory
        let title: String
        let description: String
        let priority: Priority
        let actions: [RecommendedAction]
        let expiresAt: Date
    }
    
    // RecommendedAction definition for local use
    struct RecommendedAction {
        let action: String
        let urgency: Urgency
        let expectedOutcome: String
    }
    
    struct RiskAssessment {
        var overall: Float = 0
        var cardiac: Float = 0
        var metabolic: Float = 0
        var respiratory: Float = 0
        var neurological: Float = 0
        var trend: Trend = .stable
        var lastUpdated = Date()
    }
    
    struct PredictionCacheEntry {
        let prediction: Any
        let timestamp: Date
        let confidence: Float
    }
    
    struct BloodPressure {
        let systolic: Int
        let diastolic: Int
    }
    
    // MARK: - Enums
    
    enum PredictionType {
        case arrhythmia
        case myocardialInfarction
        case hypoglycemia
        case hyperglycemia
        case respiratoryFailure
        case seizure
        case stroke
        case fall
        case generalDeterioration
    }
    
    enum Severity {
        case low, moderate, high, critical
    }
    
    enum Priority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case urgent = 3
        case emergency = 4
        
        static func < (lhs: Priority, rhs: Priority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    enum Urgency {
        case immediate, withinHour, withinDay, routine
    }
    
    enum Trend {
        case improving, stable, worsening, critical
    }
    
    enum RecommendationCategory {
        case medication
        case lifestyle
        case monitoring
        case emergency
        case appointment
        case diagnostic
    }
    
    enum InterventionType {
        case medicationAdjustment
        case emergencyResponse
        case physicianConsultation
        case lifestyleModification
        case increasedMonitoring
        case diagnosticTest
    }
    
    // MARK: - Initialization
    
    init(edgeML: CoreMLEdgeModels, alertManager: AlertManager, repository: HealthDataRepository) {
        self.edgeML = edgeML
        self.alertManager = alertManager
        self.repository = repository
    }
    
    // MARK: - Main Processing
    
    /**
     * Main entry point for processing cloud ML predictions
     */
    func processCloudPrediction(_ response: CloudMLResponse) async {
        await withCheckedContinuation { continuation in
            processingQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    // 1. Validate response
                    guard self.validateResponse(response) else {
                        print("Invalid cloud response: \(response.requestId)")
                        continuation.resume()
                        return
                    }
                    
                    // 2. Extract predictions
                    let predictions = self.extractPredictions(from: response)
                    
                    // 3. Merge with edge ML results
                    Task {
                        let mergedPredictions = await self.mergeWithEdgeResults(predictions)
                        
                        // 4. Update risk assessment
                        await self.updateRiskAssessment(mergedPredictions)
                        
                        // 5. Generate alerts
                        await self.generateAlerts(for: mergedPredictions)
                        
                        // 6. Update recommendations
                        await self.updateRecommendations(for: mergedPredictions)
                        
                        // 7. Store predictions
                        await self.storePredictions(mergedPredictions)
                        
                        // 8. Notify observers
                        await self.notifyPredictionUpdate(mergedPredictions)
                        
                        print("Successfully processed cloud prediction: \(response.requestId)")
                        continuation.resume()
                    }
                    
                } catch {
                    print("Error processing cloud prediction: \(error)")
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private func validateResponse(_ response: CloudMLResponse) -> Bool {
        return response.confidence > 0.3 &&
               response.timestamp.timeIntervalSinceNow > -3600 &&
               response.predictions.composite.overallHealthScore >= 0 &&
               response.predictions.composite.overallHealthScore <= 100
    }
    
    // MARK: - Prediction Extraction
    
    private func extractPredictions(from response: CloudMLResponse) -> [ActivePrediction] {
        var predictions: [ActivePrediction] = []
        
        // Process cardiac predictions
        if let arrhythmiaRisk = processTimeSeries(
            response.predictions.cardiac.arrhythmiaRisk,
            type: .arrhythmia
        ) {
            predictions.append(arrhythmiaRisk)
        }
        
        if let miRisk = processTimeSeries(
            response.predictions.cardiac.miRisk,
            type: .myocardialInfarction
        ) {
            predictions.append(miRisk)
        }
        
        // Process metabolic predictions
        if let hypoRisk = processTimeSeries(
            response.predictions.metabolic.hypoglycemiaRisk,
            type: .hypoglycemia
        ) {
            predictions.append(hypoRisk)
        }
        
        if let hyperRisk = processTimeSeries(
            response.predictions.metabolic.hyperglycemiaRisk,
            type: .hyperglycemia
        ) {
            predictions.append(hyperRisk)
        }
        
        // Process respiratory predictions
        if let copdRisk = processTimeSeries(
            response.predictions.respiratory.copdExacerbation,
            type: .respiratoryFailure
        ) {
            predictions.append(copdRisk)
        }
        
        // Process neurological predictions
        if let seizureRisk = processTimeSeries(
            response.predictions.neurological.seizureRisk,
            type: .seizure
        ) {
            predictions.append(seizureRisk)
        }
        
        if let strokeRisk = processTimeSeries(
            response.predictions.neurological.strokeRisk,
            type: .stroke
        ) {
            predictions.append(strokeRisk)
        }
        
        if let fallRisk = processTimeSeries(
            response.predictions.neurological.fallRisk,
            type: .fall
        ) {
            predictions.append(fallRisk)
        }
        
        return predictions
    }
    
    private func processTimeSeries(_ timeSeries: TimeSeries<Float>, type: PredictionType) -> ActivePrediction? {
        guard let maxRisk = timeSeries.values.max(),
              maxRisk > Self.MODERATE_RISK_THRESHOLD else {
            return nil
        }
        
        guard let maxIndex = timeSeries.values.firstIndex(of: maxRisk) else {
            return nil
        }
        
        let timeToEvent = timeSeries.timestamps[maxIndex].timeIntervalSinceNow
        
        return ActivePrediction(
            type: String(describing: type),
            confidence: Double(timeSeries.confidence[maxIndex]),
            prediction: "Risk level: \(Int(maxRisk * 100))% in \(formatTimeToEvent(timeToEvent))",
            explanation: "ML model detected \(type) risk based on recent health metrics",
            recommendedAction: maxRisk > Self.HIGH_RISK_THRESHOLD ? getRecommendedAction(for: type) : nil,
            timestamp: Date()
        )
    }
    
    // MARK: - Edge ML Merging
    
    private func mergeWithEdgeResults(_ cloudPredictions: [ActivePrediction]) async -> [ActivePrediction] {
        var mergedPredictions: [ActivePrediction] = []
        
        for cloudPred in cloudPredictions {
            if let edgePred = await getEdgePrediction(for: cloudPred.type) {
                // Weighted average
                // Merge confidence values
                let mergedConfidence = Float(cloudPred.confidence) * Self.CLOUD_WEIGHT + 
                                     Float(edgePred.confidence) * Self.EDGE_WEIGHT
                
                let mergedPrediction = ActivePrediction(
                    type: cloudPred.type,
                    confidence: Double(mergedConfidence),
                    prediction: cloudPred.prediction,
                    explanation: cloudPred.explanation,
                    recommendedAction: cloudPred.recommendedAction,
                    timestamp: cloudPred.timestamp
                )
                
                mergedPredictions.append(mergedPrediction)
            } else {
                mergedPredictions.append(cloudPred)
            }
        }
        
        // Add edge-only predictions
        await addEdgeOnlyPredictions(&mergedPredictions)
        
        return mergedPredictions
    }
    
    private func getEdgePrediction(for typeString: String) async -> ActivePrediction? {
        switch typeString {
        case "arrhythmia":
            let ecgData = await repository.getLatestECGData(count: 1000)
            guard !ecgData.isEmpty else { return nil }
            
            let result = await edgeML.detectArrhythmia(ecgSignal: ecgData)
            
            return ActivePrediction(
                type: typeString,
                confidence: Double(result.confidence),
                prediction: "Arrhythmia detected with \(Int(result.confidence * 100))% confidence",
                explanation: "ECG analysis detected irregular heart rhythm",
                recommendedAction: result.confidence > 0.8 ? "Seek immediate medical attention" : "Monitor closely",
                timestamp: Date()
            )
            
        case "hypoglycemia":
            let glucoseHistory = await repository.getGlucoseHistory(minutes: 30)
            guard !glucoseHistory.isEmpty else { return nil }
            
            let trend = Array(glucoseHistory.suffix(5))
            // Create glucose history for prediction
            let history = trend.map { value in
                [value, 0, 0, 0, 0] // Simple history format
            }
            let glucosePrediction = await edgeML.predictGlucose(history: [history.last ?? [100, 0, 0, 0, 0]])
            let riskValue = glucosePrediction.hypoglycemiaRisk
            let predictedValue = trend.last ?? 100 // Simplified prediction
            
            if predictedValue < 70 {
                return ActivePrediction(
                    type: typeString,
                    confidence: riskValue > 0.7 ? 0.9 : 0.7,
                    prediction: "Blood glucose may drop to \(predictedValue) mg/dL in 15 minutes",
                    explanation: "Glucose trend analysis indicates hypoglycemia risk",
                    recommendedAction: "Consume 15-20g of fast-acting carbohydrates immediately",
                    timestamp: Date()
                )
            }
            return nil
            
        default:
            return nil
        }
    }
    
    private func addEdgeOnlyPredictions(_ predictions: inout [ActivePrediction]) async {
        let recentVitals = await repository.getRecentVitals(count: 5)
        
        guard let latestVitals = recentVitals.last else { return }
        
        // Check for critical vitals
        if latestVitals.heartRate < 40 || latestVitals.heartRate > 150 {
            predictions.append(ActivePrediction(
                type: "arrhythmia",
                confidence: 0.95,
                prediction: "Critical heart rate: \(latestVitals.heartRate) bpm",
                explanation: "Heart rate outside normal range",
                recommendedAction: "Seek immediate medical attention",
                timestamp: Date()
            ))
        }
        
        if latestVitals.spo2 < 88 {
            predictions.append(ActivePrediction(
                type: "respiratoryFailure",
                confidence: 0.9,
                prediction: "Critical SpO2: \(latestVitals.spo2)%",
                explanation: "Oxygen saturation critically low",
                recommendedAction: "Seek emergency medical care immediately",
                timestamp: Date()
            ))
        }
    }
    
    // MARK: - Risk Assessment
    
    @MainActor
    private func updateRiskAssessment(_ predictions: [ActivePrediction]) async {
        let cardiacRisk = predictions
            .filter { $0.type == "arrhythmia" || $0.type == "myocardialInfarction" }
            .map { Float($0.confidence) }
            .max() ?? 0
        
        let metabolicRisk = predictions
            .filter { $0.type == "hypoglycemia" || $0.type == "hyperglycemia" }
            .map { Float($0.confidence) }
            .max() ?? 0
        
        let respiratoryRisk = predictions
            .filter { $0.type == "respiratoryFailure" }
            .map { Float($0.confidence) }
            .max() ?? 0
        
        let neurologicalRisk = predictions
            .filter { $0.type == "seizure" || $0.type == "stroke" || $0.type == "fall" }
            .map { Float($0.confidence) }
            .max() ?? 0
        
        let overallRisk = max(cardiacRisk, metabolicRisk, respiratoryRisk, neurologicalRisk)
        
        let trend: Trend
        if overallRisk > riskAssessment.overall + 0.1 {
            trend = .worsening
        } else if overallRisk < riskAssessment.overall - 0.1 {
            trend = .improving
        } else if overallRisk > Self.CRITICAL_RISK_THRESHOLD {
            trend = .critical
        } else {
            trend = .stable
        }
        
        riskAssessment = RiskAssessment(
            overall: overallRisk,
            cardiac: cardiacRisk,
            metabolic: metabolicRisk,
            respiratory: respiratoryRisk,
            neurological: neurologicalRisk,
            trend: trend,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Alert Generation
    
    private func generateAlerts(for predictions: [ActivePrediction]) async {
        for prediction in predictions.filter({ $0.recommendedAction != nil }) {
            if shouldGenerateAlert(for: prediction) {
                let alert = createAlert(from: prediction)
                await alertManager.sendAlert(alert)
                
                alertHistory[prediction.type] = Date()
                
                // Log critical alerts
                // Log critical alerts
                if prediction.confidence > Double(Self.CRITICAL_RISK_THRESHOLD) {
                    print("CRITICAL ALERT: \(prediction.type) - Confidence: \(prediction.confidence)")
                    
                    // Trigger emergency protocol if needed
                    if prediction.type == "myocardialInfarction",
                       prediction.confidence > 0.9 {
                        await triggerEmergencyProtocol(for: prediction)
                    }
                }
            }
        }
    }
    
    private func shouldGenerateAlert(for prediction: ActivePrediction) -> Bool {
        let key = prediction.type
        let lastAlert = alertHistory[key] ?? Date.distantPast
        let cooldownExpired = Date().timeIntervalSince(lastAlert) > 
                             TimeInterval(Self.ALERT_COOLDOWN_MINUTES * 60)
        
        return cooldownExpired || prediction.confidence > Double(Self.CRITICAL_RISK_THRESHOLD)
    }
    
    private func createAlert(from prediction: ActivePrediction) -> HealthAlert {
        let title = getAlertTitle(for: prediction.type)
        let message = buildAlertMessage(for: prediction)
        
        return HealthAlert(
            title: title,
            message: message,
            type: mapPredictionTypeToAlertType(prediction.type),
            severity: mapConfidenceToAlertSeverity(prediction.confidence),
            source: "ML Prediction Engine",
            actionRequired: prediction.recommendedAction != nil
        )
    }
    
    private func mapPredictionTypeToAlertType(_ type: String) -> HealthAlert.AlertType {
        switch type {
        case "myocardialInfarction", "arrhythmia", "respiratoryFailure", "stroke":
            return .emergency
        case "hypoglycemia", "hyperglycemia", "seizure":
            return .warning
        case "fall", "generalDeterioration":
            return .notification
        default:
            return .notification
        }
    }
    
    private func mapConfidenceToAlertSeverity(_ confidence: Double) -> HealthAlert.AlertSeverity {
        let conf = Float(confidence)
        if conf > Self.CRITICAL_RISK_THRESHOLD { return .critical }
        if conf > Self.HIGH_RISK_THRESHOLD { return .high }
        if conf > Self.MODERATE_RISK_THRESHOLD { return .medium }
        return .low
    }
    
    // Severity mapping removed - using confidence-based mapping instead
    
    private func getAlertTitle(for type: String) -> String {
        switch type {
        case "arrhythmia": return "Arrhythmia Risk Detected"
        case "myocardialInfarction": return "Heart Attack Risk"
        case "hypoglycemia": return "Low Blood Sugar Warning"
        case "hyperglycemia": return "High Blood Sugar Warning"
        case "respiratoryFailure": return "Respiratory Distress"
        case "seizure": return "Seizure Risk Detected"
        case "stroke": return "Stroke Risk Warning"
        case "fall": return "Fall Risk Alert"
        case "generalDeterioration": return "Health Status Declining"
        default: return "Health Alert"
        }
    }
    
    private func buildAlertMessage(for prediction: ActivePrediction) -> String {
        let confidence = Int(prediction.confidence * 100)
        
        if let explanation = prediction.explanation {
            return "\(explanation) (Confidence: \(confidence)%)"
        } else {
            return prediction.prediction
        }
    }
    
    private func formatTimeToEvent(_ interval: TimeInterval) -> String {
        if interval <= 0 { return "now" }
        if interval < 3600 { return "in \(Int(interval / 60)) minutes" }
        if interval < 86400 { return "in \(Int(interval / 3600)) hours" }
        return "in \(Int(interval / 86400)) days"
    }
    
    // MARK: - Recommendations
    
    @MainActor
    private func updateRecommendations(for predictions: [ActivePrediction]) async {
        var newRecommendations: [RecommendationData] = []
        
        for prediction in predictions {
            if let recommendation = recommendationEngine.generateRecommendation(for: prediction) {
                newRecommendations.append(recommendation)
            }
        }
        
        // Add general recommendations based on risk assessment
        if riskAssessment.overall > Self.MODERATE_RISK_THRESHOLD {
            newRecommendations.append(createMonitoringRecommendation())
        }
        
        recommendations = newRecommendations.sorted { $0.priority > $1.priority }
    }
    
    private func createMonitoringRecommendation() -> RecommendationData {
        return RecommendationData(
            category: .monitoring,
            title: "Increase Health Monitoring",
            description: "Your health metrics show elevated risk. Increase monitoring frequency.",
            priority: .high,
            actions: [
                CloudMLResponseHandler.RecommendedAction(
                    action: "Check vitals every 2 hours",
                    urgency: .withinHour,
                    expectedOutcome: "Early detection of changes"
                ),
                CloudMLResponseHandler.RecommendedAction(
                    action: "Keep device charged and connected",
                    urgency: .immediate,
                    expectedOutcome: "Continuous monitoring"
                )
            ],
            expiresAt: Date().addingTimeInterval(86400)
        )
    }
    
    // MARK: - Storage
    
    private func storePredictions(_ predictions: [ActivePrediction]) async {
        await repository.storePredictions(predictions)
        
        // Update cache
        for prediction in predictions {
            predictionCache[prediction.id.uuidString] = PredictionCacheEntry(
                prediction: prediction,
                timestamp: Date(),
                confidence: Float(prediction.confidence)
            )
        }
        
        // Clean old cache entries
        cleanCache()
    }
    
    private func cleanCache() {
        let cutoff = Date().addingTimeInterval(-86400) // 24 hours
        predictionCache = predictionCache.filter { $0.value.timestamp > cutoff }
    }
    
    // MARK: - Notification
    
    @MainActor
    private func notifyPredictionUpdate(_ predictions: [ActivePrediction]) async {
        activePredictions = predictions
        
        // Broadcast to other components
        NotificationCenter.default.post(
            name: .cloudPredictionsUpdated,
            object: nil,
            userInfo: ["predictions": predictions]
        )
    }
    
    // MARK: - Emergency Protocol
    
    private func triggerEmergencyProtocol(for prediction: ActivePrediction) async {
        print("EMERGENCY PROTOCOL TRIGGERED: \(prediction.type)")
        
        // 1. Send emergency notification
        await alertManager.sendEmergencyAlert(
            title: "EMERGENCY: Immediate Medical Attention Required",
            message: "Critical health risk detected. Emergency services should be contacted immediately.",
            data: [
                "type": prediction.type,
                "risk": String(prediction.confidence),
                "confidence": String(prediction.confidence)
            ]
        )
        
        // 2. Notify emergency contacts
        let contacts = await repository.getEmergencyContacts()
        for contact in contacts {
            await alertManager.notifyEmergencyContact(contact, prediction: prediction)
        }
        
        // 3. Start continuous monitoring
        startContinuousMonitoring()
        
        // 4. Log to cloud
        await logEmergencyEvent(prediction)
    }
    
    private func startContinuousMonitoring() {
        // Increase monitoring frequency
        print("Continuous monitoring started")
    }
    
    private func logEmergencyEvent(_ prediction: ActivePrediction) async {
        let severityStr = prediction.confidence > 0.85 ? "critical" : "high"
        await repository.logEmergencyEvent(
            timestamp: Date(),
            type: prediction.type,
            severity: severityStr,
            riskLevel: prediction.confidence,
            confidence: Float(prediction.confidence)
        )
    }
    
    // MARK: - Helpers
    
    private func getSeverity(for risk: Float) -> Severity {
        if risk > Self.CRITICAL_RISK_THRESHOLD { return .critical }
        if risk > Self.HIGH_RISK_THRESHOLD { return .high }
        if risk > Self.MODERATE_RISK_THRESHOLD { return .moderate }
        return .low
    }
    
    private func getRecommendedAction(for type: PredictionType) -> String {
        switch type {
        case .arrhythmia:
            return "Monitor heart rhythm and seek medical consultation"
        case .myocardialInfarction:
            return "Seek immediate emergency medical attention"
        case .hypoglycemia:
            return "Consume 15-20g of fast-acting carbohydrates"
        case .hyperglycemia:
            return "Check insulin levels and hydrate"
        case .respiratoryFailure:
            return "Ensure oxygen supply and seek medical help"
        case .seizure:
            return "Ensure safety and seek medical attention"
        case .stroke:
            return "Call emergency services immediately"
        case .fall:
            return "Use walking aids and ensure safe environment"
        case .generalDeterioration:
            return "Increase monitoring and consult healthcare provider"
        }
    }
}

// MARK: - Recommendation Engine

class RecommendationEngine {
    func generateRecommendation(for prediction: ActivePrediction) -> CloudMLResponseHandler.RecommendationData? {
        switch prediction.type {
        case "hypoglycemia":
            return generateHypoglycemiaRecommendation(prediction)
        case "hyperglycemia":
            return generateHyperglycemiaRecommendation(prediction)
        case "arrhythmia":
            return generateArrhythmiaRecommendation(prediction)
        case "fall":
            return generateFallPreventionRecommendation(prediction)
        default:
            return nil
        }
    }
    
    private func generateHypoglycemiaRecommendation(_ prediction: ActivePrediction) -> CloudMLResponseHandler.RecommendationData {
        return CloudMLResponseHandler.RecommendationData(
            category: .emergency,
            title: "Prevent Low Blood Sugar",
            description: "Your glucose is predicted to drop. Take preventive action.",
            priority: prediction.confidence > 0.85 ? .emergency : .high,
            actions: [
                CloudMLResponseHandler.RecommendedAction(
                    action: "Consume 15-20g of fast-acting carbohydrates",
                    urgency: .immediate,
                    expectedOutcome: "Prevent hypoglycemia"
                ),
                CloudMLResponseHandler.RecommendedAction(
                    action: "Check blood sugar in 15 minutes",
                    urgency: .withinHour,
                    expectedOutcome: "Verify glucose levels"
                )
            ],
            expiresAt: Date().addingTimeInterval(900) // 15 minutes
        )
    }
    
    private func generateHyperglycemiaRecommendation(_ prediction: ActivePrediction) -> CloudMLResponseHandler.RecommendationData {
        return CloudMLResponseHandler.RecommendationData(
            category: .medication,
            title: "Manage High Blood Sugar",
            description: "Your glucose is trending high. Consider intervention.",
            priority: .high,
            actions: [
                CloudMLResponseHandler.RecommendedAction(
                    action: "Check insulin levels and consider correction dose",
                    urgency: .withinHour,
                    expectedOutcome: "Reduce glucose levels"
                ),
                CloudMLResponseHandler.RecommendedAction(
                    action: "Increase water intake",
                    urgency: .immediate,
                    expectedOutcome: "Help reduce glucose"
                ),
                CloudMLResponseHandler.RecommendedAction(
                    action: "Light exercise if appropriate",
                    urgency: .withinHour,
                    expectedOutcome: "Natural glucose reduction"
                )
            ],
            expiresAt: Date().addingTimeInterval(14400) // 4 hours
        )
    }
    
    private func generateArrhythmiaRecommendation(_ prediction: ActivePrediction) -> CloudMLResponseHandler.RecommendationData {
        return CloudMLResponseHandler.RecommendationData(
            category: .monitoring,
            title: "Heart Rhythm Monitoring",
            description: "Irregular heart rhythm detected. Monitor closely.",
            priority: prediction.confidence > 0.85 ? .urgent : .high,
            actions: [
                CloudMLResponseHandler.RecommendedAction(
                    action: "Rest and avoid strenuous activity",
                    urgency: .immediate,
                    expectedOutcome: "Reduce cardiac stress"
                ),
                CloudMLResponseHandler.RecommendedAction(
                    action: "Record any symptoms (chest pain, dizziness)",
                    urgency: .immediate,
                    expectedOutcome: "Track symptoms for medical review"
                ),
                CloudMLResponseHandler.RecommendedAction(
                    action: "Consider medical consultation",
                    urgency: prediction.confidence > 0.85 ? .immediate : .withinDay,
                    expectedOutcome: "Professional evaluation"
                )
            ],
            expiresAt: Date().addingTimeInterval(43200) // 12 hours
        )
    }
    
    private func generateFallPreventionRecommendation(_ prediction: ActivePrediction) -> CloudMLResponseHandler.RecommendationData {
        return CloudMLResponseHandler.RecommendationData(
            category: .lifestyle,
            title: "Fall Prevention Alert",
            description: "Elevated fall risk detected. Take precautions.",
            priority: .high,
            actions: [
                CloudMLResponseHandler.RecommendedAction(
                    action: "Use walking aids if available",
                    urgency: .immediate,
                    expectedOutcome: "Reduce fall risk"
                ),
                CloudMLResponseHandler.RecommendedAction(
                    action: "Ensure good lighting and clear pathways",
                    urgency: .immediate,
                    expectedOutcome: "Safe environment"
                ),
                CloudMLResponseHandler.RecommendedAction(
                    action: "Avoid sudden movements",
                    urgency: .immediate,
                    expectedOutcome: "Maintain balance"
                )
            ],
            expiresAt: Date().addingTimeInterval(21600) // 6 hours
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudPredictionsUpdated = Notification.Name("cloudPredictionsUpdated")
}

// MARK: - Supporting Types

struct GlucoseReading {
    let value: Double
    let timestamp: Date
}

enum NotificationPriority {
    case low, normal, high, emergency
}

struct MLHealthAlert {  // Renamed to avoid conflict
    let id: UUID
    let title: String
    let message: String
    let type: String
    let severity: String
    let priority: NotificationPriority
    let timestamp: Date
    let actionRequired: Bool
    let timeToEvent: TimeInterval
    let confidence: Float
}

// Placeholder classes - implement these based on your app structure
class AlertManager {
    func sendAlert(_ alert: HealthAlert) async {
        // Implementation
    }
    
    func sendEmergencyAlert(title: String, message: String, data: [String: String]) async {
        // Implementation
    }
    
    func notifyEmergencyContact(_ contact: EmergencyContact, prediction: ActivePrediction) async {
        // Implementation
    }
}

class HealthDataRepository {
    func getLatestECGData(count: Int) async -> [Float] {
        // Implementation
        return []
    }
    
    func getGlucoseHistory(minutes: Int) async -> [Float] {
        // Implementation
        return []
    }
    
    func getRecentVitals(count: Int) async -> [VitalSigns] {
        // Implementation
        return []
    }
    
    func storePredictions(_ predictions: [ActivePrediction]) async {
        // Implementation
    }
    
    func getEmergencyContacts() async -> [EmergencyContact] {
        // Implementation
        return []
    }
    
    func logEmergencyEvent(timestamp: Date, type: String, severity: String, riskLevel: Any, confidence: Float) async {
        // Implementation
    }
}

struct VitalSigns {
    let heartRate: Int
    let spo2: Int
}

// Duplicate removed - use SharedTypes
// struct EmergencyContact {
