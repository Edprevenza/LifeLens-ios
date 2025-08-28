//
//  HealthDataSyncService.swift
//  LifeLens
//
//  Unified Health Data Sync Service for iOS
//

import Foundation
import SwiftUI
import Combine

class HealthDataSyncService: ObservableObject {
    static let shared = HealthDataSyncService()
    
    private let healthKitManager = HealthKitManager.shared
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    init() {
        setupHealthKitObservers()
        loadLastSyncDate()
    }
    
    // MARK: - Setup
    
    private func setupHealthKitObservers() {
        // Observe HealthKit data changes
        healthKitManager.$heartRate
            .dropFirst()
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncHealthData()
            }
            .store(in: &cancellables)
        
        healthKitManager.$bloodPressure
            .dropFirst()
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncHealthData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func requestHealthKitAuthorization() {
        healthKitManager.requestAuthorization()
    }
    
    func syncHealthData() {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncStatus = .syncing
        
        Task {
            do {
                // Collect all health data
                let healthData = collectHealthData()
                
                // Send to backend
                try await uploadHealthData(healthData)
                
                // Update sync status
                await MainActor.run {
                    self.syncStatus = .success
                    self.lastSyncDate = Date()
                    self.saveLastSyncDate()
                    self.isSyncing = false
                }
                
                // Reset status after delay
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    self.syncStatus = .idle
                }
                
            } catch {
                await MainActor.run {
                    self.syncStatus = .error(error.localizedDescription)
                    self.isSyncing = false
                }
            }
        }
    }
    
    func startAutoSync() {
        // Auto-sync every 15 minutes
        Timer.publish(every: 900, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.syncHealthData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func collectHealthData() -> HealthDataPayload {
        return HealthDataPayload(
            timestamp: Date(),
            vitals: VitalsData(
                heartRate: healthKitManager.heartRate,
                restingHeartRate: healthKitManager.restingHeartRate,
                walkingHeartRate: healthKitManager.walkingHeartRate,
                heartRateVariability: healthKitManager.heartRateVariability,
                bloodPressure: BloodPressureData(
                    systolic: healthKitManager.bloodPressure.systolic,
                    diastolic: healthKitManager.bloodPressure.diastolic
                ),
                respiratoryRate: healthKitManager.respiratoryRate,
                bloodOxygen: healthKitManager.bloodOxygen,
                bodyTemperature: healthKitManager.bodyTemperature,
                vo2Max: healthKitManager.vo2Max
            ),
            bodyMeasurements: BodyMeasurementsData(
                weight: healthKitManager.weight,
                height: healthKitManager.height,
                bmi: healthKitManager.bmi,
                bodyFatPercentage: healthKitManager.bodyFatPercentage,
                leanBodyMass: healthKitManager.leanBodyMass,
                waistCircumference: healthKitManager.waistCircumference
            ),
            ecgReadings: healthKitManager.ecgReadings.map { reading in
                ECGData(
                    date: reading.date,
                    classification: reading.classification,
                    averageHeartRate: reading.averageHeartRate,
                    samplingFrequency: reading.samplingFrequency
                )
            }
        )
    }
    
    private func uploadHealthData(_ data: HealthDataPayload) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(data)
        
        var request = URLRequest(url: URL(string: "\(APIConfig.baseURL)/health/sync")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-ID")
        
        if let token = AuthenticationService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = jsonData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw HealthSyncError.uploadFailed
        }
    }
    
    private func loadLastSyncDate() {
        if let date = UserDefaults.standard.object(forKey: "LastHealthSyncDate") as? Date {
            lastSyncDate = date
        }
    }
    
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "LastHealthSyncDate")
    }
}

// MARK: - Data Models

struct HealthDataPayload: Codable {
    let timestamp: Date
    let vitals: VitalsData
    let bodyMeasurements: BodyMeasurementsData
    let ecgReadings: [SyncECGData]
}

struct VitalsData: Codable {
    let heartRate: Double
    let restingHeartRate: Double
    let walkingHeartRate: Double
    let heartRateVariability: Double
    let bloodPressure: SyncBloodPressureData
    let respiratoryRate: Double
    let bloodOxygen: Double
    let bodyTemperature: Double
    let vo2Max: Double
}

struct SyncBloodPressureData: Codable {
    let systolic: Double
    let diastolic: Double
}

struct BodyMeasurementsData: Codable {
    let weight: Double
    let height: Double
    let bmi: Double
    let bodyFatPercentage: Double
    let leanBodyMass: Double
    let waistCircumference: Double
}

struct SyncECGData: Codable {
    let date: Date
    let classification: String
    let averageHeartRate: Double
    let samplingFrequency: Double
}

enum HealthSyncError: Error {
    case uploadFailed
    case noData
    case unauthorized
}