//
//  ProgressiveDataService.swift
//  LifeLens
//
//  Progressive data loading with offline support
//

import SwiftUI
import Combine
import CoreData

// MARK: - Progressive Loading Manager (exported for validation)
class ProgressiveLoadingManager: ObservableObject {
    @Published var isLoadingInitial = true
    @Published var isLoadingMore = false
    @Published var hasMoreData = true
    
    private var currentPage = 0
    private let itemsPerPage = 20
    
    func loadInitialData<T>(fetchData: @escaping (Int, Int) async throws -> [T]) async -> [T] {
        isLoadingInitial = true
        
        do {
            let data = try await fetchData(0, itemsPerPage)
            await MainActor.run {
                self.isLoadingInitial = false
                self.currentPage = 0
                self.hasMoreData = data.count == itemsPerPage
            }
            return data
        } catch {
            await MainActor.run {
                self.isLoadingInitial = false
            }
            return []
        }
    }
    
    func loadMoreData<T>(fetchData: @escaping (Int, Int) async throws -> [T]) async -> [T] {
        guard hasMoreData && !isLoadingMore else { return [] }
        
        await MainActor.run {
            self.isLoadingMore = true
        }
        
        do {
            let nextPage = currentPage + 1
            let data = try await fetchData(nextPage * itemsPerPage, itemsPerPage)
            
            await MainActor.run {
                self.isLoadingMore = false
                self.currentPage = nextPage
                self.hasMoreData = data.count == itemsPerPage
            }
            
            return data
        } catch {
            await MainActor.run {
                self.isLoadingMore = false
            }
            return []
        }
    }
}

// MARK: - Progressive Data Service
class ProgressiveDataService: ObservableObject {
    static let shared = ProgressiveDataService()
    
    @Published var healthMetrics: [HealthMetric] = []
    @Published var isLoadingInitial = true
    @Published var isLoadingMore = false
    @Published var hasMoreData = true
    @Published var syncStatus: SyncStatus = .idle
    
    private var cancellables = Set<AnyCancellable>()
    private let cacheManager = OfflineCacheManager.shared
    private let apiService = APIService.shared
    private var currentPage = 0
    private let itemsPerPage = 20
    
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case failed(Error)
        
        static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.syncing, .syncing), (.synced, .synced):
                return true
            case (.failed(_), .failed(_)):
                return true
            default:
                return false
            }
        }
        
        var statusText: String {
            switch self {
            case .idle: return "Ready"
            case .syncing: return "Syncing..."
            case .synced: return "Synced"
            case .failed: return "Sync Failed"
            }
        }
        
        var statusColor: Color {
            switch self {
            case .idle: return .gray
            case .syncing: return .orange
            case .synced: return .green
            case .failed: return .red
            }
        }
    }
    
    private init() {
        setupNetworkMonitoring()
        loadCachedData()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        NetworkReachability.shared.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.syncWithServer()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadInitialData() async {
        await MainActor.run {
            isLoadingInitial = true
        }
        
        // First, load from cache for instant display
        if let cached = loadCachedData() {
            await MainActor.run {
                self.healthMetrics = cached
                self.isLoadingInitial = false
            }
        }
        
        // Then fetch fresh data if connected
        if NetworkReachability.shared.isConnected {
            await fetchFromServer(page: 0)
        }
        
        await MainActor.run {
            isLoadingInitial = false
        }
    }
    
    func loadMoreData() async {
        guard hasMoreData && !isLoadingMore else { return }
        
        await MainActor.run {
            isLoadingMore = true
        }
        
        let nextPage = currentPage + 1
        await fetchFromServer(page: nextPage)
        
        await MainActor.run {
            isLoadingMore = false
            currentPage = nextPage
        }
    }
    
    // MARK: - Server Sync
    private func fetchFromServer(page: Int) async {
        do {
            let response = try await apiService.fetchHealthMetrics(
                page: page,
                limit: itemsPerPage
            )
            
            await MainActor.run {
                if page == 0 {
                    self.healthMetrics = response.metrics
                } else {
                    self.healthMetrics.append(contentsOf: response.metrics)
                }
                
                self.hasMoreData = response.metrics.count == itemsPerPage
                self.syncStatus = .synced
                
                // Cache the data
                self.cacheData(self.healthMetrics)
            }
        } catch {
            await MainActor.run {
                self.syncStatus = .failed(error)
            }
        }
    }
    
    private func syncWithServer() {
        guard syncStatus != .syncing else { return }
        
        syncStatus = .syncing
        
        Task {
            // Upload any pending local changes
            await uploadPendingChanges()
            
            // Fetch latest data
            await fetchFromServer(page: 0)
        }
    }
    
    private func uploadPendingChanges() async {
        let pendingChanges = loadPendingChanges()
        
        for change in pendingChanges {
            do {
                try await apiService.uploadHealthMetric(change)
                removePendingChange(change.id)
            } catch {
                print("Failed to upload change: \(error)")
            }
        }
    }
    
    // MARK: - Caching
    private func loadCachedData() -> [HealthMetric]? {
        return cacheManager.retrieve([HealthMetric].self, forKey: "health_metrics")
    }
    
    private func cacheData(_ metrics: [HealthMetric]) {
        cacheManager.cache(metrics, forKey: "health_metrics")
    }
    
    private func loadPendingChanges() -> [HealthMetric] {
        return cacheManager.retrieve([HealthMetric].self, forKey: "pending_changes") ?? []
    }
    
    private func savePendingChange(_ metric: HealthMetric) {
        var pending = loadPendingChanges()
        pending.append(metric)
        cacheManager.cache(pending, forKey: "pending_changes")
    }
    
    private func removePendingChange(_ id: String) {
        var pending = loadPendingChanges()
        pending.removeAll { $0.id == id }
        cacheManager.cache(pending, forKey: "pending_changes")
    }
    
    // MARK: - Offline Operations
    func saveMetricOffline(_ metric: HealthMetric) {
        // Save to local storage
        healthMetrics.append(metric)
        cacheData(healthMetrics)
        
        // Queue for sync
        savePendingChange(metric)
        
        // Attempt sync if connected
        if NetworkReachability.shared.isConnected {
            syncWithServer()
        }
    }
}

// MARK: - Health Metric Model
struct HealthMetric: Codable, Identifiable {
    let id: String
    let type: MetricType
    let value: Double
    let unit: String
    let timestamp: Date
    let deviceId: String?
    let notes: String?
    
    enum MetricType: String, Codable, CaseIterable {
        case heartRate = "heart_rate"
        case bloodPressureSystolic = "bp_systolic"
        case bloodPressureDiastolic = "bp_diastolic"
        case glucose = "glucose"
        case spo2 = "spo2"
        case temperature = "temperature"
        case weight = "weight"
        case steps = "steps"
        
        var displayName: String {
            switch self {
            case .heartRate: return "Heart Rate"
            case .bloodPressureSystolic: return "Systolic BP"
            case .bloodPressureDiastolic: return "Diastolic BP"
            case .glucose: return "Glucose"
            case .spo2: return "SpO2"
            case .temperature: return "Temperature"
            case .weight: return "Weight"
            case .steps: return "Steps"
            }
        }
        
        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .bloodPressureSystolic, .bloodPressureDiastolic: return "waveform.path.ecg"
            case .glucose: return "drop.fill"
            case .spo2: return "lungs.fill"
            case .temperature: return "thermometer"
            case .weight: return "scalemass.fill"
            case .steps: return "figure.walk"
            }
        }
        
        var color: Color {
            switch self {
            case .heartRate: return .red
            case .bloodPressureSystolic, .bloodPressureDiastolic: return .pink
            case .glucose: return .purple
            case .spo2: return .blue
            case .temperature: return .orange
            case .weight: return .green
            case .steps: return .cyan
            }
        }
        
        var normalRange: ClosedRange<Double> {
            switch self {
            case .heartRate: return 60...100
            case .bloodPressureSystolic: return 90...120
            case .bloodPressureDiastolic: return 60...80
            case .glucose: return 70...140
            case .spo2: return 95...100
            case .temperature: return 97...99
            case .weight: return 0...500
            case .steps: return 0...50000
            }
        }
    }
}

// MARK: - Image Cache Service
class ImageCacheService {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure cache limits
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }
    
    func loadImage(from url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString
        
        // Check memory cache
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        // Check disk cache
        let diskPath = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        if let diskImage = UIImage(contentsOfFile: diskPath.path) {
            cache.setObject(diskImage, forKey: key)
            return diskImage
        }
        
        // Download image
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let image = UIImage(data: data) {
                // Save to memory cache
                cache.setObject(image, forKey: key)
                
                // Save to disk cache
                try? data.write(to: diskPath)
                
                return image
            }
        } catch {
            print("Failed to load image: \(error)")
        }
        
        return nil
    }
    
    func preloadImages(urls: [URL]) {
        Task {
            for url in urls {
                _ = await loadImage(from: url)
            }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

// MARK: - Progressive List View
struct ProgressiveListView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let isLoadingMore: Bool
    let hasMoreData: Bool
    let onLoadMore: () async -> Void
    let content: (Item) -> Content
    
    @State private var visibleItems: Set<Item.ID> = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: ResponsiveDimensions.spacing()) {
                ForEach(items) { item in
                    content(item)
                        .onAppear {
                            visibleItems.insert(item.id)
                            
                            // Load more when approaching the end
                            if item.id == items.suffix(3).first?.id && hasMoreData && !isLoadingMore {
                                Task {
                                    await onLoadMore()
                                }
                            }
                        }
                        .onDisappear {
                            visibleItems.remove(item.id)
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 1.1).combined(with: .opacity)
                        ))
                }
                
                if isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                    .padding()
                }
                
                if !hasMoreData && !items.isEmpty {
                    Text("No more data")
                        .font(.caption)
                        
            .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Sync Status View
struct SyncStatusView: View {
    @ObservedObject var dataService = ProgressiveDataService.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(dataService.syncStatus.statusColor)
                .frame(width: 8, height: 8)
            
            Text(dataService.syncStatus.statusText)
                .font(.caption)
                
            .foregroundColor(.secondary)
            
            if case .syncing = dataService.syncStatus {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
    }
}