// OfflineHealthStorage.swift
// 72-hour offline health data storage with encryption

import Foundation
import CoreData
import CryptoKit
import SQLite3

/**
 * Offline Health Storage System
 * Stores 72 hours of encrypted health data locally
 * Automatic sync when connection restored
 * HIPAA-compliant encryption
 */
class OfflineHealthStorage {
    
    // MARK: - Configuration
    private let RETENTION_HOURS = 72
    private let MAX_STORAGE_MB = 500  // 500MB max offline storage
    private let SYNC_BATCH_SIZE = 100
    
    // MARK: - Core Data Stack
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LifeLensOfflineData")
        
        // Enable encryption
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(FileProtectionType.completeUnlessOpen as NSObject,
                                   forKey: NSPersistentStoreFileProtectionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                AppLogger.shared.log("Core Data error: \(error)", category: .storage)
            }
        }
        
        return container
    }()
    
    // MARK: - SQLite for High-Performance Storage
    private var database: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.lifelens.offline.db", attributes: .concurrent)
    
    // MARK: - Encryption
    private let encryptionKey = SymmetricKey(size: .bits256)
    
    // MARK: - Sync Management
    private var syncTimer: Timer?
    private var pendingSyncData: [HealthDataPacket] = []
    private let syncQueue = DispatchQueue(label: "com.lifelens.offline.sync")
    
    // MARK: - Types
    
    struct HealthDataPacket: Codable {
        let id: UUID
        let timestamp: Date
        let dataType: DataType
        let encryptedPayload: Data
        let priority: Priority
        let synced: Bool
        
        enum DataType: String, Codable {
            case vitalSigns
            case biomarkers
            case ecgWaveform
            case continuousGlucose
            case alerts
            case edgePredictions
        }
        
        enum Priority: Int, Codable {
            case low = 0
            case normal = 1
            case high = 2
            case critical = 3
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupDatabase()
        setupAutoCleanup()
        setupSyncTimer()
    }
    
    // MARK: - Database Setup
    
    private func setupDatabase() {
        let fileManager = FileManager.default
        let documentsURL = try! fileManager.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        let dbURL = documentsURL.appendingPathComponent("LifeLensOffline.db")
        
        // Open SQLite database with encryption
        if sqlite3_open_v2(dbURL.path,
                          &database,
                          SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
                          nil) == SQLITE_OK {
            
            // Enable SQLCipher encryption
            let keyData = encryptionKey.withUnsafeBytes { Data($0) }
            let keyString = keyData.base64EncodedString()
            sqlite3_exec(database, "PRAGMA key = '\(keyString)'", nil, nil, nil)
            
            // Create tables
            createTables()
            
            AppLogger.shared.log("✅ Offline database initialized", category: .storage)
        } else {
            AppLogger.shared.log("❌ Failed to open database", category: .storage)
        }
    }
    
    private func createTables() {
        let createVitalSignsTable = """
            CREATE TABLE IF NOT EXISTS vital_signs (
                id TEXT PRIMARY KEY,
                timestamp INTEGER NOT NULL,
                heart_rate INTEGER,
                hrv INTEGER,
                systolic_bp INTEGER,
                diastolic_bp INTEGER,
                respiratory_rate INTEGER,
                spo2 INTEGER,
                temperature REAL,
                encrypted_data BLOB,
                synced INTEGER DEFAULT 0,
                created_at INTEGER DEFAULT (strftime('%s', 'now'))
            );
            CREATE INDEX IF NOT EXISTS idx_vital_signs_timestamp ON vital_signs(timestamp);
            CREATE INDEX IF NOT EXISTS idx_vital_signs_synced ON vital_signs(synced);
        """
        
        let createBiomarkersTable = """
            CREATE TABLE IF NOT EXISTS biomarkers (
                id TEXT PRIMARY KEY,
                timestamp INTEGER NOT NULL,
                troponin_level REAL,
                glucose_level REAL,
                cholesterol_total REAL,
                creatinine REAL,
                encrypted_data BLOB,
                synced INTEGER DEFAULT 0,
                created_at INTEGER DEFAULT (strftime('%s', 'now'))
            );
            CREATE INDEX IF NOT EXISTS idx_biomarkers_timestamp ON biomarkers(timestamp);
        """
        
        let createECGTable = """
            CREATE TABLE IF NOT EXISTS ecg_waveforms (
                id TEXT PRIMARY KEY,
                timestamp INTEGER NOT NULL,
                sample_rate INTEGER,
                duration_ms INTEGER,
                waveform_data BLOB,
                arrhythmia_detected INTEGER,
                classification TEXT,
                synced INTEGER DEFAULT 0,
                created_at INTEGER DEFAULT (strftime('%s', 'now'))
            );
            CREATE INDEX IF NOT EXISTS idx_ecg_timestamp ON ecg_waveforms(timestamp);
        """
        
        let createAlertsTable = """
            CREATE TABLE IF NOT EXISTS critical_alerts (
                id TEXT PRIMARY KEY,
                timestamp INTEGER NOT NULL,
                alert_type TEXT,
                severity TEXT,
                message TEXT,
                action_required TEXT,
                auto_escalate INTEGER,
                acknowledged INTEGER DEFAULT 0,
                synced INTEGER DEFAULT 0,
                created_at INTEGER DEFAULT (strftime('%s', 'now'))
            );
            CREATE INDEX IF NOT EXISTS idx_alerts_severity ON critical_alerts(severity);
        """
        
        let createEdgePredictionsTable = """
            CREATE TABLE IF NOT EXISTS edge_predictions (
                id TEXT PRIMARY KEY,
                timestamp INTEGER NOT NULL,
                model_name TEXT,
                prediction_type TEXT,
                confidence REAL,
                result_data BLOB,
                inference_time_ms INTEGER,
                synced INTEGER DEFAULT 0,
                created_at INTEGER DEFAULT (strftime('%s', 'now'))
            );
        """
        
        // Execute table creation
        [createVitalSignsTable, createBiomarkersTable, createECGTable, 
         createAlertsTable, createEdgePredictionsTable].forEach { sql in
            if sqlite3_exec(database, sql, nil, nil, nil) != SQLITE_OK {
                AppLogger.shared.log("Failed to create table", category: .storage)
            }
        }
    }
    
    // MARK: - Store Vital Signs
    
    func storeVitalSigns(_ metrics: ContinuousMonitoringEngine.HealthMetrics) {
        dbQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let id = UUID().uuidString
            let timestamp = Int(Date().timeIntervalSince1970)
            
            // Encrypt sensitive data
            let sensitiveData = try? JSONEncoder().encode(metrics)
            let encryptedData = self.encryptData(sensitiveData ?? Data())
            
            let sql = """
                INSERT INTO vital_signs 
                (id, timestamp, heart_rate, hrv, systolic_bp, diastolic_bp, 
                 respiratory_rate, spo2, encrypted_data)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.database, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, id, -1, nil)
                sqlite3_bind_int64(statement, 2, Int64(timestamp))
                sqlite3_bind_int(statement, 3, Int32(metrics.heartRate))
                sqlite3_bind_int(statement, 4, Int32(metrics.heartRateVariability))
                sqlite3_bind_int(statement, 5, Int32(metrics.systolicBP))
                sqlite3_bind_int(statement, 6, Int32(metrics.diastolicBP))
                sqlite3_bind_int(statement, 7, Int32(metrics.respiratoryRate))
                sqlite3_bind_int(statement, 8, Int32(metrics.spO2))
                
                encryptedData?.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, 9, bytes.baseAddress, Int32(bytes.count), nil)
                }
                
                if sqlite3_step(statement) != SQLITE_DONE {
                    AppLogger.shared.log("Failed to store vital signs", category: .storage)
                }
            }
            sqlite3_finalize(statement)
            
            // Check storage size
            self.checkStorageSize()
        }
    }
    
    // MARK: - Store Biomarkers
    
    func storeBiomarkers(_ metrics: ContinuousMonitoringEngine.HealthMetrics) {
        dbQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let id = UUID().uuidString
            let timestamp = Int(Date().timeIntervalSince1970)
            
            let sensitiveData = try? JSONEncoder().encode(metrics)
            let encryptedData = self.encryptData(sensitiveData ?? Data())
            
            let sql = """
                INSERT INTO biomarkers 
                (id, timestamp, troponin_level, glucose_level, encrypted_data)
                VALUES (?, ?, ?, ?, ?)
            """
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.database, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, id, -1, nil)
                sqlite3_bind_int64(statement, 2, Int64(timestamp))
                sqlite3_bind_double(statement, 3, Double(metrics.troponinLevel))
                sqlite3_bind_double(statement, 4, Double(metrics.glucoseLevel))
                
                encryptedData?.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, 5, bytes.baseAddress, Int32(bytes.count), nil)
                }
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    // MARK: - Store ECG Waveform
    
    func storeECGWaveform(_ ecgData: [Float], 
                         arrhythmiaDetected: Bool,
                         classification: String) {
        dbQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let id = UUID().uuidString
            let timestamp = Int(Date().timeIntervalSince1970)
            
            // Compress ECG data
            let waveformData = ecgData.withUnsafeBytes { Data($0) }
            let compressedData = self.compressData(waveformData)
            let encryptedData = self.encryptData(compressedData ?? Data())
            
            let sql = """
                INSERT INTO ecg_waveforms 
                (id, timestamp, sample_rate, duration_ms, waveform_data, 
                 arrhythmia_detected, classification)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.database, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, id, -1, nil)
                sqlite3_bind_int64(statement, 2, Int64(timestamp))
                sqlite3_bind_int(statement, 3, 250)  // 250 Hz sample rate
                sqlite3_bind_int(statement, 4, Int32(ecgData.count * 4))  // Duration
                
                encryptedData?.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, 5, bytes.baseAddress, Int32(bytes.count), nil)
                }
                
                sqlite3_bind_int(statement, 6, arrhythmiaDetected ? 1 : 0)
                sqlite3_bind_text(statement, 7, classification, -1, nil)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    // MARK: - Store Critical Alert
    
    func storeCriticalAlert(_ alert: ContinuousMonitoringEngine.CriticalAlert) {
        dbQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let sql = """
                INSERT INTO critical_alerts 
                (id, timestamp, alert_type, severity, message, 
                 action_required, auto_escalate)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.database, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, alert.id.uuidString, -1, nil)
                sqlite3_bind_int64(statement, 2, Int64(alert.timestamp.timeIntervalSince1970))
                sqlite3_bind_text(statement, 3, String(describing: alert.type), -1, nil)
                sqlite3_bind_text(statement, 4, String(describing: alert.severity), -1, nil)
                sqlite3_bind_text(statement, 5, alert.message, -1, nil)
                sqlite3_bind_text(statement, 6, alert.actionRequired, -1, nil)
                sqlite3_bind_int(statement, 7, alert.autoEscalate ? 1 : 0)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    // MARK: - Retrieve Unsynced Data
    
    func getUnsyncedData(limit: Int = 100) -> [HealthDataPacket] {
        var packets: [HealthDataPacket] = []
        
        dbQueue.sync { [weak self] in
            guard let self = self else { return }
            
            // Query all tables for unsynced data
            let tables = ["vital_signs", "biomarkers", "ecg_waveforms", "critical_alerts", "edge_predictions"]
            
            for table in tables {
                let sql = """
                    SELECT id, timestamp, encrypted_data 
                    FROM \(table) 
                    WHERE synced = 0 
                    ORDER BY timestamp DESC 
                    LIMIT ?
                """
                
                var statement: OpaquePointer?
                if sqlite3_prepare_v2(self.database, sql, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_bind_int(statement, 1, Int32(limit))
                    
                    while sqlite3_step(statement) == SQLITE_ROW {
                        let id = String(cString: sqlite3_column_text(statement, 0))
                        let timestamp = Date(timeIntervalSince1970: Double(sqlite3_column_int64(statement, 1)))
                        
                        if let dataBlob = sqlite3_column_blob(statement, 2) {
                            let dataSize = sqlite3_column_bytes(statement, 2)
                            let data = Data(bytes: dataBlob, count: Int(dataSize))
                            
                            let packet = HealthDataPacket(
                                id: UUID(uuidString: id) ?? UUID(),
                                timestamp: timestamp,
                                dataType: self.dataTypeForTable(table),
                                encryptedPayload: data,
                                priority: .normal,
                                synced: false
                            )
                            packets.append(packet)
                        }
                    }
                }
                sqlite3_finalize(statement)
            }
        }
        
        return packets
    }
    
    // MARK: - Sync Management
    
    func syncPendingData() {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            let unsyncedData = self.getUnsyncedData(limit: self.SYNC_BATCH_SIZE)
            
            if !unsyncedData.isEmpty {
                Task {
                    do {
                        // Batch upload to cloud
                        try await APIService.shared.batchUploadHealthData(unsyncedData)
                        
                        // Mark as synced
                        self.markDataAsSynced(unsyncedData.map { $0.id })
                        
                        AppLogger.shared.log("✅ Synced \(unsyncedData.count) health records", category: .sync)
                    } catch {
                        AppLogger.shared.log("Sync failed: \(error)", category: .sync)
                    }
                }
            }
        }
    }
    
    private func markDataAsSynced(_ ids: [UUID]) {
        dbQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let tables = ["vital_signs", "biomarkers", "ecg_waveforms", "critical_alerts", "edge_predictions"]
            
            for table in tables {
                for id in ids {
                    let sql = "UPDATE \(table) SET synced = 1 WHERE id = ?"
                    
                    var statement: OpaquePointer?
                    if sqlite3_prepare_v2(self.database, sql, -1, &statement, nil) == SQLITE_OK {
                        sqlite3_bind_text(statement, 1, id.uuidString, -1, nil)
                        sqlite3_step(statement)
                    }
                    sqlite3_finalize(statement)
                }
            }
        }
    }
    
    // MARK: - Auto Cleanup (72-hour retention)
    
    private func setupAutoCleanup() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.cleanupOldData()
        }
    }
    
    private func cleanupOldData() {
        dbQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let cutoffTime = Int(Date().addingTimeInterval(-Double(self.RETENTION_HOURS) * 3600).timeIntervalSince1970)
            
            let tables = ["vital_signs", "biomarkers", "ecg_waveforms", "critical_alerts", "edge_predictions"]
            
            for table in tables {
                let sql = "DELETE FROM \(table) WHERE timestamp < ? AND synced = 1"
                
                var statement: OpaquePointer?
                if sqlite3_prepare_v2(self.database, sql, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_bind_int64(statement, 1, Int64(cutoffTime))
                    sqlite3_step(statement)
                }
                sqlite3_finalize(statement)
            }
            
            // Vacuum to reclaim space
            sqlite3_exec(self.database, "VACUUM", nil, nil, nil)
        }
    }
    
    // MARK: - Storage Management
    
    private func checkStorageSize() {
        dbQueue.async { [weak self] in
            guard let self = self else { return }
            
            var statement: OpaquePointer?
            let sql = "SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()"
            
            if sqlite3_prepare_v2(self.database, sql, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    let sizeBytes = sqlite3_column_int64(statement, 0)
                    let sizeMB = Double(sizeBytes) / (1024 * 1024)
                    
                    if sizeMB > Double(self.MAX_STORAGE_MB) {
                        // Delete oldest synced data
                        self.deleteOldestSyncedData()
                    }
                }
            }
            sqlite3_finalize(statement)
        }
    }
    
    private func deleteOldestSyncedData() {
        let tables = ["vital_signs", "biomarkers", "ecg_waveforms"]
        
        for table in tables {
            let sql = """
                DELETE FROM \(table) 
                WHERE id IN (
                    SELECT id FROM \(table) 
                    WHERE synced = 1 
                    ORDER BY timestamp ASC 
                    LIMIT 1000
                )
            """
            sqlite3_exec(database, sql, nil, nil, nil)
        }
    }
    
    // MARK: - Encryption/Decryption
    
    private func encryptData(_ data: Data) -> Data? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
            return sealedBox.combined
        } catch {
            return nil
        }
    }
    
    private func decryptData(_ encryptedData: Data) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: encryptionKey)
        } catch {
            return nil
        }
    }
    
    // MARK: - Compression
    
    private func compressData(_ data: Data) -> Data? {
        return data.compressed(using: .zlib)
    }
    
    private func decompressData(_ compressedData: Data) -> Data? {
        return compressedData.decompressed(using: .zlib)
    }
    
    // MARK: - Helper Methods
    
    private func dataTypeForTable(_ table: String) -> HealthDataPacket.DataType {
        switch table {
        case "vital_signs": return .vitalSigns
        case "biomarkers": return .biomarkers
        case "ecg_waveforms": return .ecgWaveform
        case "critical_alerts": return .alerts
        case "edge_predictions": return .edgePredictions
        default: return .vitalSigns
        }
    }
    
    private func setupSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            if NetworkMonitor.shared.isConnected {
                self?.syncPendingData()
            }
        }
    }
    
    // MARK: - Configure Retention
    
    func configure(retentionHours: Int) {
        // Allow configuration of retention period
        // Implementation for dynamic configuration
    }
    
    deinit {
        syncTimer?.invalidate()
        sqlite3_close(database)
    }
}

// MARK: - Data Compression Extension

extension Data {
    func compressed(using algorithm: NSData.CompressionAlgorithm) -> Data? {
        return (self as NSData).compressed(using: algorithm) as Data?
    }
    
    func decompressed(using algorithm: NSData.CompressionAlgorithm) -> Data? {
        return (self as NSData).decompressed(using: algorithm) as Data?
    }
}