// ErrorHandler.swift
import Foundation
import SwiftUI

class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var errorHistory: [AppError] = []
    
    private let maxErrorHistory = 50
    private let logger = AppLogger.shared
    
    private init() {}
    
    // MARK: - Error Types
    
    enum AppError: LocalizedError, Identifiable {
        case networkError(NetworkError)
        case authenticationError(AuthError)
        case healthDataError(HealthDataError)
        case bluetoothError(BluetoothError)
        case mlProcessingError(MLError)
        case storageError(StorageError)
        case systemError(SystemError)
        
        var id: String {
            switch self {
            case .networkError(let error): return "network_\(error.rawValue)"
            case .authenticationError(let error): return "auth_\(error.rawValue)"
            case .healthDataError(let error): return "health_\(error.rawValue)"
            case .bluetoothError(let error): return "bluetooth_\(error.rawValue)"
            case .mlProcessingError(let error): return "ml_\(error.rawValue)"
            case .storageError(let error): return "storage_\(error.rawValue)"
            case .systemError(let error): return "system_\(error.rawValue)"
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .networkError(let error):
                return error.localizedDescription
            case .authenticationError(let error):
                return error.localizedDescription
            case .healthDataError(let error):
                return error.localizedDescription
            case .bluetoothError(let error):
                return error.localizedDescription
            case .mlProcessingError(let error):
                return error.localizedDescription
            case .storageError(let error):
                return error.localizedDescription
            case .systemError(let error):
                return error.localizedDescription
            }
        }
        
        var severity: ErrorSeverity {
            switch self {
            case .networkError(let error):
                return error.severity
            case .authenticationError(let error):
                return error.severity
            case .healthDataError(let error):
                return error.severity
            case .bluetoothError(let error):
                return error.severity
            case .mlProcessingError(let error):
                return error.severity
            case .storageError(let error):
                return error.severity
            case .systemError(let error):
                return error.severity
            }
        }
    }
    
    enum NetworkError: Int, CaseIterable {
        case noConnection = 1
        case timeout = 2
        case serverError = 3
        case invalidResponse = 4
        case rateLimited = 5
        
        var localizedDescription: String {
            switch self {
            case .noConnection:
                return "No internet connection available"
            case .timeout:
                return "Request timed out. Please try again"
            case .serverError:
                return "Server error. Please try again later"
            case .invalidResponse:
                return "Invalid response from server"
            case .rateLimited:
                return "Too many requests. Please wait"
            }
        }
        
        var severity: ErrorSeverity {
            switch self {
            case .noConnection, .timeout:
                return .warning
            case .serverError, .invalidResponse:
                return .error
            case .rateLimited:
                return .info
            }
        }
    }
    
    enum AuthError: Int, CaseIterable {
        case tokenExpired = 1
        case invalidCredentials = 2
        case biometricFailed = 3
        case sessionExpired = 4
        
        var localizedDescription: String {
            switch self {
            case .tokenExpired:
                return "Authentication token expired"
            case .invalidCredentials:
                return "Invalid credentials"
            case .biometricFailed:
                return "Biometric authentication failed"
            case .sessionExpired:
                return "Session expired. Please login again"
            }
        }
        
        var severity: ErrorSeverity {
            switch self {
            case .tokenExpired, .sessionExpired:
                return .warning
            case .invalidCredentials, .biometricFailed:
                return .error
            }
        }
    }
    
    enum HealthDataError: Int, CaseIterable {
        case sensorDisconnected = 1
        case invalidData = 2
        case processingFailed = 3
        case storageFull = 4
        
        var localizedDescription: String {
            switch self {
            case .sensorDisconnected:
                return "Health sensor disconnected"
            case .invalidData:
                return "Invalid health data received"
            case .processingFailed:
                return "Failed to process health data"
            case .storageFull:
                return "Health data storage full"
            }
        }
        
        var severity: ErrorSeverity {
            switch self {
            case .sensorDisconnected:
                return .critical
            case .invalidData, .processingFailed:
                return .error
            case .storageFull:
                return .warning
            }
        }
    }
    
    enum BluetoothError: Int, CaseIterable {
        case notAvailable = 1
        case notAuthorized = 2
        case deviceNotFound = 3
        case connectionFailed = 4
        case dataTransferFailed = 5
        
        var localizedDescription: String {
            switch self {
            case .notAvailable:
                return "Bluetooth not available"
            case .notAuthorized:
                return "Bluetooth access not authorized"
            case .deviceNotFound:
                return "LifeLens device not found"
            case .connectionFailed:
                return "Failed to connect to device"
            case .dataTransferFailed:
                return "Failed to transfer data"
            }
        }
        
        var severity: ErrorSeverity {
            switch self {
            case .notAvailable, .notAuthorized:
                return .error
            case .deviceNotFound, .connectionFailed:
                return .warning
            case .dataTransferFailed:
                return .error
            }
        }
    }
    
    enum MLError: Int, CaseIterable {
        case modelLoadFailed = 1
        case processingTimeout = 2
        case insufficientData = 3
        case predictionFailed = 4
        
        var localizedDescription: String {
            switch self {
            case .modelLoadFailed:
                return "Failed to load ML model"
            case .processingTimeout:
                return "ML processing timeout"
            case .insufficientData:
                return "Insufficient data for ML processing"
            case .predictionFailed:
                return "ML prediction failed"
            }
        }
        
        var severity: ErrorSeverity {
            switch self {
            case .modelLoadFailed:
                return .critical
            case .processingTimeout, .predictionFailed:
                return .error
            case .insufficientData:
                return .warning
            }
        }
    }
    
    enum StorageError: Int, CaseIterable {
        case writeFailed = 1
        case readFailed = 2
        case corruption = 3
        case quotaExceeded = 4
        
        var localizedDescription: String {
            switch self {
            case .writeFailed:
                return "Failed to save data"
            case .readFailed:
                return "Failed to read data"
            case .corruption:
                return "Data corruption detected"
            case .quotaExceeded:
                return "Storage quota exceeded"
            }
        }
        
        var severity: ErrorSeverity {
            switch self {
            case .corruption:
                return .critical
            case .writeFailed, .readFailed:
                return .error
            case .quotaExceeded:
                return .warning
            }
        }
    }
    
    enum SystemError: Int, CaseIterable {
        case memoryPressure = 1
        case batteryLow = 2
        case thermalThrottling = 3
        case appTermination = 4
        
        var localizedDescription: String {
            switch self {
            case .memoryPressure:
                return "Low memory condition"
            case .batteryLow:
                return "Battery level critical"
            case .thermalThrottling:
                return "Device overheating"
            case .appTermination:
                return "App terminated unexpectedly"
            }
        }
        
        var severity: ErrorSeverity {
            switch self {
            case .appTermination:
                return .critical
            case .memoryPressure, .batteryLow:
                return .warning
            case .thermalThrottling:
                return .error
            }
        }
    }
    
    enum ErrorSeverity {
        case info
        case warning
        case error
        case critical
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .critical: return .purple
            }
        }
        
        var shouldShowAlert: Bool {
            switch self {
            case .info: return false
            case .warning: return true
            case .error: return true
            case .critical: return true
            }
        }
    }
    
    // MARK: - Error Handling Methods
    
    func handle(_ error: AppError) {
        logger.error("Error occurred: \(error.localizedDescription)")
        
        // Add to history
        errorHistory.append(error)
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst()
        }
        
        // Set current error if it should show alert
        if error.severity.shouldShowAlert {
            DispatchQueue.main.async {
                self.currentError = error
            }
        }
        
        // Handle critical errors immediately
        if error.severity == .critical {
            handleCriticalError(error)
        }
        
        // Send to analytics
        logErrorToAnalytics(error)
    }
    
    func handle(_ error: Error, context: String = "") {
        let appError = convertToAppError(error, context: context)
        handle(appError)
    }
    
    func clearCurrentError() {
        currentError = nil
    }
    
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func handleCriticalError(_ error: AppError) {
        switch error {
        case .healthDataError(.sensorDisconnected):
            // Trigger emergency protocols
            NotificationCenter.default.post(name: .emergencyAlert, object: nil)
        case .mlProcessingError(.modelLoadFailed):
            // Fallback to basic monitoring
            NotificationCenter.default.post(name: .mlServiceDegraded, object: nil)
        case .systemError(.appTermination):
            // Attempt recovery
            attemptAppRecovery()
        default:
            break
        }
    }
    
    private func convertToAppError(_ error: Error, context: String) -> AppError {
        // Convert generic errors to specific app errors
        if let networkError = error as? URLError {
            switch networkError.code {
            case .notConnectedToInternet:
                return .networkError(.noConnection)
            case .timedOut:
                return .networkError(.timeout)
            case .serverCertificateUntrusted:
                return .networkError(.serverError)
            default:
                return .networkError(.invalidResponse)
            }
        }
        
        // Default to system error
        return .systemError(.memoryPressure)
    }
    
    private func attemptAppRecovery() {
        // Implement app recovery logic
        logger.info("Attempting app recovery")
        
        // Clear caches
        clearCaches()
        
        // Restart critical services
        restartCriticalServices()
    }
    
    private func clearCaches() {
        // Clear image caches, temporary files, etc.
        URLCache.shared.removeAllCachedResponses()
    }
    
    private func restartCriticalServices() {
        // Restart ML service, health monitoring, etc.
        NotificationCenter.default.post(name: .restartServices, object: nil)
    }
    
    private func logErrorToAnalytics(_ error: AppError) {
        let analyticsData: [String: Any] = [
            "error_type": String(describing: type(of: error)),
            "error_id": error.id,
            "severity": String(describing: error.severity),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        logger.logEvent("app_error", parameters: analyticsData)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let mlServiceDegraded = Notification.Name("mlServiceDegraded")
    static let restartServices = Notification.Name("restartServices")
}
