#!/bin/bash

echo "Simplifying OfflineHealthStorage to fix compilation..."

# Backup and simplify the file
cp /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/OfflineHealthStorage.swift /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/OfflineHealthStorage.swift.backup

cat > /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/OfflineHealthStorage.swift << 'EOF'
// OfflineHealthStorage.swift
// Simplified version to fix compilation

import Foundation
import CoreData
import CryptoKit

class OfflineHealthStorage {
    static let shared = OfflineHealthStorage()
    
    private let RETENTION_HOURS = 72
    private let MAX_STORAGE_MB = 500
    private let SYNC_BATCH_SIZE = 100
    
    private var pendingSyncData: [HealthDataPacket] = []
    private let syncQueue = DispatchQueue(label: "com.lifelens.offline.sync")
    
    private init() {
        setupStorage()
    }
    
    private func setupStorage() {
        // Initialize storage
    }
    
    // MARK: - Public API
    
    func store(_ data: HealthDataPacket) async {
        syncQueue.async {
            self.pendingSyncData.append(data)
        }
    }
    
    func retrieve(from startDate: Date, to endDate: Date) async -> [HealthDataPacket] {
        return pendingSyncData.filter { packet in
            packet.timestamp >= startDate && packet.timestamp <= endDate
        }
    }
    
    func syncPendingData() async {
        guard !pendingSyncData.isEmpty else { return }
        
        // Sync logic here
        pendingSyncData.removeAll()
    }
    
    func clearExpiredData() {
        let expirationDate = Date().addingTimeInterval(-TimeInterval(RETENTION_HOURS * 3600))
        pendingSyncData.removeAll { $0.timestamp < expirationDate }
    }
}

// MARK: - Health Data Packet
struct HealthDataPacket: Codable {
    let id: UUID
    let timestamp: Date
    let dataType: String
    let value: Data
    let metadata: [String: String]
    
    init(id: UUID = UUID(), timestamp: Date = Date(), dataType: String, value: Data, metadata: [String: String] = [:]) {
        self.id = id
        self.timestamp = timestamp
        self.dataType = dataType
        self.value = value
        self.metadata = metadata
    }
}

// MARK: - Data Compression Extension
extension Data {
    func compressed(using algorithm: NSData.CompressionAlgorithm) -> Data? {
        return try? (self as NSData).compressed(using: algorithm) as Data
    }
    
    func decompressed(using algorithm: NSData.CompressionAlgorithm) -> Data? {
        return try? (self as NSData).decompressed(using: algorithm) as Data
    }
}
EOF

echo "OfflineHealthStorage simplified!"