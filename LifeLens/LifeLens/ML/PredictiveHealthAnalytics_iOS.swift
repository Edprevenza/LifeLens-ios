// PredictiveHealthAnalytics_iOS.swift
// iOS-compatible predictive health analytics using CoreML

import Foundation
import CoreML
import Accelerate

// MARK: - Multi-Factor Disease Risk Prediction
public class DiseaseRiskPredictor {
    private var ensembleModels: [MLModel] = []
    
    public struct RiskFactors {
        let hbA1c: Double
        let glucose: Double
        let bmi: Double
        let cholesterol: Double
        let bloodPressure: (systolic: Double, diastolic: Double)
        let age: Int
        let smokingStatus: Bool
        let exerciseMinutes: Double
        let familyHistory: [String]
        let medications: [String]
        let sleepHours: Double
        let stressLevel: Int
    }
    
    public struct RiskPrediction {
        let disease: String
        let riskScore: Double
        let confidence: Double
        let timeHorizon: String
        let contributingFactors: [String: Double]
        let recommendations: [String]
    }
    
    public init() {
        loadModels()
    }
    
    private func loadModels() {
        // Load pre-trained CoreML models
        // In production, these would be actual CoreML models
        print("Loading disease risk prediction models...")
    }
    
    public func predictRisk(factors: RiskFactors) async -> [RiskPrediction] {
        var predictions: [RiskPrediction] = []
        
        // Diabetes Risk
        let diabetesRisk = calculateDiabetesRisk(factors)
        predictions.append(diabetesRisk)
        
        // Cardiovascular Risk
        let cvRisk = calculateCardiovascularRisk(factors)
        predictions.append(cvRisk)
        
        // Hypertension Risk
        let hyperRisk = calculateHypertensionRisk(factors)
        predictions.append(hyperRisk)
        
        return predictions
    }
    
    private func calculateDiabetesRisk(_ factors: RiskFactors) -> RiskPrediction {
        var riskScore = 0.0
        var contributingFactors: [String: Double] = [:]
        
        // HbA1c contribution
        if factors.hbA1c > 5.7 {
            let contribution = min((factors.hbA1c - 5.7) * 0.3, 0.3)
            riskScore += contribution
            contributingFactors["HbA1c"] = contribution
        }
        
        // BMI contribution
        if factors.bmi > 25 {
            let contribution = min((factors.bmi - 25) * 0.02, 0.2)
            riskScore += contribution
            contributingFactors["BMI"] = contribution
        }
        
        // Age contribution
        if factors.age > 45 {
            let contribution = Double(factors.age - 45) * 0.01
            riskScore += contribution
            contributingFactors["Age"] = contribution
        }
        
        // Family history
        if factors.familyHistory.contains("diabetes") {
            riskScore += 0.2
            contributingFactors["Family History"] = 0.2
        }
        
        // Exercise
        if factors.exerciseMinutes < 150 {
            let contribution = (150 - factors.exerciseMinutes) / 150 * 0.1
            riskScore += contribution
            contributingFactors["Low Exercise"] = contribution
        }
        
        let confidence = min(0.85, 0.6 + (Double(contributingFactors.count) * 0.05))
        
        var recommendations: [String] = []
        if factors.hbA1c > 5.7 {
            recommendations.append("Monitor blood glucose regularly")
        }
        if factors.bmi > 25 {
            recommendations.append("Maintain healthy weight through diet and exercise")
        }
        if factors.exerciseMinutes < 150 {
            recommendations.append("Increase weekly exercise to at least 150 minutes")
        }
        
        return RiskPrediction(
            disease: "Type 2 Diabetes",
            riskScore: min(riskScore, 1.0),
            confidence: confidence,
            timeHorizon: "5 years",
            contributingFactors: contributingFactors,
            recommendations: recommendations
        )
    }
    
    private func calculateCardiovascularRisk(_ factors: RiskFactors) -> RiskPrediction {
        var riskScore = 0.0
        var contributingFactors: [String: Double] = [:]
        
        // Blood pressure contribution
        if factors.bloodPressure.systolic > 130 || factors.bloodPressure.diastolic > 80 {
            let contribution = 0.25
            riskScore += contribution
            contributingFactors["Blood Pressure"] = contribution
        }
        
        // Cholesterol contribution
        if factors.cholesterol > 200 {
            let contribution = min((factors.cholesterol - 200) / 100 * 0.2, 0.3)
            riskScore += contribution
            contributingFactors["Cholesterol"] = contribution
        }
        
        // Smoking
        if factors.smokingStatus {
            riskScore += 0.3
            contributingFactors["Smoking"] = 0.3
        }
        
        // Age contribution
        if factors.age > 40 {
            let contribution = Double(factors.age - 40) * 0.015
            riskScore += contribution
            contributingFactors["Age"] = contribution
        }
        
        let confidence = min(0.82, 0.6 + (Double(contributingFactors.count) * 0.05))
        
        var recommendations: [String] = []
        if factors.smokingStatus {
            recommendations.append("Quit smoking - seek support if needed")
        }
        if factors.cholesterol > 200 {
            recommendations.append("Reduce cholesterol through diet modification")
        }
        if factors.bloodPressure.systolic > 130 {
            recommendations.append("Monitor blood pressure regularly")
        }
        
        return RiskPrediction(
            disease: "Cardiovascular Disease",
            riskScore: min(riskScore, 1.0),
            confidence: confidence,
            timeHorizon: "10 years",
            contributingFactors: contributingFactors,
            recommendations: recommendations
        )
    }
    
    private func calculateHypertensionRisk(_ factors: RiskFactors) -> RiskPrediction {
        var riskScore = 0.0
        var contributingFactors: [String: Double] = [:]
        
        // Current blood pressure
        if factors.bloodPressure.systolic > 120 {
            let contribution = min((factors.bloodPressure.systolic - 120) / 40 * 0.3, 0.3)
            riskScore += contribution
            contributingFactors["Pre-hypertension"] = contribution
        }
        
        // BMI contribution
        if factors.bmi > 25 {
            let contribution = min((factors.bmi - 25) * 0.03, 0.2)
            riskScore += contribution
            contributingFactors["BMI"] = contribution
        }
        
        // Stress level
        if factors.stressLevel > 7 {
            let contribution = Double(factors.stressLevel - 7) * 0.05
            riskScore += contribution
            contributingFactors["Stress"] = contribution
        }
        
        // Sleep
        if factors.sleepHours < 7 {
            let contribution = (7 - factors.sleepHours) * 0.05
            riskScore += contribution
            contributingFactors["Poor Sleep"] = contribution
        }
        
        let confidence = min(0.78, 0.6 + (Double(contributingFactors.count) * 0.05))
        
        var recommendations: [String] = []
        if factors.stressLevel > 7 {
            recommendations.append("Practice stress management techniques")
        }
        if factors.sleepHours < 7 {
            recommendations.append("Aim for 7-9 hours of quality sleep")
        }
        recommendations.append("Reduce sodium intake")
        
        return RiskPrediction(
            disease: "Hypertension",
            riskScore: min(riskScore, 1.0),
            confidence: confidence,
            timeHorizon: "3 years",
            contributingFactors: contributingFactors,
            recommendations: recommendations
        )
    }
}

// MARK: - Treatment Optimization Engine
public class TreatmentOptimizer {
    public struct PatientProfile {
        let demographics: Demographics
        let conditions: [String]
        let medications: [String]
        let allergies: [String]
        let labResults: [String: Double]
        let vitalSigns: [String: Double]
    }
    
    public struct TreatmentPlan {
        let medications: [MedicationRecommendation]
        let lifestyle: [String]
        let monitoring: [String]
        let followUp: String
        let confidence: Double
    }
    
    public struct MedicationRecommendation {
        let name: String
        let dosage: String
        let frequency: String
        let duration: String
        let reasoning: String
        let contraindications: [String]
    }
    
    public func optimizeTreatment(profile: PatientProfile) async -> TreatmentPlan {
        // Analyze patient profile
        let medications = recommendMedications(profile)
        let lifestyle = recommendLifestyleChanges(profile)
        let monitoring = determineMonitoringNeeds(profile)
        
        return TreatmentPlan(
            medications: medications,
            lifestyle: lifestyle,
            monitoring: monitoring,
            followUp: "2 weeks",
            confidence: 0.75
        )
    }
    
    private func recommendMedications(_ profile: PatientProfile) -> [MedicationRecommendation] {
        var recommendations: [MedicationRecommendation] = []
        
        // Example: Hypertension treatment
        if profile.conditions.contains("Hypertension") {
            if !profile.medications.contains(where: { $0.lowercased().contains("lisinopril") }) &&
               !profile.allergies.contains(where: { $0.lowercased().contains("ace") }) {
                recommendations.append(MedicationRecommendation(
                    name: "Lisinopril",
                    dosage: "10mg",
                    frequency: "Once daily",
                    duration: "Ongoing",
                    reasoning: "First-line ACE inhibitor for hypertension",
                    contraindications: ["Pregnancy", "Hyperkalemia"]
                ))
            }
        }
        
        // Example: Diabetes treatment
        if profile.conditions.contains("Diabetes") {
            if let hba1c = profile.labResults["HbA1c"], hba1c > 7.0 {
                if !profile.medications.contains(where: { $0.lowercased().contains("metformin") }) {
                    recommendations.append(MedicationRecommendation(
                        name: "Metformin",
                        dosage: "500mg",
                        frequency: "Twice daily",
                        duration: "Ongoing",
                        reasoning: "First-line medication for Type 2 Diabetes",
                        contraindications: ["Renal impairment", "Lactic acidosis history"]
                    ))
                }
            }
        }
        
        return recommendations
    }
    
    private func recommendLifestyleChanges(_ profile: PatientProfile) -> [String] {
        var recommendations: [String] = []
        
        if profile.conditions.contains("Hypertension") {
            recommendations.append("Reduce sodium intake to less than 2300mg per day")
            recommendations.append("Engage in 150 minutes of moderate exercise weekly")
        }
        
        if profile.conditions.contains("Diabetes") {
            recommendations.append("Follow a low-glycemic diet")
            recommendations.append("Monitor blood glucose daily")
        }
        
        // BMI-based recommendations
        if let weight = profile.vitalSigns["weight"],
           let height = profile.vitalSigns["height"] {
            let bmi = weight / pow(height/100, 2)
            if bmi > 25 {
                recommendations.append("Achieve and maintain healthy weight")
            }
        }
        
        return recommendations
    }
    
    private func determineMonitoringNeeds(_ profile: PatientProfile) -> [String] {
        var monitoring: [String] = []
        
        if profile.conditions.contains("Hypertension") {
            monitoring.append("Daily blood pressure monitoring")
        }
        
        if profile.conditions.contains("Diabetes") {
            monitoring.append("Daily blood glucose monitoring")
            monitoring.append("Quarterly HbA1c testing")
        }
        
        if profile.medications.contains(where: { $0.lowercased().contains("warfarin") }) {
            monitoring.append("Weekly INR monitoring")
        }
        
        return monitoring
    }
}

// MARK: - Health Trend Analyzer
public class HealthTrendAnalyzer {
    public func analyzeTrends(dataPoints: [HealthDataPoint]) -> TrendAnalysis {
        guard dataPoints.count > 1 else {
            return TrendAnalysis(trend: .stable, confidence: 0, prediction: nil)
        }
        
        let values = dataPoints.map { $0.value }
        let trend = calculateTrend(values)
        let confidence = calculateConfidence(dataPoints)
        let prediction = predictNextValue(values)
        
        return TrendAnalysis(
            trend: trend,
            confidence: confidence,
            prediction: prediction
        )
    }
    
    public struct TrendAnalysis {
        let trend: Trend
        let confidence: Double
        let prediction: Double?
        
        public enum Trend {
            case increasing
            case decreasing
            case stable
            case volatile
        }
    }
    
    private func calculateTrend(_ values: [Double]) -> TrendAnalysis.Trend {
        guard values.count > 2 else { return .stable }
        
        // Simple linear regression
        let n = Double(values.count)
        let sumX = (0..<values.count).reduce(0.0) { $0 + Double($1) }
        let sumY = values.reduce(0, +)
        let sumXY = values.enumerated().reduce(0.0) { $0 + Double($1.0) * $1.1 }
        let sumX2 = (0..<values.count).reduce(0.0) { $0 + pow(Double($1), 2) }
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - pow(sumX, 2))
        
        // Calculate volatility
        let mean = sumY / n
        let variance = values.reduce(0.0) { $0 + pow($1 - mean, 2) } / n
        let stdDev = sqrt(variance)
        let cv = stdDev / mean // Coefficient of variation
        
        if cv > 0.3 {
            return .volatile
        } else if abs(slope) < 0.01 {
            return .stable
        } else if slope > 0 {
            return .increasing
        } else {
            return .decreasing
        }
    }
    
    private func calculateConfidence(_ dataPoints: [HealthDataPoint]) -> Double {
        // Factors affecting confidence:
        // 1. Number of data points
        // 2. Consistency of measurements
        // 3. Time span coverage
        
        let countFactor = min(Double(dataPoints.count) / 30.0, 1.0) // More data = higher confidence
        
        // Calculate consistency
        let values = dataPoints.map { $0.value }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let cv = sqrt(variance) / mean
        let consistencyFactor = max(0, 1.0 - cv)
        
        // Time span (prefer data over longer periods)
        if let firstDate = dataPoints.first?.timestamp,
           let lastDate = dataPoints.last?.timestamp {
            let timeSpan = lastDate.timeIntervalSince(firstDate)
            let daysCovered = timeSpan / 86400
            let timeFactor = min(daysCovered / 30, 1.0) // 30 days = full confidence
            
            return (countFactor + consistencyFactor + timeFactor) / 3.0
        }
        
        return (countFactor + consistencyFactor) / 2.0
    }
    
    private func predictNextValue(_ values: [Double]) -> Double? {
        guard values.count >= 3 else { return nil }
        
        // Simple moving average prediction
        let recentValues = Array(values.suffix(5))
        return recentValues.reduce(0, +) / Double(recentValues.count)
    }
}