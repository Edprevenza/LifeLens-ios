import Foundation
import Network
import Combine
import CryptoKit
import Compression

// MARK: - Sync Models
enum SyncPriority: Int, Comparable {
    case critical = 4
    case high = 3
    case normal = 2
    case low = 1
    
    static func < (lhs: SyncPriority, rhs: SyncPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

enum ConflictResolution {
    case clientWins
    case serverWins
    case latestWins
    case merge
}

struct SyncItem: Codable {
    let id: String
    let type: String
    let data: Data
    let timestamp: Date
    let priority: Int
    let userId: String
    let checksum: String
    var retryCount: Int = 0
    var lastAttempt: Date?
    
    var syncPriority: SyncPriority {
        return SyncPriority(rawValue: priority) ?? .normal
    }
}

struct SyncBatch: Codable {
    let batchId: String
    let items: [SyncItem]
    let timestamp: Date
    let compressed: Bool
    let encryption: String
}

struct SyncResponse: Codable {
    let success: Bool
    let syncedIds: [String]
    let conflicts: [SyncConflict]?
    let serverTimestamp: Date
    let nextSyncToken: String?
}

struct SyncConflict: Codable {
    let itemId: String
    let clientVersion: Data
    let serverVersion: Data
    let clientTimestamp: Date
    let serverTimestamp: Date
    let resolution: String
}

struct SyncStatus {
    var pending: Int
    var synced: Int
    var failed: Int
    var lastSync: Date?
    var isOnline: Bool
    let currentBatch: String?
}

// MARK: - DataSyncManager
class DataSyncManager: ObservableObject {
    static let shared = DataSyncManager()
    
    // Published properties
    @Published var syncStatus = SyncStatus(
        pending: 0,
        synced: 0,
        failed: 0,
        lastSync: nil,
        isOnline: true,
        currentBatch: nil
    )
    
    @Published var isSyncing = false
    @Published var networkState: NWPath.Status = .satisfied
    
    // Private properties
    private let syncQueue = DispatchQueue(label: "com.lifelens.sync", qos: .utility)
    private let priorityQueue = PriorityQueue<SyncItem>()
    private let fileManager = FileManager.default
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.lifelens.network")
    
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var activeSyncTasks = Set<String>()
    private let maxRetries = 3
    private let batchSize = 100
    private let syncInterval: TimeInterval = 300 // 5 minutes
    
    // Storage paths
    private var pendingItemsURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("SyncData/pending.json")
    }
    
    private var failedItemsURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("SyncData/failed.json")
    }
    
    // API Configuration
    private let baseURL = "https://api.lifelens.io/v1"
    private var authToken: String? {
        // TODO: KeychainManager.shared.getAuthToken()
        return nil
    }
    
    private init() {
        setupNetworkMonitoring()
        setupSyncTimer()
        loadPendingItems()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.networkState = path.status
                self?.syncStatus.isOnline = (path.status == .satisfied)
                
                if path.status == .satisfied {
                    self?.processPendingSync()
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Sync Timer
    private func setupSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            self?.performPeriodicSync()
        }
    }
    
    // MARK: - Data Queueing
    func queueData(_ data: Data, type: String, priority: SyncPriority = .normal) {
        let item = SyncItem(
            id: UUID().uuidString,
            type: type,
            data: data,
            timestamp: Date(),
            priority: priority.rawValue,
            userId: getUserId(),
            checksum: calculateChecksum(data)
        )
        
        // Add to priority queue
        priorityQueue.enqueue(item, priority: priority)
        
        // Save to persistent storage
        savePendingItem(item)
        
        // Update status
        DispatchQueue.main.async {
            self.syncStatus.pending += 1
        }
        
        // Process immediately if critical
        if priority == .critical && networkState == .satisfied {
            processCriticalItem(item)
        }
    }
    
    // MARK: - Critical Item Processing
    private func processCriticalItem(_ item: SyncItem) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let success = try self.syncSingleItem(item)
                if success {
                    self.removePendingItem(item.id)
                    DispatchQueue.main.async {
                        self.syncStatus.pending = max(0, self.syncStatus.pending - 1)
                        self.syncStatus.synced += 1
                    }
                }
            } catch {
                print("Failed to sync critical item: \(error)")
                self.handleSyncFailure(item, error: error)
            }
        }
    }
    
    // MARK: - Batch Processing
    func processPendingSync() {
        guard !isSyncing && networkState == .satisfied else { return }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        syncQueue.async { [weak self] in
            self?.processBatchSync()
        }
    }
    
    private func processBatchSync() {
        let items = priorityQueue.dequeueAll(limit: batchSize)
        guard !items.isEmpty else {
            DispatchQueue.main.async {
                self.isSyncing = false
            }
            return
        }
        
        let batch = SyncBatch(
            batchId: UUID().uuidString,
            items: items,
            timestamp: Date(),
            compressed: true,
            encryption: "AES-256-GCM"
        )
        
        do {
            let response = try syncBatch(batch)
            handleSyncResponse(response, batch: batch)
        } catch {
            print("Batch sync failed: \(error)")
            handleBatchFailure(batch, error: error)
        }
        
        DispatchQueue.main.async {
            self.isSyncing = false
        }
    }
    
    // MARK: - Network Operations
    private func syncSingleItem(_ item: SyncItem) throws -> Bool {
        guard let url = URL(string: "\(baseURL)/sync/item") else {
            throw SyncError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encrypted = try encryptData(item.data)
        let payload = [
            "id": item.id,
            "type": item.type,
            "data": encrypted.base64EncodedString(),
            "timestamp": ISO8601DateFormatter().string(from: item.timestamp),
            "checksum": item.checksum,
            "userId": item.userId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let semaphore = DispatchSemaphore(value: 0)
        var success = false
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                success = true
            }
            semaphore.signal()
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 30)
        return success
    }
    
    private func syncBatch(_ batch: SyncBatch) throws -> SyncResponse {
        guard let url = URL(string: "\(baseURL)/sync/batch") else {
            throw SyncError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Compress batch data
        let batchData = try JSONEncoder().encode(batch)
        let compressed = try compressData(batchData)
        
        request.httpBody = compressed
        request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        
        let semaphore = DispatchSemaphore(value: 0)
        var responseData: Data?
        var responseError: Error?
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            responseData = data
            responseError = error
            semaphore.signal()
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 60)
        
        if let error = responseError {
            throw error
        }
        
        guard let data = responseData else {
            throw SyncError.noData
        }
        
        return try JSONDecoder().decode(SyncResponse.self, from: data)
    }
    
    // MARK: - Conflict Resolution
    private func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) throws {
        switch resolution {
        case .clientWins:
            // Re-upload client version
            try uploadClientVersion(conflict)
            
        case .serverWins:
            // Accept server version
            try acceptServerVersion(conflict)
            
        case .latestWins:
            // Compare timestamps
            if conflict.clientTimestamp > conflict.serverTimestamp {
                try uploadClientVersion(conflict)
            } else {
                try acceptServerVersion(conflict)
            }
            
        case .merge:
            // Merge both versions
            let merged = try mergeVersions(conflict)
            try uploadMergedVersion(merged, conflictId: conflict.itemId)
        }
    }
    
    private func uploadClientVersion(_ conflict: SyncConflict) throws {
        guard let url = URL(string: "\(baseURL)/sync/resolve") else {
            throw SyncError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let payload = [
            "itemId": conflict.itemId,
            "resolution": "client_wins",
            "data": conflict.clientVersion.base64EncodedString()
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    private func acceptServerVersion(_ conflict: SyncConflict) throws {
        // Update local cache with server version
        updateLocalCache(itemId: conflict.itemId, data: conflict.serverVersion)
    }
    
    private func mergeVersions(_ conflict: SyncConflict) throws -> Data {
        // Implement domain-specific merge logic
        // For now, simple concatenation as placeholder
        var merged = Data()
        merged.append(conflict.clientVersion)
        merged.append(conflict.serverVersion)
        return merged
    }
    
    private func uploadMergedVersion(_ data: Data, conflictId: String) throws {
        guard let url = URL(string: "\(baseURL)/sync/merge") else {
            throw SyncError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let payload = [
            "itemId": conflictId,
            "resolution": "merge",
            "data": data.base64EncodedString()
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    // MARK: - Response Handling
    private func handleSyncResponse(_ response: SyncResponse, batch: SyncBatch) {
        // Update synced items
        for itemId in response.syncedIds {
            removePendingItem(itemId)
        }
        
        // Handle conflicts
        if let conflicts = response.conflicts {
            for conflict in conflicts {
                do {
                    try resolveConflict(conflict, resolution: .latestWins)
                } catch {
                    print("Failed to resolve conflict: \(error)")
                }
            }
        }
        
        // Update status
        DispatchQueue.main.async {
            self.syncStatus.pending = max(0, self.syncStatus.pending - response.syncedIds.count)
            self.syncStatus.synced += response.syncedIds.count
            self.syncStatus.lastSync = Date()
        }
        
        // Store sync token
        if let token = response.nextSyncToken {
            UserDefaults.standard.set(token, forKey: "syncToken")
        }
    }
    
    private func handleSyncFailure(_ item: SyncItem, error: Error) {
        var mutableItem = item
        mutableItem.retryCount += 1
        mutableItem.lastAttempt = Date()
        
        if mutableItem.retryCount < maxRetries {
            // Re-queue with exponential backoff
            let delay = pow(2.0, Double(mutableItem.retryCount))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.priorityQueue.enqueue(mutableItem, priority: mutableItem.syncPriority)
            }
        } else {
            // Move to failed items
            saveFailedItem(mutableItem)
            DispatchQueue.main.async {
                self.syncStatus.failed += 1
            }
        }
    }
    
    private func handleBatchFailure(_ batch: SyncBatch, error: Error) {
        // Re-queue all items in batch
        for item in batch.items {
            var mutableItem = item
            mutableItem.retryCount += 1
            priorityQueue.enqueue(mutableItem, priority: mutableItem.syncPriority)
        }
    }
    
    // MARK: - Persistence
    private func savePendingItem(_ item: SyncItem) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            var items = self.loadItemsFromFile(self.pendingItemsURL)
            items.append(item)
            self.saveItemsToFile(items, url: self.pendingItemsURL)
        }
    }
    
    private func removePendingItem(_ itemId: String) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            var items = self.loadItemsFromFile(self.pendingItemsURL)
            items.removeAll { $0.id == itemId }
            self.saveItemsToFile(items, url: self.pendingItemsURL)
        }
    }
    
    private func saveFailedItem(_ item: SyncItem) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            var items = self.loadItemsFromFile(self.failedItemsURL)
            items.append(item)
            self.saveItemsToFile(items, url: self.failedItemsURL)
        }
    }
    
    private func loadItemsFromFile(_ url: URL) -> [SyncItem] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([SyncItem].self, from: data)
        } catch {
            print("Failed to load items: \(error)")
            return []
        }
    }
    
    private func saveItemsToFile(_ items: [SyncItem], url: URL) {
        do {
            let directory = url.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            
            let data = try JSONEncoder().encode(items)
            try data.write(to: url)
        } catch {
            print("Failed to save items: \(error)")
        }
    }
    
    private func loadPendingItems() {
        let items = loadItemsFromFile(pendingItemsURL)
        for item in items {
            priorityQueue.enqueue(item, priority: item.syncPriority)
        }
        
        DispatchQueue.main.async {
            self.syncStatus.pending = items.count
        }
    }
    
    // MARK: - Utility Functions
    private func calculateChecksum(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func encryptData(_ data: Data) throws -> Data {
        // Use AES-256-GCM encryption
        let key = SymmetricKey(size: .bits256)
        let sealed = try AES.GCM.seal(data, using: key)
        return sealed.combined ?? Data()
    }
    
    private func compressData(_ data: Data) throws -> Data {
        return data.compressed(using: .lz4) ?? data
    }
    
    private func getUserId() -> String {
        return UserDefaults.standard.string(forKey: "userId") ?? "unknown"
    }
    
    private func updateLocalCache(itemId: String, data: Data) {
        // Update local cache/database with server version
        NotificationCenter.default.post(
            name: Notification.Name("SyncItemUpdated"),
            object: nil,
            userInfo: ["itemId": itemId, "data": data]
        )
    }
    
    // MARK: - Periodic Sync
    private func performPeriodicSync() {
        guard networkState == .satisfied && !isSyncing else { return }
        
        // Sync pending items
        processPendingSync()
        
        // Retry failed items
        retryFailedItems()
    }
    
    private func retryFailedItems() {
        let failedItems = loadItemsFromFile(failedItemsURL)
        for var item in failedItems {
            item.retryCount = 0 // Reset retry count
            priorityQueue.enqueue(item, priority: item.syncPriority)
        }
        
        // Clear failed items file
        saveItemsToFile([], url: failedItemsURL)
    }
    
    // MARK: - Public Methods
    func forceSyncNow() {
        processPendingSync()
    }
    
    func clearAllPendingData() {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.priorityQueue.clear()
            self.saveItemsToFile([], url: self.pendingItemsURL)
            self.saveItemsToFile([], url: self.failedItemsURL)
            
            DispatchQueue.main.async {
                self.syncStatus.pending = 0
                self.syncStatus.failed = 0
            }
        }
    }
    
    func getSyncStatistics() -> (pending: Int, synced: Int, failed: Int, lastSync: Date?) {
        return (syncStatus.pending, syncStatus.synced, syncStatus.failed, syncStatus.lastSync)
    }
}

// MARK: - Priority Queue Implementation
private class PriorityQueue<T: Codable> {
    private var heap: [(element: T, priority: SyncPriority)] = []
    private let queue = DispatchQueue(label: "com.lifelens.priorityqueue", attributes: .concurrent)
    
    func enqueue(_ element: T, priority: SyncPriority) {
        queue.async(flags: .barrier) {
            self.heap.append((element, priority))
            self.heap.sort { $0.priority > $1.priority }
        }
    }
    
    func dequeue() -> T? {
        queue.sync {
            return heap.isEmpty ? nil : heap.removeFirst().element
        }
    }
    
    func dequeueAll(limit: Int) -> [T] {
        queue.sync {
            let count = min(limit, heap.count)
            guard count > 0 else { return [] }
            
            let items = Array(heap.prefix(count).map { $0.element })
            heap.removeFirst(count)
            return items
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.heap.removeAll()
        }
    }
    
    var isEmpty: Bool {
        queue.sync { heap.isEmpty }
    }
}

// MARK: - KeychainManager Extension
// TODO: Implement KeychainManager
/* 
extension KeychainManager {
    func getAuthToken() -> String? {
        // Retrieve auth token from keychain
        return retrieve(key: "authToken")
    }
}
*/

// MARK: - Error Types
enum SyncError: Error {
    case invalidURL
    case noData
    case encryptionFailed
    case compressionFailed
    case authenticationFailed
    case networkUnavailable
}