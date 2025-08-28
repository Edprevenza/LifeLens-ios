//
//  HealthKitManager.swift
//  LifeLens
//
//  Comprehensive HealthKit Integration for Native Health Data
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    
    // Published health data
    @Published var heartRate: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var walkingHeartRate: Double = 0
    @Published var heartRateVariability: Double = 0
    @Published var bloodPressure: (systolic: Double, diastolic: Double) = (0, 0)
    @Published var respiratoryRate: Double = 0
    @Published var bloodOxygen: Double = 0
    @Published var bodyTemperature: Double = 0
    @Published var vo2Max: Double = 0
    @Published var weight: Double = 0
    @Published var height: Double = 0
    @Published var bmi: Double = 0
    @Published var bodyFatPercentage: Double = 0
    @Published var leanBodyMass: Double = 0
    @Published var waistCircumference: Double = 0
    @Published var ecgReadings: [ECGReading] = []
    @Published var isAuthorized = false
    
    // MARK: - Health Data Types
    
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        // Vitals
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHeartRate)
        }
        if let walkingHeartRate = HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage) {
            types.insert(walkingHeartRate)
        }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }
        if let bloodPressureSystolic = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) {
            types.insert(bloodPressureSystolic)
        }
        if let bloodPressureDiastolic = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            types.insert(bloodPressureDiastolic)
        }
        if let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate) {
            types.insert(respiratoryRate)
        }
        if let oxygenSaturation = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
            types.insert(oxygenSaturation)
        }
        if let bodyTemp = HKObjectType.quantityType(forIdentifier: .bodyTemperature) {
            types.insert(bodyTemp)
        }
        if let vo2Max = HKObjectType.quantityType(forIdentifier: .vo2Max) {
            types.insert(vo2Max)
        }
        
        // Body Measurements
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let bmi = HKObjectType.quantityType(forIdentifier: .bodyMassIndex) {
            types.insert(bmi)
        }
        if let bodyFat = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) {
            types.insert(bodyFat)
        }
        if let leanMass = HKObjectType.quantityType(forIdentifier: .leanBodyMass) {
            types.insert(leanMass)
        }
        if let waist = HKObjectType.quantityType(forIdentifier: .waistCircumference) {
            types.insert(waist)
        }
        
        // ECG
        if #available(iOS 14.0, *) {
            if let ecg = HKObjectType.electrocardiogramType() {
                types.insert(ecg)
            }
        }
        
        // Workout
        if let workout = HKObjectType.workoutType() {
            types.insert(workout)
        }
        
        return types
    }
    
    private var writeTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        
        // Add types we want to write back to HealthKit
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let bloodPressureSystolic = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) {
            types.insert(bloodPressureSystolic)
        }
        if let bloodPressureDiastolic = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            types.insert(bloodPressureDiastolic)
        }
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        if let bmi = HKObjectType.quantityType(forIdentifier: .bodyMassIndex) {
            types.insert(bmi)
        }
        
        return types
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.startObservingHealthData()
                    self?.fetchAllHealthData()
                } else if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Fetch Health Data
    
    private func fetchAllHealthData() {
        fetchHeartRateData()
        fetchBloodPressureData()
        fetchRespiratoryRate()
        fetchBloodOxygen()
        fetchBodyTemperature()
        fetchVO2Max()
        fetchBodyMeasurements()
        fetchECGData()
    }
    
    private func fetchHeartRateData() {
        // Current heart rate
        fetchMostRecentSample(for: .heartRate, unit: HKUnit(from: "count/min")) { [weak self] value in
            self?.heartRate = value ?? 0
        }
        
        // Resting heart rate
        fetchMostRecentSample(for: .restingHeartRate, unit: HKUnit(from: "count/min")) { [weak self] value in
            self?.restingHeartRate = value ?? 0
        }
        
        // Walking heart rate
        fetchMostRecentSample(for: .walkingHeartRateAverage, unit: HKUnit(from: "count/min")) { [weak self] value in
            self?.walkingHeartRate = value ?? 0
        }
        
        // Heart rate variability
        fetchMostRecentSample(for: .heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli)) { [weak self] value in
            self?.heartRateVariability = value ?? 0
        }
    }
    
    private func fetchBloodPressureData() {
        // Systolic
        fetchMostRecentSample(for: .bloodPressureSystolic, unit: HKUnit.millimeterOfMercury()) { [weak self] systolic in
            // Diastolic
            self?.fetchMostRecentSample(for: .bloodPressureDiastolic, unit: HKUnit.millimeterOfMercury()) { diastolic in
                DispatchQueue.main.async {
                    self?.bloodPressure = (systolic ?? 0, diastolic ?? 0)
                }
            }
        }
    }
    
    private func fetchRespiratoryRate() {
        fetchMostRecentSample(for: .respiratoryRate, unit: HKUnit(from: "count/min")) { [weak self] value in
            self?.respiratoryRate = value ?? 0
        }
    }
    
    private func fetchBloodOxygen() {
        fetchMostRecentSample(for: .oxygenSaturation, unit: HKUnit.percent()) { [weak self] value in
            self?.bloodOxygen = (value ?? 0) * 100
        }
    }
    
    private func fetchBodyTemperature() {
        fetchMostRecentSample(for: .bodyTemperature, unit: HKUnit.degreeFahrenheit()) { [weak self] value in
            self?.bodyTemperature = value ?? 98.6
        }
    }
    
    private func fetchVO2Max() {
        fetchMostRecentSample(for: .vo2Max, unit: HKUnit(from: "mL/kg·min")) { [weak self] value in
            self?.vo2Max = value ?? 0
        }
    }
    
    private func fetchBodyMeasurements() {
        // Weight
        fetchMostRecentSample(for: .bodyMass, unit: HKUnit.pound()) { [weak self] value in
            self?.weight = value ?? 0
        }
        
        // Height
        fetchMostRecentSample(for: .height, unit: HKUnit.inch()) { [weak self] value in
            self?.height = value ?? 0
        }
        
        // BMI
        fetchMostRecentSample(for: .bodyMassIndex, unit: HKUnit(from: "")) { [weak self] value in
            self?.bmi = value ?? 0
        }
        
        // Body fat percentage
        fetchMostRecentSample(for: .bodyFatPercentage, unit: HKUnit.percent()) { [weak self] value in
            self?.bodyFatPercentage = (value ?? 0) * 100
        }
        
        // Lean body mass
        fetchMostRecentSample(for: .leanBodyMass, unit: HKUnit.pound()) { [weak self] value in
            self?.leanBodyMass = value ?? 0
        }
        
        // Waist circumference
        fetchMostRecentSample(for: .waistCircumference, unit: HKUnit.inch()) { [weak self] value in
            self?.waistCircumference = value ?? 0
        }
    }
    
    private func fetchECGData() {
        guard #available(iOS 14.0, *) else { return }
        
        let ecgType = HKObjectType.electrocardiogramType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: ecgType, predicate: nil, limit: 10, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            guard let ecgSamples = samples as? [HKElectrocardiogram], error == nil else {
                print("Failed to fetch ECG data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self?.ecgReadings = ecgSamples.map { ecg in
                    ECGReading(
                        date: ecg.startDate,
                        classification: self?.classificationString(for: ecg.classification) ?? "Unknown",
                        averageHeartRate: ecg.averageHeartRate?.doubleValue(for: HKUnit(from: "count/min")) ?? 0,
                        samplingFrequency: ecg.samplingFrequency?.doubleValue(for: HKUnit.hertz()) ?? 0
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Helper Methods
    
    private func fetchMostRecentSample(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double?) -> Void) {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let value = sample.quantity.doubleValue(for: unit)
            DispatchQueue.main.async {
                completion(value)
            }
        }
        
        healthStore.execute(query)
    }
    
    @available(iOS 14.0, *)
    private func classificationString(for classification: HKElectrocardiogram.Classification) -> String {
        switch classification {
        case .notSet:
            return "Not Set"
        case .sinusRhythm:
            return "Sinus Rhythm"
        case .atrialFibrillation:
            return "Atrial Fibrillation"
        case .inconclusiveLowHeartRate:
            return "Low Heart Rate"
        case .inconclusiveHighHeartRate:
            return "High Heart Rate"
        case .inconclusivePoorReading:
            return "Poor Reading"
        case .inconclusiveOther:
            return "Inconclusive"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Real-time Monitoring
    
    private func startObservingHealthData() {
        observeHeartRate()
        observeBloodOxygen()
        observeRespiratoryRate()
    }
    
    private func observeHeartRate() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                self?.fetchHeartRateData()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func observeBloodOxygen() {
        guard let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let query = HKObserverQuery(sampleType: oxygenType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                self?.fetchBloodOxygen()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func observeRespiratoryRate() {
        guard let respiratoryType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else { return }
        
        let query = HKObserverQuery(sampleType: respiratoryType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                self?.fetchRespiratoryRate()
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Write Health Data
    
    func saveHeartRate(_ value: Double, date: Date = Date()) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let quantity = HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: value)
        let sample = HKQuantitySample(type: heartRateType, quantity: quantity, start: date, end: date)
        
        healthStore.save(sample) { success, error in
            if !success {
                print("Failed to save heart rate: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func saveBloodPressure(systolic: Double, diastolic: Double, date: Date = Date()) {
        guard let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else { return }
        
        let systolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: systolic)
        let diastolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: diastolic)
        
        let systolicSample = HKQuantitySample(type: systolicType, quantity: systolicQuantity, start: date, end: date)
        let diastolicSample = HKQuantitySample(type: diastolicType, quantity: diastolicQuantity, start: date, end: date)
        
        healthStore.save([systolicSample, diastolicSample]) { success, error in
            if !success {
                print("Failed to save blood pressure: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func saveWeight(_ value: Double, date: Date = Date()) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let quantity = HKQuantity(unit: HKUnit.pound(), doubleValue: value)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)
        
        healthStore.save(sample) { success, error in
            if !success {
                print("Failed to save weight: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

// MARK: - ECG Reading Model
struct ECGReading {
    let date: Date
    let classification: String
    let averageHeartRate: Double
    let samplingFrequency: Double
}