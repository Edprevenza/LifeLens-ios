// PrivacyManager.swift
import Foundation
import CryptoKit
import Security

class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    
    @Published var isDataEncryptionEnabled = true
    @Published var isBiometricEnabled = true
    @Published var isAnalyticsEnabled = false
    @Published var isCrashReportingEnabled = false
    @Published var dataRetentionDays = 30
    
    private let keychainService = KeychainService()
    private let logger = AppLogger.shared
    
    // Encryption keys
    private var encryptionKey: SymmetricKey?
    private let keychainKey = "LifeLensEncryptionKey"
    
    private init() {
        setupEncryption()
        loadPrivacySettings()
    }
    
    // MARK: - Encryption Setup
    
    private func setupEncryption() {
        if let existingKey = loadEncryptionKey() {
            encryptionKey = existingKey
        } else {
            encryptionKey = generateNewEncryptionKey()
            saveEncryptionKey(encryptionKey!)
        }
    }
    
    private func generateNewEncryptionKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    private func loadEncryptionKey() -> SymmetricKey? {
        guard let keyData = keychainService.retrieve(key: keychainKey) else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    private func saveEncryptionKey(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        keychainService.store(key: keychainKey, data: keyData)
    }
    
    // MARK: - Data Encryption/Decryption
    
    func encryptHealthData(_ data: Data) -> Data? {
        guard isDataEncryptionEnabled, let key = encryptionKey else {
            return data
        }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            logger.error("Failed to encrypt health data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func decryptHealthData(_ encryptedData: Data) -> Data? {
        guard isDataEncryptionEnabled, let key = encryptionKey else {
            return encryptedData
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            logger.error("Failed to decrypt health data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func encryptString(_ string: String) -> String? {
        guard let data = string.data(using: .utf8),
              let encryptedData = encryptHealthData(data) else {
            return nil
        }
        
        return encryptedData.base64EncodedString()
    }
    
    func decryptString(_ encryptedString: String) -> String? {
        guard let encryptedData = Data(base64Encoded: encryptedString),
              let decryptedData = decryptHealthData(encryptedData) else {
            return nil
        }
        
        return String(data: decryptedData, encoding: .utf8)
    }
    
    // MARK: - Privacy Settings
    
    private func loadPrivacySettings() {
        isDataEncryptionEnabled = UserDefaults.standard.bool(forKey: "privacy_encryption_enabled")
        isBiometricEnabled = UserDefaults.standard.bool(forKey: "privacy_biometric_enabled")
        isAnalyticsEnabled = UserDefaults.standard.bool(forKey: "privacy_analytics_enabled")
        isCrashReportingEnabled = UserDefaults.standard.bool(forKey: "privacy_crash_reporting_enabled")
        dataRetentionDays = UserDefaults.standard.integer(forKey: "privacy_data_retention_days")
        
        // Set defaults if not previously set
        if UserDefaults.standard.object(forKey: "privacy_encryption_enabled") == nil {
            isDataEncryptionEnabled = true
        }
        if UserDefaults.standard.object(forKey: "privacy_biometric_enabled") == nil {
            isBiometricEnabled = true
        }
        if dataRetentionDays == 0 {
            dataRetentionDays = 30
        }
    }
    
    func updatePrivacySettings(
        encryption: Bool? = nil,
        biometric: Bool? = nil,
        analytics: Bool? = nil,
        crashReporting: Bool? = nil,
        retentionDays: Int? = nil
    ) {
        if let encryption = encryption {
            isDataEncryptionEnabled = encryption
            UserDefaults.standard.set(encryption, forKey: "privacy_encryption_enabled")
        }
        
        if let biometric = biometric {
            isBiometricEnabled = biometric
            UserDefaults.standard.set(biometric, forKey: "privacy_biometric_enabled")
        }
        
        if let analytics = analytics {
            isAnalyticsEnabled = analytics
            UserDefaults.standard.set(analytics, forKey: "privacy_analytics_enabled")
        }
        
        if let crashReporting = crashReporting {
            isCrashReportingEnabled = crashReporting
            UserDefaults.standard.set(crashReporting, forKey: "privacy_crash_reporting_enabled")
        }
        
        if let retentionDays = retentionDays {
            dataRetentionDays = retentionDays
            UserDefaults.standard.set(retentionDays, forKey: "privacy_data_retention_days")
        }
        
        logger.info("Privacy settings updated")
    }
    
    // MARK: - Data Anonymization
    
    func anonymizeHealthData(_ data: [String: Any]) -> [String: Any] {
        var anonymizedData = data
        
        // Remove or hash personally identifiable information
        if let userId = anonymizedData["user_id"] as? String {
            anonymizedData["user_id"] = hashString(userId)
        }
        
        if let deviceId = anonymizedData["device_id"] as? String {
            anonymizedData["device_id"] = hashString(deviceId)
        }
        
        // Round timestamps to hour precision for privacy
        if let timestamp = anonymizedData["timestamp"] as? String,
           let date = ISO8601DateFormatter().date(from: timestamp) {
            let calendar = Calendar.current
            var roundedDate = calendar.date(bySetting: .minute, value: 0, of: date) ?? date
            roundedDate = calendar.date(bySetting: .second, value: 0, of: roundedDate) ?? roundedDate
            anonymizedData["timestamp"] = ISO8601DateFormatter().string(from: roundedDate)
        }
        
        return anonymizedData
    }
    
    private func hashString(_ string: String) -> String {
        let inputData = Data(string.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Data Retention & Cleanup
    
    func cleanupOldData() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -dataRetentionDays, to: Date()) ?? Date()
        
        // Clean up Core Data
        cleanupCoreData(before: cutoffDate)
        
        // Clean up temporary files
        cleanupTemporaryFiles()
        
        // Clean up cached data
        cleanupCachedData()
        
        logger.info("Data cleanup completed")
    }
    
    private func cleanupCoreData(before date: Date) {
        // Implementation would depend on your Core Data model
        // This is a placeholder for the actual cleanup logic
        logger.info("Cleaning up Core Data records before \(date)")
    }
    
    private func cleanupTemporaryFiles() {
        let tempDirectory = FileManager.default.temporaryDirectory
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            for file in tempFiles {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            logger.error("Failed to cleanup temporary files: \(error.localizedDescription)")
        }
    }
    
    private func cleanupCachedData() {
        URLCache.shared.removeAllCachedResponses()
    }
    
    // MARK: - Privacy Compliance
    
    func exportUserData() -> Data? {
        // Export all user data in a privacy-compliant format
        var exportData: [String: Any] = [:]
        
        // Export user profile
        exportData["profile"] = exportUserProfile()
        
        // Export health data (anonymized)
        exportData["health_data"] = exportHealthData()
        
        // Export settings
        exportData["settings"] = exportSettings()
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            return jsonData
        } catch {
            logger.error("Failed to export user data: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func exportUserProfile() -> [String: Any] {
        // Export user profile data
        return [:]
    }
    
    private func exportHealthData() -> [String: Any] {
        // Export anonymized health data
        return [:]
    }
    
    private func exportSettings() -> [String: Any] {
        // Export user settings
        return [:]
    }
    
    func deleteAllUserData() {
        // Delete all user data for GDPR compliance
        
        // Clear Core Data
        clearCoreData()
        
        // Clear UserDefaults
        clearUserDefaults()
        
        // Clear Keychain
        clearKeychain()
        
        // Clear temporary files
        cleanupTemporaryFiles()
        
        // Clear caches
        cleanupCachedData()
        
        logger.info("All user data deleted")
    }
    
    private func clearCoreData() {
        // Implementation would depend on your Core Data setup
        logger.info("Clearing Core Data")
    }
    
    private func clearUserDefaults() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }
    }
    
    private func clearKeychain() {
        // Clear all keychain items for this app
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Security Validation
    
    func validateDataIntegrity() -> Bool {
        // Validate that stored data hasn't been tampered with
        // This is a simplified implementation
        
        guard encryptionKey != nil else {
            logger.error("No encryption key available for integrity validation")
            return false
        }
        
        // Check keychain integrity
        let keychainValid = validateKeychainIntegrity()
        
        // Check data consistency
        let dataValid = validateDataConsistency()
        
        return keychainValid && dataValid
    }
    
    private func validateKeychainIntegrity() -> Bool {
        // Validate keychain items
        return true // Simplified implementation
    }
    
    private func validateDataConsistency() -> Bool {
        // Validate data consistency
        return true // Simplified implementation
    }
    
    // MARK: - Privacy Audit
    
    func generatePrivacyAuditReport() -> [String: Any] {
        let report: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "encryption_enabled": isDataEncryptionEnabled,
            "biometric_enabled": isBiometricEnabled,
            "analytics_enabled": isAnalyticsEnabled,
            "crash_reporting_enabled": isCrashReportingEnabled,
            "data_retention_days": dataRetentionDays,
            "data_integrity_valid": validateDataIntegrity(),
            "last_cleanup": UserDefaults.standard.object(forKey: "last_data_cleanup") as? String ?? "Never"
        ]
        
        return report
    }
}
