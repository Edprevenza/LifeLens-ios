// HealthDataSyncService.swift - Simplified
import Foundation
import Combine

class HealthDataSyncService: ObservableObject {
    static let shared = HealthDataSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncProgress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func startSync() async {
        await MainActor.run {
            self.isSyncing = true
            self.syncProgress = 0.0
        }
        
        // Simulate sync
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            await MainActor.run {
                self.syncProgress = Double(i) / 10.0
            }
        }
        
        await MainActor.run {
            self.isSyncing = false
            self.lastSyncTime = Date()
            self.syncProgress = 1.0
        }
    }
    
    func stopSync() {
        isSyncing = false
    }
}
