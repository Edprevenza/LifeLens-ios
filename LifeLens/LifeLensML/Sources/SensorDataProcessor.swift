// SensorDataProcessor.swift
import Foundation

class SensorDataProcessor {
    
    struct RawSensorData {
        let deviceId: String
        let deviceModel: String
        let firmwareVersion: String
        let batteryLevel: Int
        let ecgData: [Float]?
        let ppgData: [Float]?
        let glucoseData: [Double]?
        let bloodPressure: [BPReading]?
        let spo2Data: [Int]?
        let heartRateData: [Int]?
        let temperature: [Double]?
        let respiratoryRate: [Int]?
    }
    
    struct BPReading {
        let systolic: Int
        let diastolic: Int
        let pulse: Int
        let timestamp: Date
    }
    
    struct ProcessedData {
        let deviceId: String
        let timestamp: Date
        let features: FeatureSet
        let qualityScore: Double
        let metadata: DataMetadata
    }
    
    struct FeatureSet {
        let ecgFeatures: ECGFatures?
        let glucoseFeatures: GlucoseFeatures?
        let bloodPressureFeatures: BloodPressureFeatures?
        let spo2Features: SpO2Features?
    }
    
    struct ECGFatures {
        let heartRateVariability: Double
        let qtInterval: Double
        let prInterval: Double
        let qrsWidth: Double
        let stLevel: Double
        let tWaveAmplitude: Double
    }
    
    struct GlucoseFeatures {
        let mean: Double
        let std: Double
        let cv: Double
        let trend: String
        let timeInRange: Double
    }
    
    struct BloodPressureFeatures {
        let systolicMean: Double
        let diastolicMean: Double
        let pulsePressure: Double
        let variability: Double
    }
    
    struct SpO2Features {
        let mean: Double
        let min: Double
        let desaturationEvents: Int
        let timeBelow90: Double
    }
    
    struct DataMetadata {
        let deviceModel: String
        let firmwareVersion: String
        let batteryLevel: Int
        let signalQuality: String
    }
    
    // MARK: - Data Processing Methods
    
    func preprocessForCloud(raw: RawSensorData) -> ProcessedData {
        let features = extractFeatures(from: raw)
        let qualityScore = calculateQualityScore(raw: raw)
        let metadata = DataMetadata(
            deviceModel: raw.deviceModel,
            firmwareVersion: raw.firmwareVersion,
            batteryLevel: raw.batteryLevel,
            signalQuality: assessSignalQuality(raw: raw)
        )
        
        return ProcessedData(
            deviceId: raw.deviceId,
            timestamp: Date(),
            features: features,
            qualityScore: qualityScore,
            metadata: metadata
        )
    }
    
    private func extractFeatures(from raw: RawSensorData) -> FeatureSet {
        let ecgFeatures = extractECGFeatures(from: raw.ecgData)
        let glucoseFeatures = extractGlucoseFeatures(from: raw.glucoseData)
        let bloodPressureFeatures = extractBloodPressureFeatures(from: raw.bloodPressure)
        let spo2Features = extractSpO2Features(from: raw.spo2Data)
        
        return FeatureSet(
            ecgFeatures: ecgFeatures,
            glucoseFeatures: glucoseFeatures,
            bloodPressureFeatures: bloodPressureFeatures,
            spo2Features: spo2Features
        )
    }
    
    private func extractECGFeatures(from ecgData: [Float]?) -> ECGFatures? {
        guard let data = ecgData, data.count >= 100 else { return nil }
        
        let hrv = calculateHeartRateVariability(data)
        let qtInterval = calculateQTInterval(data)
        let prInterval = calculatePRInterval(data)
        let qrsWidth = calculateQRSWidth(data)
        let stLevel = calculateSTLevel(data)
        let tWaveAmplitude = calculateTWaveAmplitude(data)
        
        return ECGFatures(
            heartRateVariability: hrv,
            qtInterval: qtInterval,
            prInterval: prInterval,
            qrsWidth: qrsWidth,
            stLevel: stLevel,
            tWaveAmplitude: tWaveAmplitude
        )
    }
    
    private func extractGlucoseFeatures(from glucoseData: [Double]?) -> GlucoseFeatures? {
        guard let data = glucoseData, data.count >= 3 else { return nil }
        
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        let std = sqrt(variance)
        let cv = mean != 0 ? std / mean : 0
        
        let trend = calculateGlucoseTrend(data)
        let timeInRange = calculateTimeInRange(data)
        
        return GlucoseFeatures(
            mean: mean,
            std: std,
            cv: cv,
            trend: trend,
            timeInRange: timeInRange
        )
    }
    
    private func extractBloodPressureFeatures(from bpData: [BPReading]?) -> BloodPressureFeatures? {
        guard let data = bpData, data.count >= 2 else { return nil }
        
        let systolicValues = data.map { Double($0.systolic) }
        let diastolicValues = data.map { Double($0.diastolic) }
        
        let systolicMean = systolicValues.reduce(0, +) / Double(systolicValues.count)
        let diastolicMean = diastolicValues.reduce(0, +) / Double(diastolicValues.count)
        let pulsePressure = systolicMean - diastolicMean
        
        let systolicVariance = systolicValues.map { pow($0 - systolicMean, 2) }.reduce(0, +) / Double(systolicValues.count)
        let variability = sqrt(systolicVariance)
        
        return BloodPressureFeatures(
            systolicMean: systolicMean,
            diastolicMean: diastolicMean,
            pulsePressure: pulsePressure,
            variability: variability
        )
    }
    
    private func extractSpO2Features(from spo2Data: [Int]?) -> SpO2Features? {
        guard let data = spo2Data, data.count >= 5 else { return nil }
        
        let doubleData = data.map { Double($0) }
        let mean = doubleData.reduce(0, +) / Double(doubleData.count)
        let min = doubleData.min() ?? 100
        
        let desaturationEvents = data.filter { $0 < 90 }.count
        let timeBelow90 = Double(desaturationEvents) / Double(data.count) * 100
        
        return SpO2Features(
            mean: mean,
            min: min,
            desaturationEvents: desaturationEvents,
            timeBelow90: timeBelow90
        )
    }
    
    private func calculateQualityScore(raw: RawSensorData) -> Double {
        var score = 1.0
        
        // Check data completeness
        if raw.ecgData == nil || raw.ecgData!.isEmpty { score -= 0.2 }
        if raw.glucoseData == nil || raw.glucoseData!.isEmpty { score -= 0.2 }
        if raw.bloodPressure == nil || raw.bloodPressure!.isEmpty { score -= 0.2 }
        if raw.spo2Data == nil || raw.spo2Data!.isEmpty { score -= 0.1 }
        
        // Check battery level
        if raw.batteryLevel < 20 { score -= 0.1 }
        if raw.batteryLevel < 10 { score -= 0.2 }
        
        // Check data quality
        if let ecgData = raw.ecgData, ecgData.count < 50 { score -= 0.1 }
        if let glucoseData = raw.glucoseData, glucoseData.count < 3 { score -= 0.1 }
        
        return max(0.0, score)
    }
    
    private func assessSignalQuality(raw: RawSensorData) -> String {
        let qualityScore = calculateQualityScore(raw: raw)
        
        if qualityScore >= 0.9 {
            return "Excellent"
        } else if qualityScore >= 0.7 {
            return "Good"
        } else if qualityScore >= 0.5 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
    
    // MARK: - ECG Feature Extraction
    
    private func calculateHeartRateVariability(_ data: [Float]) -> Double {
        // Simplified HRV calculation
        let peaks = findPeaks(in: data)
        guard peaks.count >= 3 else { return 0.0 }
        
        var intervals: [Double] = []
        for i in 1..<peaks.count {
            intervals.append(Double(peaks[i] - peaks[i-1]))
        }
        
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
        
        return sqrt(variance)
    }
    
    private func calculateQTInterval(_ data: [Float]) -> Double {
        // Simplified QT interval calculation
        return 400.0 // Default value in milliseconds
    }
    
    private func calculatePRInterval(_ data: [Float]) -> Double {
        // Simplified PR interval calculation
        return 160.0 // Default value in milliseconds
    }
    
    private func calculateQRSWidth(_ data: [Float]) -> Double {
        // Simplified QRS width calculation
        return 80.0 // Default value in milliseconds
    }
    
    private func calculateSTLevel(_ data: [Float]) -> Double {
        // Simplified ST level calculation
        guard data.count >= 20 else { return 0.0 }
        
        let baseline = Double(data.prefix(10).reduce(0, +)) / 10.0
        let stSegment = Double(data.suffix(10).reduce(0, +)) / 10.0
        
        return stSegment - baseline
    }
    
    private func calculateTWaveAmplitude(_ data: [Float]) -> Double {
        // Simplified T wave amplitude calculation
        return Double(data.max() ?? 0.0)
    }
    
    private func findPeaks(in data: [Float]) -> [Int] {
        var peaks: [Int] = []
        let threshold = (data.max() ?? 0) * 0.6
        
        for i in 1..<(data.count - 1) {
            if data[i] > threshold &&
               data[i] > data[i-1] &&
               data[i] > data[i+1] {
                peaks.append(i)
            }
        }
        
        return peaks
    }
    
    // MARK: - Glucose Feature Extraction
    
    private func calculateGlucoseTrend(_ data: [Double]) -> String {
        guard data.count >= 2 else { return "Stable" }
        
        let first = data.first!
        let last = data.last!
        let change = last - first
        
        if change > 20 {
            return "Rising"
        } else if change < -20 {
            return "Falling"
        } else {
            return "Stable"
        }
    }
    
    private func calculateTimeInRange(_ data: [Double]) -> Double {
        let inRange = data.filter { $0 >= 70 && $0 <= 180 }.count
        return Double(inRange) / Double(data.count) * 100
    }
}