//
//  HealthDashboardView.swift
//  LifeLens
//
//  Main health monitoring dashboard with real-time charts
//

import SwiftUI
import Combine

// MARK: - View Model

class HealthDashboardViewModel: ObservableObject {
    @Published var bloodPressureData: [ChartDataPoint] = []
    @Published var heartRateData: [ChartDataPoint] = []
    @Published var glucoseData: [ChartDataPoint] = []
    @Published var spo2Data: [ChartDataPoint] = []
    @Published var troponinData: [ChartDataPoint] = []
    @Published var ecgSamples: [Double] = []
    
    @Published var currentAlerts: [HealthAlert] = []
    @Published var isLoading = false
    @Published var lastUpdated = Date()
    @Published var connectionStatus: String = "Disconnected"
    
    @Published var currentBP: (systolic: Int, diastolic: Int) = (120, 80)
    @Published var currentHeartRate: Int = 75
    @Published var currentGlucose: Double = 95
    @Published var currentSpO2: Int = 98
    @Published var currentTroponin: (i: Double, t: Double) = (0.01, 0.005)
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private let bluetoothManager = BluetoothManager.shared
    private let apiService = APIService.shared
    
    init() {
        setupSubscriptions()
        startDataRefresh()
        generateMockData() // Remove this in production
    }
    
    private func setupSubscriptions() {
        // Subscribe to Bluetooth data updates
        bluetoothManager.$connectedDevice
            .sink { [weak self] device in
                self?.connectionStatus = device != nil ? "Connected" : "Disconnected"
            }
            .store(in: &cancellables)
        
        bluetoothManager.$latestECGData
            .compactMap { $0 }
            .sink { [weak self] ecgData in
                self?.updateECGData(ecgData)
            }
            .store(in: &cancellables)
        
        bluetoothManager.$latestBloodPressureData
            .compactMap { $0 }
            .sink { [weak self] bpData in
                self?.updateBloodPressureData(bpData)
            }
            .store(in: &cancellables)
        
        bluetoothManager.$latestGlucoseData
            .compactMap { $0 }
            .sink { [weak self] glucoseData in
                self?.updateGlucoseData(glucoseData)
            }
            .store(in: &cancellables)
        
        bluetoothManager.$latestSpO2Data
            .compactMap { $0 }
            .sink { [weak self] spo2Data in
                self?.updateSpO2Data(spo2Data)
            }
            .store(in: &cancellables)
        
        bluetoothManager.$latestTroponinData
            .compactMap { $0 }
            .sink { [weak self] troponinData in
                self?.updateTroponinData(troponinData)
            }
            .store(in: &cancellables)
        
        bluetoothManager.$currentAlerts
            .sink { [weak self] alerts in
                self?.currentAlerts = alerts
            }
            .store(in: &cancellables)
    }
    
    private func startDataRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshData()
        }
    }
    
    func refreshData() {
        lastUpdated = Date()
        fetchAlertsFromAPI()
    }
    
    private func fetchAlertsFromAPI() {
        apiService.fetchAlerts()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to fetch alerts: \(error)")
                    }
                },
                receiveValue: { [weak self] alerts in
                    self?.currentAlerts = alerts
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Data Updates
    
    private func updateECGData(_ data: ECGData) {
        ecgSamples = Array(data.samples.prefix(2500)) // 5 seconds at 500Hz
        currentHeartRate = data.heartRate
        
        let point = ChartDataPoint(
            timestamp: data.timestamp,
            value: Double(data.heartRate)
        )
        heartRateData.append(point)
        heartRateData = Array(heartRateData.suffix(100)) // Keep last 100 points
    }
    
    private func updateBloodPressureData(_ data: BloodPressureData) {
        currentBP = (data.systolic, data.diastolic)
        
        let point = ChartDataPoint(
            timestamp: data.timestamp,
            value: Double(data.systolic),
            label: "\(data.systolic)/\(data.diastolic)"
        )
        bloodPressureData.append(point)
        bloodPressureData = Array(bloodPressureData.suffix(50))
    }
    
    private func updateGlucoseData(_ data: GlucoseData) {
        currentGlucose = data.glucoseLevel
        
        let point = ChartDataPoint(
            timestamp: data.timestamp,
            value: data.glucoseLevel
        )
        glucoseData.append(point)
        glucoseData = Array(glucoseData.suffix(50))
    }
    
    private func updateSpO2Data(_ data: SpO2Data) {
        currentSpO2 = data.oxygenSaturation
        
        let point = ChartDataPoint(
            timestamp: data.timestamp,
            value: Double(data.oxygenSaturation)
        )
        spo2Data.append(point)
        spo2Data = Array(spo2Data.suffix(100))
    }
    
    private func updateTroponinData(_ data: TroponinData) {
        currentTroponin = (data.troponinI, data.troponinT)
        
        let point = ChartDataPoint(
            timestamp: data.timestamp,
            value: data.troponinI,
            label: "Troponin I"
        )
        troponinData.append(point)
        troponinData = Array(troponinData.suffix(24)) // Keep 24 hours of data
    }
    
    // MARK: - Mock Data (Remove in production)
    
    private func generateMockData() {
        let now = Date()
        
        // Generate blood pressure data
        for i in 0..<24 {
            let timestamp = now.addingTimeInterval(Double(i - 24) * 3600)
            let systolic = Double.random(in: 110...130)
            bloodPressureData.append(ChartDataPoint(timestamp: timestamp, value: systolic))
        }
        
        // Generate heart rate data
        for i in 0..<50 {
            let timestamp = now.addingTimeInterval(Double(i - 50) * 60)
            let hr = Double.random(in: 65...85)
            heartRateData.append(ChartDataPoint(timestamp: timestamp, value: hr))
        }
        
        // Generate glucose data
        for i in 0..<30 {
            let timestamp = now.addingTimeInterval(Double(i - 30) * 600)
            let glucose = Double.random(in: 85...105)
            glucoseData.append(ChartDataPoint(timestamp: timestamp, value: glucose))
        }
        
        // Generate SpO2 data
        for i in 0..<50 {
            let timestamp = now.addingTimeInterval(Double(i - 50) * 60)
            let spo2 = Double.random(in: 96...99)
            spo2Data.append(ChartDataPoint(timestamp: timestamp, value: spo2))
        }
        
        // Generate ECG samples
        for i in 0..<2500 {
            let t = Double(i) / 500.0
            let value = sin(2 * .pi * 1.2 * t) * 0.5 + Double.random(in: -0.1...0.1)
            ecgSamples.append(value)
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - Main Dashboard View

struct HealthDashboardView: View {
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var selectedTab = 0
    @State private var showingAlerts = false
    @State private var selectedMetric: String? = nil
    @State private var appearAnimation = false
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Gradient Background
                    LinearGradient(
                        colors: [Color.blue.opacity(0.05), 
                                 Color.purple.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: adaptiveSpacing(for: geometry.size)) {
                        // Compact Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome Back")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Health Dashboard")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            // Connection Status
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(viewModel.connectionStatus == "Connected" ? Color.green : Color.gray)
                                    .frame(width: 8, height: 8)
                                    .overlay(
                                        Circle()
                                            .stroke(viewModel.connectionStatus == "Connected" ? Color.green.opacity(0.5) : Color.clear, lineWidth: 8)
                                            .scaleEffect(appearAnimation ? 2 : 1)
                                            .opacity(appearAnimation ? 0 : 1)
                                            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: appearAnimation)
                                    )
                                Text(viewModel.connectionStatus)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                        .padding(.horizontal, adaptivePadding(for: geometry.size))
                        .padding(.top, 10)
                        
                        // Alert Banner at top if needed
                        if !viewModel.currentAlerts.isEmpty {
                            EnhancedAlertBanner(alerts: viewModel.currentAlerts)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        showingAlerts = true
                                    }
                                }
                                .padding(.horizontal, adaptivePadding(for: geometry.size))
                        }
                        
                        // Adaptive Stats Grid
                        LazyVGrid(columns: adaptiveGridColumns(for: geometry.size), spacing: adaptiveSpacing(for: geometry.size)) {
                            ModernStatCard(
                                title: "Heart Rate",
                                value: "\(viewModel.currentHeartRate)",
                                unit: "BPM",
                                icon: "heart.fill",
                                color: .pink,
                                trend: getTrend(for: viewModel.heartRateData),
                                sparklineData: viewModel.heartRateData.suffix(20).map { $0.value },
                                isSelected: selectedMetric == "heartRate",
                                onTap: { selectedMetric = selectedMetric == "heartRate" ? nil : "heartRate" }
                            )
                                                        
                            ModernStatCard(
                                title: "Blood Pressure",
                                value: "\(viewModel.currentBP.systolic)/\(viewModel.currentBP.diastolic)",
                                unit: "mmHg",
                                icon: "waveform.path.ecg",
                                color: .red,
                                trend: getTrend(for: viewModel.bloodPressureData),
                                sparklineData: viewModel.bloodPressureData.suffix(20).map { $0.value },
                                isSelected: selectedMetric == "bloodPressure",
                                onTap: { selectedMetric = selectedMetric == "bloodPressure" ? nil : "bloodPressure" }
                            )
                                                        
                            ModernStatCard(
                                title: "Glucose",
                                value: String(format: "%.0f", viewModel.currentGlucose),
                                unit: "mg/dL",
                                icon: "drop.fill",
                                color: .purple,
                                trend: getTrend(for: viewModel.glucoseData),
                                sparklineData: viewModel.glucoseData.suffix(20).map { $0.value },
                                isSelected: selectedMetric == "glucose",
                                onTap: { selectedMetric = selectedMetric == "glucose" ? nil : "glucose" }
                            )
                                                        
                            ModernStatCard(
                                title: "SpO2",
                                value: "\(viewModel.currentSpO2)",
                                unit: "%",
                                icon: "lungs.fill",
                                color: .blue,
                                trend: getTrend(for: viewModel.spo2Data),
                                sparklineData: viewModel.spo2Data.suffix(20).map { $0.value },
                                isSelected: selectedMetric == "spo2",
                                onTap: { selectedMetric = selectedMetric == "spo2" ? nil : "spo2" }
                            )
                                                    }
                        .padding(.horizontal, adaptivePadding(for: geometry.size))
                    
                        // ECG Section - More prominent
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("ECG Monitor", systemImage: "waveform.path.ecg")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.green.opacity(0.5), lineWidth: 8)
                                                    .scaleEffect(appearAnimation ? 2 : 1)
                                                    .opacity(appearAnimation ? 0 : 1)
                                                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: appearAnimation)
                                            )
                                        Text("Live")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.green.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .padding(.horizontal, adaptivePadding(for: geometry.size))
                                
                                EnhancedECGWaveform(samples: viewModel.ecgSamples)
                                    .frame(height: adaptiveECGHeight(for: geometry.size))
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.9))
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                                    )
                                    .padding(.horizontal, adaptivePadding(for: geometry.size))
                            }
                        
                            // Charts Section - Compact view
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Recent Trends")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, adaptivePadding(for: geometry.size))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        MetricTabButton(title: "Blood Pressure", icon: "heart.text.square", isSelected: selectedMetric == "bloodPressure", color: .red) {
                                            selectedMetric = selectedMetric == "bloodPressure" ? nil : "bloodPressure"
                                        }
                                        
                                        MetricTabButton(title: "Heart Rate", icon: "heart.fill", isSelected: selectedMetric == "heartRate", color: .pink) {
                                            selectedMetric = selectedMetric == "heartRate" ? nil : "heartRate"
                                        }
                                        
                                        MetricTabButton(title: "Glucose", icon: "drop.fill", isSelected: selectedMetric == "glucose", color: .purple) {
                                            selectedMetric = selectedMetric == "glucose" ? nil : "glucose"
                                        }
                                        
                                        MetricTabButton(title: "SpO2", icon: "lungs.fill", isSelected: selectedMetric == "spo2", color: .blue) {
                                            selectedMetric = selectedMetric == "spo2" ? nil : "spo2"
                                        }
                                        
                                        if !viewModel.troponinData.isEmpty {
                                            MetricTabButton(title: "Troponin", icon: "waveform.path.ecg", isSelected: selectedMetric == "troponin", color: .orange) {
                                                selectedMetric = selectedMetric == "troponin" ? nil : "troponin"
                                            }
                                        }
                                    }
                                    .padding(.horizontal, adaptivePadding(for: geometry.size))
                                }
                            }
                            
                            // Dynamic chart based on selection
                            if let metric = selectedMetric {
                                Group {
                                    switch metric {
                                    case "bloodPressure":
                                        EnhancedChartView(
                                            title: "Blood Pressure Trends",
                                            data: viewModel.bloodPressureData,
                                            unit: "mmHg",
                                            chartType: .line,
                                            range: ChartRange(
                                                min: 60,
                                                max: 200,
                                                normalMin: 90,
                                                normalMax: 140,
                                                criticalMin: nil,
                                                criticalMax: 180
                                            ),
                                            color: .red,
                                            showFullStats: true
                                        )
                                    case "heartRate":
                                        EnhancedChartView(
                                            title: "Heart Rate Analysis",
                                            data: viewModel.heartRateData,
                                            unit: "BPM",
                                            chartType: .area,
                                            range: ChartRange(
                                                min: 40,
                                                max: 150,
                                                normalMin: 60,
                                                normalMax: 100,
                                                criticalMin: 40,
                                                criticalMax: 150
                                            ),
                                            color: .pink,
                                            showFullStats: true
                                        )
                                    case "glucose":
                                        EnhancedChartView(
                                            title: "Glucose Levels",
                                            data: viewModel.glucoseData,
                                            unit: "mg/dL",
                                            chartType: .line,
                                            range: ChartRange(
                                                min: 50,
                                                max: 200,
                                                normalMin: 70,
                                                normalMax: 140,
                                                criticalMin: 70,
                                                criticalMax: 180
                                            ),
                                            color: .purple,
                                            showFullStats: true
                                        )
                                    case "spo2":
                                        EnhancedChartView(
                                            title: "Oxygen Saturation",
                                            data: viewModel.spo2Data,
                                            unit: "%",
                                            chartType: .line,
                                            range: ChartRange(
                                                min: 85,
                                                max: 100,
                                                normalMin: 95,
                                                normalMax: 100,
                                                criticalMin: 90,
                                                criticalMax: nil
                                            ),
                                            color: .blue,
                                            showFullStats: true
                                        )
                                    case "troponin":
                                        EnhancedChartView(
                                            title: "Troponin I Levels",
                                            data: viewModel.troponinData,
                                            unit: "ng/mL",
                                            chartType: .bar,
                                            range: ChartRange(
                                                min: 0,
                                                max: 0.1,
                                                normalMin: 0,
                                                normalMax: 0.04,
                                                criticalMin: nil,
                                                criticalMax: 0.04
                                            ),
                                            color: .orange,
                                            showFullStats: true
                                        )
                                    default:
                                        EmptyView()
                                    }
                                }
                                .padding(.horizontal, adaptivePadding(for: geometry.size))
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                                    removal: .scale(scale: 1.1).combined(with: .opacity)
                                ))
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedMetric)
                            }
                            
                            // Always show compact charts
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    MiniChartCard(
                                        title: "Blood Pressure",
                                        value: "\(viewModel.currentBP.systolic)/\(viewModel.currentBP.diastolic)",
                                        unit: "mmHg",
                                        data: viewModel.bloodPressureData.suffix(30).map { $0.value },
                                        color: .red,
                                        icon: "heart.text.square"
                                    )
                                    
                                    MiniChartCard(
                                        title: "Heart Rate",
                                        value: "\(viewModel.currentHeartRate)",
                                        unit: "BPM",
                                        data: viewModel.heartRateData.suffix(30).map { $0.value },
                                        color: .pink,
                                        icon: "heart.fill"
                                    )
                                }
                                
                                HStack(spacing: 12) {
                                    MiniChartCard(
                                        title: "Glucose",
                                        value: String(format: "%.0f", viewModel.currentGlucose),
                                        unit: "mg/dL",
                                        data: viewModel.glucoseData.suffix(30).map { $0.value },
                                        color: .purple,
                                        icon: "drop.fill"
                                    )
                                    
                                    MiniChartCard(
                                        title: "SpO2",
                                        value: "\(viewModel.currentSpO2)",
                                        unit: "%",
                                        data: viewModel.spo2Data.suffix(30).map { $0.value },
                                        color: .blue,
                                        icon: "lungs.fill"
                                    )
                                }
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry.size))
                    }
                    }
                    .padding(.bottom, 100) // Space for tab bar and floating buttons
                }
            }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .overlay(
                // Floating Action Buttons
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        Spacer()
                        
                        // Refresh button
                        FloatingActionButton(
                            icon: "arrow.clockwise",
                            color: .blue,
                            action: { 
                                withAnimation(.spring()) {
                                    viewModel.refreshData()
                                }
                            }
                        )
                        
                        // Devices button
                        NavigationLink(destination: ModernDevicesView()) {
                            FloatingActionButton(
                                icon: "antenna.radiowaves.left.and.right",
                                color: .purple,
                                action: { }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, horizontalSizeClass == .compact ? 20 : 30)
                }
            )
            .sheet(isPresented: $showingAlerts) {
                AlertsListView(alerts: viewModel.currentAlerts)
            }
            .onAppear {
                appearAnimation = true
            }
            } // End GeometryReader
        } // End NavigationStack
    } // End body var
    
    // MARK: - Helper Functions
    
    private func getTrend(for data: [ChartDataPoint]) -> Double {
        guard data.count > 1 else { return 0 }
        let recent = data.suffix(5)
        guard let first = recent.first?.value,
              let last = recent.last?.value else { return 0 }
        return last - first
    }
    
    // MARK: - Responsive Layout Helpers
    
    private func adaptiveSpacing(for size: CGSize) -> CGFloat {
        if size.width < 400 {
            return 12
        } else if size.width < 700 {
            return 16
        } else {
            return 20
        }
    }
    
    private func adaptivePadding(for size: CGSize) -> CGFloat {
        if size.width < 400 {
            return 12
        } else if size.width < 700 {
            return 16
        } else {
            return 24
        }
    }
    
    private func adaptiveECGHeight(for size: CGSize) -> CGFloat {
        if size.height < 600 {
            return 120
        } else if size.height < 900 {
            return 150
        } else {
            return 180
        }
    }
    
    private func adaptiveGridColumns(for size: CGSize) -> [GridItem] {
        if size.width < 400 {
            // Single column for very small screens
            return [GridItem(.flexible())]
        } else if size.width < 600 {
            // Two columns for compact screens
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        } else if size.width < 900 {
            // Three columns for medium screens
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
        } else {
            // Four columns for large screens
            return Array(repeating: GridItem(.flexible(), spacing: 20), count: 4)
        }
    }
    
    private func adaptiveChartColumns(for size: CGSize) -> [GridItem] {
        if size.width < 600 {
            return [GridItem(.flexible())]
        } else if size.width < 900 {
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        } else {
            return Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
        }
    }

// MARK: - Enhanced Supporting Views

struct ResponsiveHeader: View {
    let connectionStatus: String
    let screenWidth: CGFloat
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var isCompact: Bool {
        screenWidth < 400
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if !isCompact {
                    Text("Welcome Back")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("Health Dashboard")
                    .font(isCompact ? .title3 : .title2)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer()
            
            // Connection Status
            HStack(spacing: 6) {
                Circle()
                    .fill(connectionStatus == "Connected" ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                if !isCompact {
                    Text(connectionStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, isCompact ? 8 : 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
}

struct EnhancedStatusHeader: View {
    let connectionStatus: String
    let lastUpdated: Date
    let alertCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Connection Status with animation
            HStack(spacing: 8) {
                Circle()
                    .fill(connectionStatus == "Connected" ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(connectionStatus == "Connected" ? Color.green.opacity(0.5) : Color.gray.opacity(0.5), lineWidth: 8)
                            .scaleEffect(connectionStatus == "Connected" ? 1.5 : 1)
                            .opacity(connectionStatus == "Connected" ? 0 : 1)
                            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: connectionStatus)
                    )
                
                Text(connectionStatus)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
            )
            
            Spacer()
            
            // Alert Badge
            if alertCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                    Text("\(alertCount)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 5, y: 2)
                )
            }
            
            // Last Updated
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                Text(lastUpdated, style: .relative)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
            )
        }
        .padding(.horizontal)
    }
}

struct StatusHeaderView: View {
    let connectionStatus: String
    let lastUpdated: Date
    let alertCount: Int
    
    var body: some View {
        HStack {
            // Connection Status
            HStack(spacing: 6) {
                Circle()
                    .fill(connectionStatus == "Connected" ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(connectionStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Alert Count
            if alertCount > 0 {
                Label("\(alertCount)", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            // Last Updated
            Text("Updated \(lastUpdated, style: .relative) ago")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
}

struct ModernStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: Double
    let sparklineData: [Double]
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.sizeCategory) private var sizeCategory
    
    private var iconSize: CGFloat {
        sizeCategory.isAccessibilityCategory ? 24 : 20
    }
    
    private var padding: CGFloat {
        sizeCategory.isAccessibilityCategory ? 16 : 12
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: sizeCategory.isAccessibilityCategory ? 16 : 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                // Value and title
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: sizeCategory.isAccessibilityCategory ? 13 : 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.8)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(value)
                            .font(.system(size: sizeCategory.isAccessibilityCategory ? 20 : 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.7)
                        
                        Text(unit)
                            .font(.system(size: sizeCategory.isAccessibilityCategory ? 12 : 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 0)
                
                // Trend indicator
                if trend != 0 {
                    Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: sizeCategory.isAccessibilityCategory ? 14 : 12, weight: .medium))
                        .foregroundColor(trend > 0 ? .red : .green)
                }
            }
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.08))
                    .shadow(color: Color.black.opacity(0.05), radius: 3, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MiniChartCard: View {
    let title: String
    let value: String
    let unit: String
    let data: [Double]
    let color: Color
    let icon: String
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var iconSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 18 : 14
    }
    
    private var titleFont: Font {
        dynamicTypeSize.isAccessibilitySize ? .system(size: 14, weight: .medium) : .system(size: 12, weight: .medium)
    }
    
    private var valueFont: Font {
        dynamicTypeSize.isAccessibilitySize ? .system(size: 24, weight: .bold, design: .rounded) : .system(size: 20, weight: .bold, design: .rounded)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(titleFont)
                    .foregroundColor(.secondary)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(valueFont)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.7)
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if !data.isEmpty {
                SparklineView(data: data, color: color, lineWidth: 1.5)
                    .frame(minHeight: 30, maxHeight: 40)
                    .opacity(0.8)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.08))
                .shadow(color: Color.black.opacity(0.05), radius: 3, y: 1)
        )
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                if trend != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(String(format: "%.1f", abs(trend)))
                            .font(.caption2)
                    }
                    .foregroundColor(trend > 0 ? .red : .green)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct EnhancedAlertBanner: View {
    let alerts: [HealthAlert]
    @State private var currentAlertIndex = 0
    @State private var timer: Timer?
    
    var criticalAlerts: [HealthAlert] {
        alerts.filter { $0.severity == .critical || $0.severity == .emergency }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !criticalAlerts.isEmpty {
                HStack(spacing: 12) {
                    // Animated icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        if #available(iOS 17.0, *) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                                .symbolEffect(.pulse.byLayer, options: .repeating)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if criticalAlerts.indices.contains(currentAlertIndex) {
                            Text(criticalAlerts[currentAlertIndex].title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(criticalAlerts[currentAlertIndex].message)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Alert counter
                    if criticalAlerts.count > 1 {
                        Text("\(currentAlertIndex + 1) of \(criticalAlerts.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.9),
                            Color.orange.opacity(0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color.red.opacity(0.3), radius: 10, y: 5)
        )
        .padding(.horizontal)
        .onAppear {
            startAlertRotation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startAlertRotation() {
        guard criticalAlerts.count > 1 else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentAlertIndex = (currentAlertIndex + 1) % criticalAlerts.count
            }
        }
    }
}

struct AlertBannerView: View {
    let alerts: [HealthAlert]
    
    var criticalCount: Int {
        alerts.filter { $0.severity == .critical || $0.severity == .emergency }.count
    }
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text("\(criticalCount) Critical Alert\(criticalCount == 1 ? "" : "s")")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.red, Color.orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct AlertsListView: View {
    let alerts: [HealthAlert]
    @Environment(\.dismiss) var dismiss
    
    private func getSeverityIcon(_ severity: HealthAlert.AlertSeverity) -> String {
        switch severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .urgent: return "exclamationmark.2"
        case .critical: return "exclamationmark.3"
        case .emergency: return "exclamationmark.octagon.fill"
        }
    }
    
    private func getSeverityColor(_ severity: HealthAlert.AlertSeverity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .yellow
        case .urgent: return .orange
        case .critical: return .red
        case .emergency: return .purple
        }
    }
    
    var body: some View {
        NavigationView {
            List(alerts) { alert in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: getSeverityIcon(alert.severity))
                            .foregroundColor(getSeverityColor(alert.severity))
                        
                        Text(alert.title)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(alert.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(alert.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if alert.actionRequired {
                        Label("Action Required", systemImage: "hand.raised.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Health Alerts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced ECG Waveform

struct EnhancedECGWaveform: View {
    let samples: [Double]
    @State private var drawingProgress: CGFloat = 0
    @State private var glowAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid background
                ECGGrid()
                    .stroke(Color.green.opacity(0.1), lineWidth: 0.5)
                
                // Main waveform with glow effect
                Path { path in
                    guard !samples.isEmpty else { return }
                    
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let midY = height / 2
                    
                    let maxAmplitude = samples.map { abs($0) }.max() ?? 1.0
                    let scale = (height * 0.35) / maxAmplitude
                    
                    let visibleSamples = min(samples.count, 500)
                    let xStep = width / CGFloat(visibleSamples)
                    
                    for (index, sample) in samples.prefix(visibleSamples).enumerated() {
                        let progress = CGFloat(index) / CGFloat(visibleSamples)
                        if progress > drawingProgress { break }
                        
                        let x = CGFloat(index) * xStep
                        let y = midY - (CGFloat(sample) * scale)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .trim(from: 0, to: drawingProgress)
                .stroke(Color.green, lineWidth: 2)
                .shadow(color: Color.green.opacity(glowAnimation ? 0.8 : 0.4), radius: glowAnimation ? 8 : 4)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowAnimation)
                
                // Scanning line effect
                if drawingProgress >= 1 {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color.green.opacity(0.3), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 2)
                        .offset(x: geometry.size.width * (drawingProgress - 1))
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2)) {
                drawingProgress = 1
            }
            glowAnimation = true
        }
    }
}

struct ECGGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gridSize: CGFloat = 20
        
        // Vertical lines
        stride(from: 0, to: rect.width, by: gridSize).forEach { x in
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        // Horizontal lines
        stride(from: 0, to: rect.height, by: gridSize).forEach { y in
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        return path
    }
}

// MARK: - Additional Enhanced Components

struct MetricTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedChartView: View {
    let title: String
    let data: [ChartDataPoint]
    let unit: String
    let chartType: ChartType
    let range: ChartRange?
    let color: Color
    let showFullStats: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Stats overview
            if showFullStats && !data.isEmpty {
                HStack(spacing: 20) {
                    StatItem(label: "Current", value: String(format: "%.1f", data.last?.value ?? 0), unit: unit, color: color)
                    StatItem(label: "Average", value: String(format: "%.1f", data.map { $0.value }.reduce(0, +) / Double(data.count)), unit: unit, color: .gray)
                    StatItem(label: "Min", value: String(format: "%.1f", data.map { $0.value }.min() ?? 0), unit: unit, color: .blue)
                    StatItem(label: "Max", value: String(format: "%.1f", data.map { $0.value }.max() ?? 0), unit: unit, color: .red)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                )
            }
            
            // Enhanced chart
            HealthChartView(
                title: title,
                data: data,
                unit: unit,
                chartType: chartType,
                range: range,
                color: color,
                showLegend: true,
                animated: true
            )
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CompactChartView: View {
    let title: String
    let data: [ChartDataPoint]
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon and title
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let lastValue = data.last {
                        HStack(spacing: 4) {
                            Text(String(format: "%.1f", lastValue.value))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text(unit)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Mini sparkline
            if !data.isEmpty {
                SparklineView(
                    data: data.suffix(30).map { $0.value },
                    color: color,
                    lineWidth: 2
                )
                .frame(width: 100, height: 40)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.3), radius: isPressed ? 5 : 10, y: isPressed ? 2 : 5)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(icon == "arrow.clockwise" && isPressed ? 360 : 0))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = pressing
                }
            },
            perform: { }
        )
    }
}

// MARK: - Preview

struct HealthDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        HealthDashboardView()
    }
}
