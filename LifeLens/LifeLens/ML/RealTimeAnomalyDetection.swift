import Foundation
import CoreML
import Accelerate
/*
// import CreateML  // Not available on iOS
// MARK: - Real-Time Anomaly Detection System
class RealTimeAnomalyDetector {
    
    // MARK: - ECG Anomaly Detection
    class ECGAnomalyDetector {
        private var resNetModel: MLModel?
        private var efficientNetModel: MLModel?
        private let signalProcessor = SignalProcessor()
        private let arrhythmiaClassifier = ArrhythmiaClassifier()
        
        struct ECGAnalysis {
            let heartRate: Double
            let heartRateVariability: Double
            let arrhythmiaDetected: Bool
            let arrhythmiaType: ArrhythmiaType?
            let confidence: Double
            let pWaveAbnormality: Bool
            let qrsComplexWidth: Double
            let qtInterval: Double
            let stSegmentElevation: Double
            let urgencyLevel: UrgencyLevel
            let recommendations: [String]
        }
        
        enum ArrhythmiaType {
            case atrialFibrillation
            case ventricularTachycardia
            case bradycardia
            case tachycardia
            case prematureVentricularContraction
            case prematureAtrialContraction
            case atrioventricularBlock
            case bundleBranchBlock
        }
        
        enum UrgencyLevel {
            case normal
            case monitor
            case warning
            case urgent
            case critical
        }
        
        func analyzeECGSignal(_ signal: [Double], samplingRate: Double = 360.0) async -> ECGAnalysis {
            // Preprocess signal
            let filteredSignal = signalProcessor.bandpassFilter(signal, lowCutoff: 0.5, highCutoff: 45.0, samplingRate: samplingRate)
            let normalizedSignal = signalProcessor.normalize(filteredSignal)
            
            // Extract features
            let features = extractECGFeatures(normalizedSignal, samplingRate: samplingRate)
            
            // Deep learning classification
            let arrhythmiaResult = await classifyArrhythmia(normalizedSignal)
            
            // Calculate urgency level
            let urgency = calculateUrgencyLevel(
                arrhythmia: arrhythmiaResult.type,
                confidence: arrhythmiaResult.confidence,
                heartRate: features.heartRate
            )
            
            // Generate recommendations
            let recommendations = generateECGRecommendations(
                arrhythmia: arrhythmiaResult.type,
                urgency: urgency,
                heartRate: features.heartRate
            )
            
            return ECGAnalysis(
                heartRate: features.heartRate,
                heartRateVariability: features.hrv,
                arrhythmiaDetected: arrhythmiaResult.type != nil,
                arrhythmiaType: arrhythmiaResult.type,
                confidence: arrhythmiaResult.confidence,
                pWaveAbnormality: features.pWaveAbnormal,
                qrsComplexWidth: features.qrsWidth,
                qtInterval: features.qtInterval,
                stSegmentElevation: features.stElevation,
                urgencyLevel: urgency,
                recommendations: recommendations
            )
        }
        
        private func extractECGFeatures(_ signal: [Double], samplingRate: Double) -> ECGFeatures {
            // R-peak detection using Pan-Tompkins algorithm
            let rPeaks = detectRPeaks(signal, samplingRate: samplingRate)
            
            // Calculate heart rate and HRV
            let rrIntervals = calculateRRIntervals(rPeaks, samplingRate: samplingRate)
            let heartRate = 60.0 / (rrIntervals.mean ?? 60.0)
            let hrv = calculateHRV(rrIntervals)
            
            // Detect P, Q, S, T waves
            let waves = detectWaves(signal, rPeaks: rPeaks, samplingRate: samplingRate)
            
            // Calculate intervals and segments
            let qrsWidth = calculateQRSWidth(waves, samplingRate: samplingRate)
            let qtInterval = calculateQTInterval(waves, samplingRate: samplingRate)
            let stElevation = calculateSTElevation(signal, waves: waves)
            
            return ECGFeatures(
                heartRate: heartRate,
                hrv: hrv,
                pWaveAbnormal: waves.pWaveAbnormal,
                qrsWidth: qrsWidth,
                qtInterval: qtInterval,
                stElevation: stElevation
            )
        }
        
        private func classifyArrhythmia(_ signal: [Double]) async -> (type: ArrhythmiaType?, confidence: Double) {
            // Use ensemble of deep learning models
            guard let resNet = resNetModel, let efficientNet = efficientNetModel else {
                return (nil, 0.0)
            }
            
            // Prepare input for models
            let inputArray = try? MLMultiArray(shape: [1, signal.count as NSNumber], dataType: .float32)
            guard let input = inputArray else { return (nil, 0.0) }
            
            for (index, value) in signal.enumerated() {
                input[index] = NSNumber(value: Float(value))
            }
            
            // Get predictions from both models
            let resNetPrediction = try? resNet.prediction(from: MLFeatureProvider())
            let efficientNetPrediction = try? efficientNet.prediction(from: MLFeatureProvider())
            
            // Ensemble voting
            return arrhythmiaClassifier.ensembleClassification(
                resNetPrediction,
                efficientNetPrediction
            )
        }
    }
    
    // MARK: - Sleep Pattern Anomaly Detection
    class SleepAnomalyDetector {
        private let isolationForest = IsolationForest()
        private let autoencoder = Autoencoder()
        
        struct SleepAnomaly {
            let anomalyDetected: Bool
            let anomalyScore: Double
            let sleepStageDistribution: [SleepStage: Double]
            let respiratoryEvents: Int
            let movementEvents: Int
            let heartRateAnomalies: Int
            let sleepQualityScore: Double
            let possibleConditions: [SleepCondition]
            let recommendations: [String]
        }
        
        enum SleepStage {
            case awake
            case lightSleep
            case deepSleep
            case remSleep
        }
        
        enum SleepCondition {
            case sleepApnea
            case insomnia
            case restlessLegSyndrome
            case narcolepsy
            case circadianRhythmDisorder
        }
        
        func detectSleepAnomalies(
            accelerometer: [Double],
            heartRate: [Double],
            respiratoryRate: [Double],
            duration: TimeInterval
        ) -> SleepAnomaly {
            // Extract sleep features
            let features = extractSleepFeatures(
                accelerometer: accelerometer,
                heartRate: heartRate,
                respiratoryRate: respiratoryRate
            )
            
            // Isolation Forest for anomaly detection
            let isolationScore = isolationForest.anomalyScore(features)
            
            // Autoencoder for deep anomaly detection
            let reconstructionError = autoencoder.reconstructionError(features)
            
            // Combine scores
            let combinedAnomalyScore = (isolationScore + reconstructionError) / 2.0
            let isAnomaly = combinedAnomalyScore > 0.7
            
            // Analyze sleep stages
            let sleepStages = analyzeSleepStages(accelerometer, heartRate: heartRate)
            
            // Detect specific events
            let respiratoryEvents = detectRespiratoryEvents(respiratoryRate)
            let movementEvents = detectMovementEvents(accelerometer)
            let hrAnomalies = detectHeartRateAnomalies(heartRate)
            
            // Identify possible conditions
            let conditions = identifySleepConditions(
                anomalyScore: combinedAnomalyScore,
                respiratoryEvents: respiratoryEvents,
                sleepStages: sleepStages
            )
            
            // Calculate sleep quality
            let qualityScore = calculateSleepQuality(
                sleepStages: sleepStages,
                anomalyScore: combinedAnomalyScore,
                events: respiratoryEvents + movementEvents + hrAnomalies
            )
            
            // Generate recommendations
            let recommendations = generateSleepRecommendations(
                conditions: conditions,
                qualityScore: qualityScore
            )
            
            return SleepAnomaly(
                anomalyDetected: isAnomaly,
                anomalyScore: combinedAnomalyScore,
                sleepStageDistribution: sleepStages,
                respiratoryEvents: respiratoryEvents,
                movementEvents: movementEvents,
                heartRateAnomalies: hrAnomalies,
                sleepQualityScore: qualityScore,
                possibleConditions: conditions,
                recommendations: recommendations
            )
        }
    }
    
    // MARK: - Activity Pattern Anomaly Detection
    class ActivityAnomalyDetector {
        private let oneClassSVM = OneClassSVM()
        private let localOutlierFactor = LocalOutlierFactor()
        
        struct ActivityAnomaly {
            let isAnomaly: Bool
            let anomalyType: AnomalyType?
            let severity: Double
            let activityLevel: ActivityLevel
            let energyExpenditure: Double
            let stepCountAnomaly: Bool
            let heartRateAnomaly: Bool
            let locationAnomaly: Bool
            let timePatternAnomaly: Bool
            let healthImpact: HealthImpact
            let alerts: [Alert]
        }
        
        enum AnomalyType {
            case suddenInactivity
            case unusualHighActivity
            case irregularPattern
            case potentialFall
            case prolongedStationary
            case abnormalGait
        }
        
        enum ActivityLevel {
            case sedentary
            case light
            case moderate
            case vigorous
            case extreme
        }
        
        enum HealthImpact {
            case positive
            case neutral
            case concerning
            case critical
        }
        
        struct Alert {
            let type: String
            let message: String
            let severity: AlertSeverity
        }
        
        enum AlertSeverity {
            case info
            case warning
            case urgent
        }
        
        func detectActivityAnomalies(
            steps: [Int],
            heartRate: [Double],
            location: [CLLocation],
            accelerometer: [AccelerometerReading],
            timeWindow: TimeInterval
        ) -> ActivityAnomaly {
            // Extract comprehensive features
            let features = extractActivityFeatures(
                steps: steps,
                heartRate: heartRate,
                location: location,
                accelerometer: accelerometer
            )
            
            // Multi-algorithm anomaly detection
            let svmScore = oneClassSVM.predict(features)
            let lofScore = localOutlierFactor.score(features)
            
            // Combine scores with weighted average
            let anomalyScore = 0.6 * svmScore + 0.4 * lofScore
            let isAnomaly = anomalyScore > 0.65
            
            // Detect specific anomaly types
            let anomalyType = identifyAnomalyType(
                features: features,
                anomalyScore: anomalyScore
            )
            
            // Check individual components
            let stepAnomaly = detectStepCountAnomaly(steps)
            let hrAnomaly = detectHeartRateActivityAnomaly(heartRate, steps: steps)
            let locAnomaly = detectLocationAnomaly(location)
            let timeAnomaly = detectTimePatternAnomaly(features.timeDistribution)
            
            // Calculate activity level and energy
            let activityLevel = calculateActivityLevel(steps, heartRate: heartRate)
            let energy = calculateEnergyExpenditure(
                steps: steps,
                heartRate: heartRate,
                duration: timeWindow
            )
            
            // Assess health impact
            let impact = assessHealthImpact(
                anomalyType: anomalyType,
                anomalyScore: anomalyScore,
                activityLevel: activityLevel
            )
            
            // Generate alerts
            let alerts = generateActivityAlerts(
                anomalyType: anomalyType,
                impact: impact,
                components: (stepAnomaly, hrAnomaly, locAnomaly, timeAnomaly)
            )
            
            return ActivityAnomaly(
                isAnomaly: isAnomaly,
                anomalyType: anomalyType,
                severity: anomalyScore,
                activityLevel: activityLevel,
                energyExpenditure: energy,
                stepCountAnomaly: stepAnomaly,
                heartRateAnomaly: hrAnomaly,
                locationAnomaly: locAnomaly,
                timePatternAnomaly: timeAnomaly,
                healthImpact: impact,
                alerts: alerts
            )
        }
    }
    
    // MARK: - Supporting Classes
    
    class IsolationForest {
        private var trees: [IsolationTree] = []
        private let numberOfTrees = 100
        
        func anomalyScore(_ features: [Double]) -> Double {
            // Simplified isolation forest implementation
            var scores: [Double] = []
            
            for tree in trees {
                let pathLength = tree.pathLength(features)
                scores.append(pathLength)
            }
            
            let averagePathLength = scores.reduce(0, +) / Double(scores.count)
            let expectedPathLength = 2.0 * (log(Double(features.count - 1)) + 0.5772) - (2.0 * Double(features.count - 1) / Double(features.count))
            
            return pow(2.0, -averagePathLength / expectedPathLength)
        }
    }
    
    class Autoencoder {
        private var encoder: MLModel?
        private var decoder: MLModel?
        
        func reconstructionError(_ features: [Double]) -> Double {
            // Simplified autoencoder reconstruction error
            guard let encoder = encoder, let decoder = decoder else {
                return 0.0
            }
            
            // Encode features
            let encoded = encodeFeatures(features, model: encoder)
            
            // Decode back
            let reconstructed = decodeFeatures(encoded, model: decoder)
            
            // Calculate MSE
            var error = 0.0
            for i in 0..<features.count {
                let diff = features[i] - reconstructed[i]
                error += diff * diff
            }
            
            return sqrt(error / Double(features.count))
        }
        
        private func encodeFeatures(_ features: [Double], model: MLModel) -> [Double] {
            // Placeholder for actual encoding
            return features.map { $0 * 0.5 }
        }
        
        private func decodeFeatures(_ encoded: [Double], model: MLModel) -> [Double] {
            // Placeholder for actual decoding
            return encoded.map { $0 * 2.0 }
        }
    }
    
    class OneClassSVM {
        private let kernel = RBFKernel(gamma: 0.1)
        private var supportVectors: [[Double]] = []
        private var alphas: [Double] = []
        private var rho = 0.0
        
        func predict(_ features: [Double]) -> Double {
            var decision = -rho
            
            for i in 0..<supportVectors.count {
                decision += alphas[i] * kernel.compute(features, supportVectors[i])
            }
            
            return decision > 0 ? 0.0 : 1.0
        }
    }
    
    class LocalOutlierFactor {
        private let k = 20 // Number of neighbors
        private var data: [[Double]] = []
        
        func score(_ features: [Double]) -> Double {
            // Simplified LOF calculation
            let distances = calculateKNearestDistances(features, k: k)
            let lrd = localReachabilityDensity(distances)
            let lof = localOutlierFactor(lrd, neighbors: findKNearest(features, k: k))
            
            // Normalize to [0, 1]
            return min(max((lof - 1.0) / 2.0, 0.0), 1.0)
        }
        
        private func calculateKNearestDistances(_ point: [Double], k: Int) -> [Double] {
            // Placeholder implementation
            return Array(repeating: 1.0, count: k)
        }
        
        private func localReachabilityDensity(_ distances: [Double]) -> Double {
            return 1.0 / (distances.reduce(0, +) / Double(distances.count))
        }
        
        private func localOutlierFactor(_ lrd: Double, neighbors: [[Double]]) -> Double {
            // Simplified calculation
            return 1.5 // Placeholder
        }
        
        private func findKNearest(_ point: [Double], k: Int) -> [[Double]] {
            // Placeholder
            return []
        }
    }
    
    struct RBFKernel {
        let gamma: Double
        
        func compute(_ x: [Double], _ y: [Double]) -> Double {
            var squaredDistance = 0.0
            for i in 0..<min(x.count, y.count) {
                let diff = x[i] - y[i]
                squaredDistance += diff * diff
            }
            return exp(-gamma * squaredDistance)
        }
    }
}
// MARK: - Helper Structures
struct ECGFeatures {
    let heartRate: Double
    let hrv: Double
    let pWaveAbnormal: Bool
    let qrsWidth: Double
    let qtInterval: Double
    let stElevation: Double
}
struct IsolationTree {
    func pathLength(_ features: [Double]) -> Double {
        // Simplified path length calculation
        return Double(features.count) * 0.5
    }
}
class SignalProcessor {
    func bandpassFilter(_ signal: [Double], lowCutoff: Double, highCutoff: Double, samplingRate: Double) -> [Double] {
        // Simplified bandpass filter
        return signal
    }
    
    func normalize(_ signal: [Double]) -> [Double] {
        guard !signal.isEmpty else { return signal }
        let maxVal = signal.max() ?? 1.0
        let minVal = signal.min() ?? 0.0
        let range = maxVal - minVal
        guard range > 0 else { return signal }
        return signal.map { ($0 - minVal) / range }
    }
}
class ArrhythmiaClassifier {
    func ensembleClassification(_ pred1: MLFeatureProvider?, _ pred2: MLFeatureProvider?) -> (type: RealTimeAnomalyDetector.ECGAnomalyDetector.ArrhythmiaType?, confidence: Double) {
        // Placeholder ensemble logic
        return (.atrialFibrillation, 0.85)
    }
}
// MARK: - Helper Functions
func detectRPeaks(_ signal: [Double], samplingRate: Double) -> [Int] {
    // Simplified R-peak detection
    var peaks: [Int] = []
    let threshold = signal.max() ?? 0.0 * 0.6
    
    for i in 1..<signal.count-1 {
        if signal[i] > threshold && signal[i] > signal[i-1] && signal[i] > signal[i+1] {
            peaks.append(i)
        }
    }
    return peaks
}
func calculateRRIntervals(_ rPeaks: [Int], samplingRate: Double) -> [Double] {
    guard rPeaks.count > 1 else { return [] }
    var intervals: [Double] = []
    
    for i in 1..<rPeaks.count {
        let interval = Double(rPeaks[i] - rPeaks[i-1]) / samplingRate
        intervals.append(interval)
    }
    return intervals
}
func calculateHRV(_ rrIntervals: [Double]) -> Double {
    guard !rrIntervals.isEmpty else { return 0.0 }
    
    let mean = rrIntervals.reduce(0, +) / Double(rrIntervals.count)
    let squaredDiffs = rrIntervals.map { pow($0 - mean, 2) }
    let variance = squaredDiffs.reduce(0, +) / Double(squaredDiffs.count)
    
    return sqrt(variance) * 1000 // RMSSD in milliseconds
}
// Additional helper functions would continue...
extension Array where Element == Double {
    var mean: Double? {
        guard !self.isEmpty else { return nil }
        return self.reduce(0, +) / Double(self.count)
    }
}
import CoreLocation
struct AccelerometerReading {
    let x: Double
    let y: Double
    let z: Double
    let timestamp: TimeInterval
}
// Placeholder implementations for remaining helper functions
func detectWaves(_ signal: [Double], rPeaks: [Int], samplingRate: Double) -> (pWaveAbnormal: Bool, qWavePresent: Bool, sWavePresent: Bool, tWavePresent: Bool) {
    return (false, true, true, true)
}
func calculateQRSWidth(_ waves: (pWaveAbnormal: Bool, qWavePresent: Bool, sWavePresent: Bool, tWavePresent: Bool), samplingRate: Double) -> Double {
    return 0.08 // Normal QRS width in seconds
}
func calculateQTInterval(_ waves: (pWaveAbnormal: Bool, qWavePresent: Bool, sWavePresent: Bool, tWavePresent: Bool), samplingRate: Double) -> Double {
    return 0.4 // Normal QT interval in seconds
}
func calculateSTElevation(_ signal: [Double], waves: (pWaveAbnormal: Bool, qWavePresent: Bool, sWavePresent: Bool, tWavePresent: Bool)) -> Double {
    return 0.0 // No elevation
}
func calculateUrgencyLevel(arrhythmia: RealTimeAnomalyDetector.ECGAnomalyDetector.ArrhythmiaType?, confidence: Double, heartRate: Double) -> RealTimeAnomalyDetector.ECGAnomalyDetector.UrgencyLevel {
    guard let arrhythmia = arrhythmia else {
        if heartRate < 40 || heartRate > 150 {
            return .warning
        }
        return .normal
    }
    
    switch arrhythmia {
    case .ventricularTachycardia:
        return confidence > 0.8 ? .critical : .urgent
    case .atrialFibrillation:
        return confidence > 0.7 ? .urgent : .warning
    case .bradycardia, .tachycardia:
        return .warning
    default:
        return .monitor
    }
}
func generateECGRecommendations(arrhythmia: RealTimeAnomalyDetector.ECGAnomalyDetector.ArrhythmiaType?, urgency: RealTimeAnomalyDetector.ECGAnomalyDetector.UrgencyLevel, heartRate: Double) -> [String] {
    var recommendations: [String] = []
    
    switch urgency {
    case .critical:
        recommendations.append("Seek immediate medical attention - Call emergency services")
    case .urgent:
        recommendations.append("Contact your healthcare provider immediately")
    case .warning:
        recommendations.append("Schedule an appointment with your cardiologist")
    case .monitor:
        recommendations.append("Continue monitoring and log symptoms")
    case .normal:
        recommendations.append("Heart rhythm appears normal")
    }
    
    if let arrhythmia = arrhythmia {
        switch arrhythmia {
        case .atrialFibrillation:
            recommendations.append("Avoid caffeine and alcohol")
            recommendations.append("Monitor for symptoms: palpitations, shortness of breath, fatigue")
        case .ventricularTachycardia:
            recommendations.append("Avoid strenuous activity until cleared by physician")
        case .bradycardia:
            if heartRate < 50 {
                recommendations.append("Monitor for dizziness or fainting")
            }
        case .tachycardia:
            recommendations.append("Practice relaxation techniques")
            recommendations.append("Stay hydrated")
        default:
            break
        }
    }
    
    return recommendations
}
// Sleep analysis helpers
func extractSleepFeatures(accelerometer: [Double], heartRate: [Double], respiratoryRate: [Double]) -> [Double] {
    var features: [Double] = []
    
    // Movement features
    features.append(accelerometer.mean ?? 0.0)
    features.append(accelerometer.max() ?? 0.0)
    features.append(accelerometer.min() ?? 0.0)
    
    // Heart rate features
    features.append(heartRate.mean ?? 0.0)
    features.append(calculateHRV(heartRate))
    
    // Respiratory features
    features.append(respiratoryRate.mean ?? 0.0)
    features.append(respiratoryRate.max() ?? 0.0 - (respiratoryRate.min() ?? 0.0))
    
    return features
}
func analyzeSleepStages(_ accelerometer: [Double], heartRate: [Double]) -> [RealTimeAnomalyDetector.SleepAnomalyDetector.SleepStage: Double] {
    // Simplified sleep stage analysis
    return [
        .deepSleep: 0.25,
        .lightSleep: 0.45,
        .remSleep: 0.20,
        .awake: 0.10
    ]
}
func detectRespiratoryEvents(_ respiratoryRate: [Double]) -> Int {
    // Detect apnea events (respiratory rate drops)
    var events = 0
    for rate in respiratoryRate {
        if rate < 8.0 { // Below normal respiratory rate
            events += 1
        }
    }
    return events
}
func detectMovementEvents(_ accelerometer: [Double]) -> Int {
    // Detect significant movements during sleep
    let threshold = 2.0
    var events = 0
    for reading in accelerometer {
        if reading > threshold {
            events += 1
        }
    }
    return events
}
func detectHeartRateAnomalies(_ heartRate: [Double]) -> Int {
    // Detect abnormal heart rate patterns during sleep
    var anomalies = 0
    for rate in heartRate {
        if rate < 40 || rate > 100 { // Outside normal sleep range
            anomalies += 1
        }
    }
    return anomalies
}
func identifySleepConditions(anomalyScore: Double, respiratoryEvents: Int, sleepStages: [RealTimeAnomalyDetector.SleepAnomalyDetector.SleepStage: Double]) -> [RealTimeAnomalyDetector.SleepAnomalyDetector.SleepCondition] {
    var conditions: [RealTimeAnomalyDetector.SleepAnomalyDetector.SleepCondition] = []
    
    if respiratoryEvents > 5 {
        conditions.append(.sleepApnea)
    }
    
    if let awakePortion = sleepStages[.awake], awakePortion > 0.3 {
        conditions.append(.insomnia)
    }
    
    if anomalyScore > 0.8 {
        conditions.append(.circadianRhythmDisorder)
    }
    
    return conditions
}
func calculateSleepQuality(sleepStages: [RealTimeAnomalyDetector.SleepAnomalyDetector.SleepStage: Double], anomalyScore: Double, events: Int) -> Double {
    var quality = 100.0
    
    // Deduct for anomalies
    quality -= anomalyScore * 20.0
    
    // Deduct for events
    quality -= Double(min(events, 20))
    
    // Factor in sleep stage distribution
    if let deepSleep = sleepStages[.deepSleep], deepSleep < 0.15 {
        quality -= 10.0
    }
    
    if let awake = sleepStages[.awake], awake > 0.15 {
        quality -= 15.0
    }
    
    return max(0, min(100, quality))
}
func generateSleepRecommendations(conditions: [RealTimeAnomalyDetector.SleepAnomalyDetector.SleepCondition], qualityScore: Double) -> [String] {
    var recommendations: [String] = []
    
    if qualityScore < 60 {
        recommendations.append("Consider consulting a sleep specialist")
    }
    
    for condition in conditions {
        switch condition {
        case .sleepApnea:
            recommendations.append("Potential sleep apnea detected - seek medical evaluation")
            recommendations.append("Consider sleeping on your side")
            recommendations.append("Avoid alcohol before bedtime")
        case .insomnia:
            recommendations.append("Practice good sleep hygiene")
            recommendations.append("Maintain consistent sleep schedule")
            recommendations.append("Limit screen time before bed")
        case .restlessLegSyndrome:
            recommendations.append("Increase iron intake if deficient")
            recommendations.append("Gentle stretching before bed may help")
        case .circadianRhythmDisorder:
            recommendations.append("Expose yourself to bright light in the morning")
            recommendations.append("Avoid bright lights in the evening")
        default:
            break
        }
    }
    
    return recommendations
}
// Activity analysis helpers
func extractActivityFeatures(steps: [Int], heartRate: [Double], location: [CLLocation], accelerometer: [AccelerometerReading]) -> (timeDistribution: [String: Double], features: [Double]) {
    var features: [Double] = []
    
    // Step features
    let totalSteps = Double(steps.reduce(0, +))
    features.append(totalSteps)
    features.append(Double(steps.max() ?? 0))
    
    // Heart rate features
    features.append(heartRate.mean ?? 0.0)
    features.append(heartRate.max() ?? 0.0)
    
    // Location features
    let totalDistance = calculateTotalDistance(location)
    features.append(totalDistance)
    
    // Accelerometer features
    let avgAcceleration = calculateAverageAcceleration(accelerometer)
    features.append(avgAcceleration)
    
    let timeDistribution = ["morning": 0.3, "afternoon": 0.4, "evening": 0.3]
    
    return (timeDistribution, features)
}
func calculateTotalDistance(_ locations: [CLLocation]) -> Double {
    guard locations.count > 1 else { return 0.0 }
    
    var totalDistance = 0.0
    for i in 1..<locations.count {
        totalDistance += locations[i].distance(from: locations[i-1])
    }
    return totalDistance
}
func calculateAverageAcceleration(_ readings: [AccelerometerReading]) -> Double {
    guard !readings.isEmpty else { return 0.0 }
    
    let magnitudes = readings.map { sqrt($0.x * $0.x + $0.y * $0.y + $0.z * $0.z) }
    return magnitudes.reduce(0, +) / Double(magnitudes.count)
}
func identifyAnomalyType(features: (timeDistribution: [String: Double], features: [Double]), anomalyScore: Double) -> RealTimeAnomalyDetector.ActivityAnomalyDetector.AnomalyType? {
    guard anomalyScore > 0.65 else { return nil }
    
    let totalSteps = features.features[0]
    let avgAcceleration = features.features[5]
    
    if totalSteps < 100 && avgAcceleration < 0.5 {
        return .prolongedStationary
    } else if totalSteps > 30000 {
        return .unusualHighActivity
    } else if avgAcceleration > 5.0 {
        return .potentialFall
    }
    
    return .irregularPattern
}
func detectStepCountAnomaly(_ steps: [Int]) -> Bool {
    let total = steps.reduce(0, +)
    return total < 500 || total > 30000
}
func detectHeartRateActivityAnomaly(_ heartRate: [Double], steps: [Int]) -> Bool {
    let avgHR = heartRate.mean ?? 70
    let totalSteps = steps.reduce(0, +)
    
    // Check if heart rate is too high for activity level
    if totalSteps < 1000 && avgHR > 100 {
        return true
    }
    
    // Check if heart rate is too low for high activity
    if totalSteps > 10000 && avgHR < 60 {
        return true
    }
    
    return false
}
func detectLocationAnomaly(_ locations: [CLLocation]) -> Bool {
    guard locations.count > 1 else { return false }
    
    // Check for unusual speed or distance
    for i in 1..<locations.count {
        let speed = locations[i].speed
        if speed > 50 { // Over 50 m/s is unusual for normal activity
            return true
        }
    }
    return false
}
func detectTimePatternAnomaly(_ timeDistribution: [String: Double]) -> Bool {
    // Check if activity is heavily skewed to unusual times
    if let nightActivity = timeDistribution["night"], nightActivity > 0.5 {
        return true
    }
    return false
}
func calculateActivityLevel(_ steps: [Int], heartRate: [Double]) -> RealTimeAnomalyDetector.ActivityAnomalyDetector.ActivityLevel {
    let totalSteps = steps.reduce(0, +)
    let avgHR = heartRate.mean ?? 70
    
    if totalSteps < 2500 {
        return .sedentary
    } else if totalSteps < 5000 {
        return .light
    } else if totalSteps < 10000 {
        return .moderate
    } else if totalSteps < 15000 {
        return .vigorous
    } else {
        return .extreme
    }
}
func calculateEnergyExpenditure(steps: [Int], heartRate: [Double], duration: TimeInterval) -> Double {
    let totalSteps = Double(steps.reduce(0, +))
    let avgHR = heartRate.mean ?? 70
    
    // Simplified calorie calculation
    let stepCalories = totalSteps * 0.04
    let hrCalories = (avgHR - 60) * duration / 60 * 0.1
    
    return stepCalories + hrCalories
}
func assessHealthImpact(anomalyType: RealTimeAnomalyDetector.ActivityAnomalyDetector.AnomalyType?, anomalyScore: Double, activityLevel: RealTimeAnomalyDetector.ActivityAnomalyDetector.ActivityLevel) -> RealTimeAnomalyDetector.ActivityAnomalyDetector.HealthImpact {
    guard let anomalyType = anomalyType else {
        switch activityLevel {
        case .moderate, .vigorous:
            return .positive
        case .sedentary:
            return .concerning
        default:
            return .neutral
        }
    }
    
    switch anomalyType {
    case .potentialFall:
        return .critical
    case .prolongedStationary:
        return .concerning
    case .unusualHighActivity:
        return anomalyScore > 0.85 ? .concerning : .neutral
    default:
        return .neutral
    }
}
func generateActivityAlerts(anomalyType: RealTimeAnomalyDetector.ActivityAnomalyDetector.AnomalyType?, impact: RealTimeAnomalyDetector.ActivityAnomalyDetector.HealthImpact, components: (Bool, Bool, Bool, Bool)) -> [RealTimeAnomalyDetector.ActivityAnomalyDetector.Alert] {
    var alerts: [RealTimeAnomalyDetector.ActivityAnomalyDetector.Alert] = []
    
    if let anomalyType = anomalyType {
        switch anomalyType {
        case .potentialFall:
            alerts.append(RealTimeAnomalyDetector.ActivityAnomalyDetector.Alert(
                type: "Fall Detection",
                message: "Potential fall detected. Are you okay?",
                severity: .urgent
            ))
        case .prolongedStationary:
            alerts.append(RealTimeAnomalyDetector.ActivityAnomalyDetector.Alert(
                type: "Inactivity Alert",
                message: "You've been inactive for an extended period. Consider taking a walk.",
                severity: .warning
            ))
        case .unusualHighActivity:
            alerts.append(RealTimeAnomalyDetector.ActivityAnomalyDetector.Alert(
                type: "High Activity",
                message: "Unusually high activity detected. Remember to rest and hydrate.",
                severity: .info
            ))
        default:
            break
        }
    }
    
    if components.1 { // Heart rate anomaly
        alerts.append(RealTimeAnomalyDetector.ActivityAnomalyDetector.Alert(
            type: "Heart Rate",
            message: "Abnormal heart rate pattern detected during activity",
            severity: .warning
        ))
    }
    
    return alerts
}
*/
