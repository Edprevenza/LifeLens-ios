// Configuration.swift
import Foundation

struct Configuration {
    static let shared = Configuration()
    
    private init() {}
    
    // MARK: - API Configuration
    
    // Production AWS API Gateway endpoint
    var apiBaseURL: String {
        return "https://fwynbeqn5k.execute-api.eu-west-1.amazonaws.com"
    }
    
    var apiTimeout: TimeInterval {
        return 30.0
    }
    
    var apiVersion: String {
        return "v1"
    }
    
    var fullAPIURL: String {
        return "\(apiBaseURL)/\(apiVersion)"
    }
    
    // MARK: - App Configuration
    
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.lifelens.app"
    }
    
    var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "LifeLens"
    }
    
    // MARK: - Feature Flags
    
    var isMockModeEnabled: Bool {
        #if DEBUG
        return false  // Use real backend API
        #else
        return false
        #endif
    }
    
    var isDebugMenuEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var isBiometricEnabled: Bool {
        return true
    }
    
    // MARK: - Health Monitoring Settings
    
    var healthDataRefreshInterval: TimeInterval {
        return 300.0  // 5 minutes
    }
    
    var emergencyAlertThreshold: TimeInterval {
        return 10.0  // 10 seconds for emergency response
    }
    
    var maxHealthRecordsToStore: Int {
        return 1000
    }
    
    // MARK: - Bluetooth Settings
    
    var bluetoothScanDuration: TimeInterval {
        return 30.0  // 30 seconds scan timeout
    }
    
    var bluetoothServiceUUID: String {
        return "00001800-0000-1000-8000-00805F9B34FB"  // Generic Access Service
    }
    
    // MARK: - Security Settings
    
    var sessionTimeout: TimeInterval {
        return 900.0  // 15 minutes
    }
    
    var maxLoginAttempts: Int {
        return 5
    }
    
    var passwordMinLength: Int {
        return 8
    }
    
    // MARK: - Debug Settings
    
    var isLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var logLevel: LogLevel {
        #if DEBUG
        return .debug
        #else
        return .error
        #endif
    }
}

enum LogLevel: Int {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    
    var description: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
}