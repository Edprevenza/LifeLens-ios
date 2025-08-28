// EdgeMLModels.swift
import Foundation

class EdgeMLModels {
    
    struct GlucoseReading {
        let value: Double
        let timestamp: Date
    }
    
    enum HypoglycemiaRisk {
        case low
        case moderate
        case high
        case critical
    }
    
    struct AFibResult {
        let detected: Bool
        let confidence: Float
        let message: String
    }
    
    struct VTachResult {
        let detected: Bool
        let message: String
    }
    
    struct STEMIResult {
        let detected: Bool
        let message: String
    }
    
    struct SpO2Alert {
        let severity: SpO2Severity
        let message: String
    }
    
    enum SpO2Severity {
        case warning
        case critical
    }
    
    // MARK: - AFib Detection
    
    func detectAtrialFibrillation(ecgData: [Float]) -> AFibResult {
        // Simplified AFib detection logic
        let irregularity = calculateIrregularity(ecgData)
        let detected = irregularity > 0.3
        let confidence = min(irregularity * 2.0, 1.0)
        
        return AFibResult(
            detected: detected,
            confidence: Float(confidence),
            message: detected ? "Atrial fibrillation pattern detected" : "Normal rhythm"
        )
    }
    
    // MARK: - VTach Detection
    
    func detectVentricularTachycardia(ecgData: [Float], heartRate: Int) -> VTachResult {
        let detected = heartRate > 100 && hasWideQRS(ecgData)
        
        return VTachResult(
            detected: detected,
            message: detected ? "Ventricular tachycardia detected" : "Normal rhythm"
        )
    }
    
    // MARK: - STEMI Detection
    
    func detectSTElevation(ecgData: [Float]) -> STEMIResult {
        let stElevation = calculateSTElevation(ecgData)
        let detected = stElevation > 0.1
        
        return STEMIResult(
            detected: detected,
            message: detected ? "ST elevation detected" : "Normal ST segment"
        )
    }
    
    // MARK: - Hypoglycemia Prediction
    
    func predictHypoglycemia(glucoseReadings: [GlucoseReading], currentValue: Double) -> HypoglycemiaRisk {
        guard glucoseReadings.count >= 3 else { return .low }
        
        let recentReadings = glucoseReadings.suffix(3).map { $0.value }
        let trend = calculateTrend(recentReadings)
        let rateOfChange = calculateRateOfChange(recentReadings)
        
        if currentValue < 70 || (trend < -10 && rateOfChange < -5) {
            return .critical
        } else if currentValue < 90 || (trend < -5 && rateOfChange < -2) {
            return .high
        } else if trend < -2 {
            return .moderate
        } else {
            return .low
        }
    }
    
    // MARK: - SpO2 Critical Drop Detection
    
    func detectSpO2CriticalDrop(spo2Values: [Float]) -> SpO2Alert? {
        guard spo2Values.count >= 5 else { return nil }
        
        let recentValues = Array(spo2Values.suffix(5))
        let average = recentValues.reduce(0, +) / Float(recentValues.count)
        let minValue = recentValues.min() ?? 100
        
        if minValue < 85 {
            return SpO2Alert(
                severity: .critical,
                message: "Critical SpO2 drop detected: \(Int(minValue))%"
            )
        } else if average < 92 {
            return SpO2Alert(
                severity: .warning,
                message: "Low SpO2 levels: \(Int(average))%"
            )
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func calculateIrregularity(_ ecgData: [Float]) -> Double {
        guard ecgData.count > 100 else { return 0.0 }
        
        // Simplified irregularity calculation
        let intervals = calculateRRIntervals(ecgData)
        let meanInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - meanInterval, 2) }.reduce(0, +) / Double(intervals.count)
        
        return sqrt(variance) / meanInterval
    }
    
    private func calculateRRIntervals(_ ecgData: [Float]) -> [Double] {
        // Simplified RR interval calculation
        var intervals: [Double] = []
        var lastPeak = 0
        
        for i in 1..<ecgData.count {
            if ecgData[i] > 0.5 && ecgData[i-1] <= 0.5 {
                if lastPeak > 0 {
                    intervals.append(Double(i - lastPeak))
                }
                lastPeak = i
            }
        }
        
        return intervals
    }
    
    private func hasWideQRS(_ ecgData: [Float]) -> Bool {
        // Simplified QRS width detection
        return ecgData.count > 50 && ecgData.max() ?? 0 > 0.8
    }
    
    private func calculateSTElevation(_ ecgData: [Float]) -> Double {
        // Simplified ST elevation calculation
        guard ecgData.count > 20 else { return 0.0 }
        
        let baseline = Double(ecgData.prefix(10).reduce(0) { $0 + $1 }) / 10.0
        let stSegment = Double(ecgData.suffix(10).reduce(0) { $0 + $1 }) / 10.0
        
        return Double(stSegment - baseline)
    }
    
    private func calculateTrend(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }
        
        let first = values.first!
        let last = values.last!
        return last - first
    }
    
    private func calculateRateOfChange(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }
        
        var totalChange = 0.0
        for i in 1..<values.count {
            totalChange += values[i] - values[i-1]
        }
        
        return totalChange / Double(values.count - 1)
    }
}