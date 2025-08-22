// LocalPatternDetection.swift
import Foundation

class LocalPatternDetection {
    
    enum RiskLevel: String, CaseIterable {
        case normal = "NORMAL"
        case low = "LOW"
        case moderate = "MODERATE"
        case high = "HIGH"
        case critical = "CRITICAL"
        
        var priority: Int {
            switch self {
            case .normal: return 0
            case .low: return 1
            case .moderate: return 2
            case .high: return 3
            case .critical: return 4
            }
        }
    }
    
    struct SensorReadings {
        let glucoseValues: [Double]
        let bloodPressureValues: [(systolic: Int, diastolic: Int)]
        let heartRateValues: [Int]
        let spo2Values: [Float]
        let timestamps: [Date]
    }
    
    struct RiskAssessment {
        let level: RiskLevel
        let recommendation: String
        let confidence: Double
    }
    
    struct SpO2Reading {
        let value: Float
        let timestamp: Date
    }
    
    struct DesaturationAnalysis {
        let severity: String
        let pattern: String
        let frequency: Int
    }
    
    struct CoherenceAnalysis {
        let stressLevel: String
        let coherence: Double
        let recommendation: String
    }
    
    // MARK: - Pattern Detection Methods
    
    func detectDangerousPatterns(readings: SensorReadings) -> RiskAssessment {
        var riskScore = 0.0
        var recommendations: [String] = []
        
        // Analyze glucose patterns
        if let glucoseRisk = analyzeGlucosePatterns(readings.glucoseValues) {
            riskScore += glucoseRisk.score
            if glucoseRisk.recommendation != "" {
                recommendations.append(glucoseRisk.recommendation)
            }
        }
        
        // Analyze blood pressure patterns
        if let bpRisk = analyzeBloodPressurePatterns(readings.bloodPressureValues) {
            riskScore += bpRisk.score
            if bpRisk.recommendation != "" {
                recommendations.append(bpRisk.recommendation)
            }
        }
        
        // Analyze heart rate patterns
        if let hrRisk = analyzeHeartRatePatterns(readings.heartRateValues) {
            riskScore += hrRisk.score
            if hrRisk.recommendation != "" {
                recommendations.append(hrRisk.recommendation)
            }
        }
        
        // Determine risk level
        let riskLevel: RiskLevel
        if riskScore >= 8.0 {
            riskLevel = .critical
        } else if riskScore >= 6.0 {
            riskLevel = .high
        } else if riskScore >= 4.0 {
            riskLevel = .moderate
        } else if riskScore >= 2.0 {
            riskLevel = .low
        } else {
            riskLevel = .normal
        }
        
        let recommendation = recommendations.isEmpty ? "All patterns normal" : recommendations.joined(separator: ". ")
        
        return RiskAssessment(
            level: riskLevel,
            recommendation: recommendation,
            confidence: min(riskScore / 10.0, 1.0)
        )
    }
    
    func detectSpO2Drops(readings: [SpO2Reading]) -> DesaturationAnalysis {
        guard readings.count >= 5 else {
            return DesaturationAnalysis(severity: "Insufficient data", pattern: "Need more readings", frequency: 0)
        }
        
        var dropCount = 0
        var severeDrops = 0
        
        for i in 1..<readings.count {
            let drop = readings[i-1].value - readings[i].value
            if drop > 3 {
                dropCount += 1
                if drop > 5 {
                    severeDrops += 1
                }
            }
        }
        
        let severity: String
        let pattern: String
        
        if severeDrops >= 3 {
            severity = "Severe"
            pattern = "Multiple severe desaturations detected"
        } else if dropCount >= 5 {
            severity = "Moderate"
            pattern = "Frequent desaturations detected"
        } else if dropCount >= 2 {
            severity = "Mild"
            pattern = "Occasional desaturations"
        } else {
            severity = "Normal"
            pattern = "No significant desaturations"
        }
        
        return DesaturationAnalysis(
            severity: severity,
            pattern: pattern,
            frequency: dropCount
        )
    }
    
    func detectCardiacCoherence(heartRates: [Int]) -> CoherenceAnalysis {
        guard heartRates.count >= 10 else {
            return CoherenceAnalysis(
                stressLevel: "Insufficient data",
                coherence: 0.0,
                recommendation: "Need more heart rate data"
            )
        }
        
        // Calculate heart rate variability
        let variability = calculateHeartRateVariability(heartRates)
        
        // Determine stress level based on HRV
        let stressLevel: String
        let recommendation: String
        
        if variability > 50 {
            stressLevel = "Low stress"
            recommendation = "Good cardiac coherence, continue current activities"
        } else if variability > 30 {
            stressLevel = "Moderate stress"
            recommendation = "Consider stress reduction techniques"
        } else {
            stressLevel = "High stress"
            recommendation = "High stress detected, recommend relaxation exercises"
        }
        
        return CoherenceAnalysis(
            stressLevel: stressLevel,
            coherence: variability / 100.0, // Normalize to 0-1
            recommendation: recommendation
        )
    }
    
    // MARK: - Helper Methods
    
    private func analyzeGlucosePatterns(_ values: [Double]) -> (score: Double, recommendation: String)? {
        guard values.count >= 3 else { return nil }
        
        var score = 0.0
        var recommendation = ""
        
        // Check for hypoglycemia
        let lowValues = values.filter { $0 < 70 }
        if lowValues.count > 0 {
            score += 3.0
            recommendation += "Hypoglycemia detected. "
        }
        
        // Check for hyperglycemia
        let highValues = values.filter { $0 > 250 }
        if highValues.count > 0 {
            score += 2.0
            recommendation += "Hyperglycemia detected. "
        }
        
        // Check for rapid changes
        if values.count >= 2 {
            let changes = zip(values, values.dropFirst()).map { abs($0 - $1) }
            let maxChange = changes.max() ?? 0
            if maxChange > 50 {
                score += 2.0
                recommendation += "Rapid glucose changes detected. "
            }
        }
        
        return (score, recommendation)
    }
    
    private func analyzeBloodPressurePatterns(_ values: [(systolic: Int, diastolic: Int)]) -> (score: Double, recommendation: String)? {
        guard values.count >= 3 else { return nil }
        
        var score = 0.0
        var recommendation = ""
        
        // Check for hypertension
        let hypertensive = values.filter { $0.systolic > 140 || $0.diastolic > 90 }
        if hypertensive.count > 0 {
            score += 2.0
            recommendation += "Hypertension detected. "
        }
        
        // Check for hypotension
        let hypotensive = values.filter { $0.systolic < 90 || $0.diastolic < 60 }
        if hypotensive.count > 0 {
            score += 2.0
            recommendation += "Hypotension detected. "
        }
        
        // Check for wide pulse pressure
        let widePulse = values.filter { ($0.systolic - $0.diastolic) > 60 }
        if widePulse.count > 0 {
            score += 1.0
            recommendation += "Wide pulse pressure detected. "
        }
        
        return (score, recommendation)
    }
    
    private func analyzeHeartRatePatterns(_ values: [Int]) -> (score: Double, recommendation: String)? {
        guard values.count >= 5 else { return nil }
        
        var score = 0.0
        var recommendation = ""
        
        // Check for tachycardia
        let tachycardic = values.filter { $0 > 100 }
        if tachycardic.count > 0 {
            score += 2.0
            recommendation += "Tachycardia detected. "
        }
        
        // Check for bradycardia
        let bradycardic = values.filter { $0 < 50 }
        if bradycardic.count > 0 {
            score += 2.0
            recommendation += "Bradycardia detected. "
        }
        
        // Check for irregularity
        let variability = calculateHeartRateVariability(values)
        if variability < 20 {
            score += 1.0
            recommendation += "Low heart rate variability detected. "
        }
        
        return (score, recommendation)
    }
    
    private func calculateHeartRateVariability(_ values: [Int]) -> Double {
        guard values.count >= 2 else { return 0.0 }
        
        let intervals = zip(values, values.dropFirst()).map { Double(abs($0 - $1)) }
        let sum = intervals.reduce(0.0) { $0 + $1 }
        return sum / Double(intervals.count)
    }
}