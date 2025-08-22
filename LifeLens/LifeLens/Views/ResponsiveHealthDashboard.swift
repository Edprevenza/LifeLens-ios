//
//  ResponsiveHealthDashboard.swift
//  LifeLens
//
//  Fully responsive and progressive health dashboard
//

import SwiftUI
import Combine

struct ResponsiveHealthDashboard: View {
    @StateObject private var viewModel = HealthDashboardViewModel()
    @StateObject private var orientationObserver = OrientationObserver()
    @StateObject private var networkReachability = NetworkReachability.shared
    @StateObject private var progressiveLoader = ProgressiveLoadingManager()
    
    @State private var selectedMetric: String? = nil
    @State private var showingAlerts = false
    @State private var appearAnimation = false
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    // Computed layout properties
    private var isCompact: Bool {
        horizontalSizeClass == .compact || ScreenSizeCategory.current == .compact
    }
    
    private var isTablet: Bool {
        DeviceType.current == .iPad
    }
    
    private var columns: [GridItem] {
        if orientationObserver.isLandscape {
            return AdaptiveGrid.columns(minWidth: 160, maxColumns: 6)
        } else {
            return AdaptiveGrid.columns(minWidth: 140, maxColumns: 4)
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Adaptive background
                    adaptiveBackground
                    
                    // Main content with pull to refresh
                    ScrollView(.vertical, showsIndicators: false) {
                        RefreshableScrollView(onRefresh: {
                            await refreshData()
                        }) {
                            VStack(spacing: ResponsiveDimensions.spacing(20)) {
                                // Responsive header
                                responsiveHeader(geometry: geometry)
                                
                                // Connection status banner
                                if !networkReachability.isConnected {
                                    offlineBanner
                                }
                                
                                // Alert banner
                                if !viewModel.currentAlerts.isEmpty {
                                    alertBanner
                                }
                                
                                // Vital signs grid
                                vitalSignsGrid(geometry: geometry)
                                
                                // ECG Monitor
                                if !isCompact || selectedMetric == "ecg" {
                                    ecgMonitor(geometry: geometry)
                                }
                                
                                // Trends section
                                trendsSection(geometry: geometry)
                                
                                // Progressive loading indicator
                                if progressiveLoader.isLoadingMore {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .responsivePadding()
                        }
                    }
                    
                    // Floating action buttons
                    floatingActionButtons
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAlerts) {
            AlertsListView(alerts: viewModel.currentAlerts)
        }
        .onAppear {
            appearAnimation = true
            Task {
                await loadInitialData()
            }
        }
    }
    
    // MARK: - Adaptive Background
    private var adaptiveBackground: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Responsive Header
    private func responsiveHeader(geometry: GeometryProxy) -> some View {
        HStack(alignment: .center, spacing: ResponsiveDimensions.spacing()) {
            VStack(alignment: .leading, spacing: 4) {
                if !isCompact {
                    Text("Welcome Back")
                        .responsiveFont(.caption, weight: .medium)
                        .foregroundColor(.secondary)
                }
                
                Text("Health Dashboard")
                    .responsiveFont(isCompact ? .title3 : .title2, weight: .bold)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Connection indicator
            connectionIndicator
            
            // Notification button
            if !isCompact {
                notificationButton
            }
        }
        .frame(maxWidth: maxContentWidth(for: geometry))
    }
    
    // MARK: - Connection Indicator
    private var connectionIndicator: some View {
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
            
            if !isCompact {
                Text(viewModel.connectionStatus)
                    .responsiveFont(.caption, weight: .medium)
                    .foregroundColor(.secondary)
            }
        }
        .responsivePadding(.horizontal, base: 12)
        .responsivePadding(.vertical, base: 6)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Notification Button
    private var notificationButton: some View {
        Button(action: { showingAlerts = true }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .responsiveFont(.body, weight: .medium)
                    .foregroundColor(.primary)
                
                if !viewModel.currentAlerts.isEmpty {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .offset(x: 4, y: -4)
                }
            }
        }
        .responsivePadding(base: 8)
        .background(Circle().fill(Color.gray.opacity(0.1)))
    }
    
    // MARK: - Offline Banner
    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
            
            Text("Offline Mode - Showing cached data")
                .responsiveFont(.subheadline, weight: .medium)
            
            Spacer()
        }
        .responsivePadding()
        .background(Color.orange.opacity(0.1))
        .responsiveCornerRadius()
    }
    
    // MARK: - Alert Banner
    private var alertBanner: some View {
        Button(action: { showingAlerts = true }) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                    .responsiveFont(.body, weight: .bold)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.currentAlerts.filter { $0.severity == .critical || $0.severity == .emergency }.count) Critical Alerts")
                        .responsiveFont(.headline, weight: .semibold)
                        .foregroundColor(.white)
                    
                    if let firstAlert = viewModel.currentAlerts.first {
                        Text(firstAlert.message)
                            .responsiveFont(.caption, weight: .regular)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.8))
            }
            .responsivePadding()
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.9), Color.orange.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .responsiveCornerRadius()
        }
    }
    
    // MARK: - Vital Signs Grid
    private func vitalSignsGrid(geometry: GeometryProxy) -> some View {
        LazyVGrid(columns: columns, spacing: ResponsiveDimensions.spacing()) {
            ResponsiveVitalCard(
                title: "Heart Rate",
                value: "\(viewModel.currentHeartRate)",
                unit: "BPM",
                icon: "heart.fill",
                color: .pink,
                trend: getTrend(for: viewModel.heartRateData),
                isSelected: selectedMetric == "heartRate",
                onTap: { toggleMetric("heartRate") }
            )
            
            ResponsiveVitalCard(
                title: "Blood Pressure",
                value: "\(viewModel.currentBP.systolic)/\(viewModel.currentBP.diastolic)",
                unit: "mmHg",
                icon: "waveform.path.ecg",
                color: .red,
                trend: getTrend(for: viewModel.bloodPressureData),
                isSelected: selectedMetric == "bloodPressure",
                onTap: { toggleMetric("bloodPressure") }
            )
            
            ResponsiveVitalCard(
                title: "Glucose",
                value: String(format: "%.0f", viewModel.currentGlucose),
                unit: "mg/dL",
                icon: "drop.fill",
                color: .purple,
                trend: getTrend(for: viewModel.glucoseData),
                isSelected: selectedMetric == "glucose",
                onTap: { toggleMetric("glucose") }
            )
            
            ResponsiveVitalCard(
                title: "SpO2",
                value: "\(viewModel.currentSpO2)",
                unit: "%",
                icon: "lungs.fill",
                color: .blue,
                trend: getTrend(for: viewModel.spo2Data),
                isSelected: selectedMetric == "spo2",
                onTap: { toggleMetric("spo2") }
            )
        }
        .frame(maxWidth: maxContentWidth(for: geometry))
    }
    
    // MARK: - ECG Monitor
    private func ecgMonitor(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: ResponsiveDimensions.spacing(8)) {
            HStack {
                Label("ECG Monitor", systemImage: "waveform.path.ecg")
                    .responsiveFont(.headline, weight: .semibold)
                
                Spacer()
                
                LiveIndicator()
            }
            
            ResponsiveECGWaveform(samples: viewModel.ecgSamples)
                .frame(height: ecgHeight(for: geometry))
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveDimensions.cornerRadius())
                        .fill(Color.black.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveDimensions.cornerRadius())
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        }
        .frame(maxWidth: maxContentWidth(for: geometry))
    }
    
    // MARK: - Trends Section
    private func trendsSection(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: ResponsiveDimensions.spacing()) {
            Text("Recent Trends")
                .responsiveFont(.headline, weight: .semibold)
            
            if let metric = selectedMetric {
                ExpandedMetricChart(
                    metric: metric,
                    viewModel: viewModel
                )
                .frame(height: chartHeight(for: geometry))
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // Compact trend cards
            if orientationObserver.isLandscape {
                HStack(spacing: ResponsiveDimensions.spacing()) {
                    ForEach(["bloodPressure", "heartRate", "glucose", "spo2"], id: \.self) { metric in
                        CompactTrendCard(
                            metric: metric,
                            viewModel: viewModel
                        )
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ResponsiveDimensions.spacing()) {
                    ForEach(["bloodPressure", "heartRate", "glucose", "spo2"], id: \.self) { metric in
                        CompactTrendCard(
                            metric: metric,
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
        .frame(maxWidth: maxContentWidth(for: geometry))
    }
    
    // MARK: - Floating Action Buttons
    private var floatingActionButtons: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: ResponsiveDimensions.spacing()) {
                    if viewModel.connectionStatus == "Disconnected" {
                        FloatingButton(
                            icon: "antenna.radiowaves.left.and.right",
                            color: .blue
                        ) {
                            // Connect to device
                        }
                    }
                    
                    FloatingButton(
                        icon: "arrow.clockwise",
                        color: .green
                    ) {
                        Task {
                            await refreshData()
                        }
                    }
                }
                .responsivePadding()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func toggleMetric(_ metric: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedMetric = selectedMetric == metric ? nil : metric
        }
    }
    
    private func getTrend(for data: [ChartDataPoint]) -> Double {
        guard data.count > 1 else { return 0 }
        let recent = data.suffix(5)
        guard let first = recent.first?.value,
              let last = recent.last?.value else { return 0 }
        return last - first
    }
    
    private func maxContentWidth(for geometry: GeometryProxy) -> CGFloat {
        if isTablet {
            return min(geometry.size.width * 0.9, 1200)
        } else {
            return geometry.size.width
        }
    }
    
    private func ecgHeight(for geometry: GeometryProxy) -> CGFloat {
        if orientationObserver.isLandscape {
            return min(geometry.size.height * 0.3, 200)
        } else if isCompact {
            return 120
        } else {
            return 180
        }
    }
    
    private func chartHeight(for geometry: GeometryProxy) -> CGFloat {
        if orientationObserver.isLandscape {
            return min(geometry.size.height * 0.4, 250)
        } else if isCompact {
            return 200
        } else {
            return 300
        }
    }
    
    // MARK: - Data Loading
    private func loadInitialData() async {
        // Load cached data first
        if let cachedData = OfflineCacheManager.shared.retrieve([ChartDataPoint].self, forKey: "dashboard_data") {
            viewModel.heartRateData = cachedData
        }
        
        // Then fetch fresh data
        viewModel.refreshData()
        
        // Cache the new data
        OfflineCacheManager.shared.cache(viewModel.heartRateData, forKey: "dashboard_data")
    }
    
    private func refreshData() async {
        viewModel.refreshData()
        
        // Update cache
        OfflineCacheManager.shared.cache(viewModel.heartRateData, forKey: "dashboard_data")
    }
}

// MARK: - Supporting Views

struct ResponsiveVitalCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: Double
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.sizeCategory) private var sizeCategory
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: ResponsiveDimensions.spacing(8)) {
                HStack {
                    Image(systemName: icon)
                        .responsiveFont(.body, weight: .semibold)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if trend != 0 && !sizeCategory.isAccessibilityCategory {
                        TrendIndicator(value: trend)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .responsiveFont(.caption, weight: .medium)
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(value)
                            .responsiveFont(.title3, weight: .bold)
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.7)
                        
                        Text(unit)
                            .responsiveFont(.caption2, weight: .medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Mini sparkline
                if !sizeCategory.isAccessibilityCategory {
                    MiniSparkline(color: color)
                        .frame(height: 20)
                        .opacity(0.6)
                }
            }
            .responsivePadding()
            .background(
                RoundedRectangle(cornerRadius: ResponsiveDimensions.cornerRadius())
                    .fill(Color.gray.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: ResponsiveDimensions.cornerRadius())
                            .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ResponsiveECGWaveform: View {
    let samples: [Double]
    @State private var drawingProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid
                ECGGridPattern()
                    .stroke(Color.green.opacity(0.1), lineWidth: 0.5)
                
                // Waveform
                Path { path in
                    guard !samples.isEmpty else { return }
                    
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let midY = height / 2
                    
                    let step = width / CGFloat(samples.count)
                    
                    for (index, sample) in samples.enumerated() {
                        let x = CGFloat(index) * step
                        let y = midY - (CGFloat(sample) * height * 0.3)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .trim(from: 0, to: drawingProgress)
                .stroke(Color.green, lineWidth: 2)
                .shadow(color: Color.green.opacity(0.5), radius: 4)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2)) {
                drawingProgress = 1
            }
        }
    }
}

struct ECGGridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gridSize = ResponsiveDimensions.spacing(20)
        
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

struct LiveIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.5), lineWidth: 8)
                        .scaleEffect(isAnimating ? 2 : 1)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                )
            
            Text("Live")
                .responsiveFont(.caption, weight: .semibold)
                .foregroundColor(.green)
        }
        .responsivePadding(.horizontal, base: 8)
        .responsivePadding(.vertical, base: 4)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct TrendIndicator: View {
    let value: Double
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: value > 0 ? "arrow.up.right" : "arrow.down.right")
                .responsiveFont(.caption2, weight: .medium)
            
            Text(String(format: "%.1f", abs(value)))
                .responsiveFont(.caption2, weight: .medium)
        }
        .foregroundColor(value > 0 ? .red : .green)
    }
}

struct MiniSparkline: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let points = stride(from: 0, to: geometry.size.width, by: 4).map { x in
                    CGPoint(x: x, y: geometry.size.height * CGFloat.random(in: 0.2...0.8))
                }
                
                guard let first = points.first else { return }
                path.move(to: first)
                
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(color, lineWidth: 1.5)
        }
    }
}

struct CompactTrendCard: View {
    let metric: String
    @ObservedObject var viewModel: HealthDashboardViewModel
    
    private var metricData: (value: String, unit: String, icon: String, color: Color) {
        switch metric {
        case "bloodPressure":
            return ("\(viewModel.currentBP.systolic)/\(viewModel.currentBP.diastolic)", "mmHg", "heart.text.square", .red)
        case "heartRate":
            return ("\(viewModel.currentHeartRate)", "BPM", "heart.fill", .pink)
        case "glucose":
            return (String(format: "%.0f", viewModel.currentGlucose), "mg/dL", "drop.fill", .purple)
        case "spo2":
            return ("\(viewModel.currentSpO2)", "%", "lungs.fill", .blue)
        default:
            return ("--", "", "questionmark", .gray)
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: metricData.icon)
                .responsiveFont(.body, weight: .medium)
                .foregroundColor(metricData.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(metricData.value)
                    .responsiveFont(.headline, weight: .bold)
                
                Text(metricData.unit)
                    .responsiveFont(.caption2, weight: .medium)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            MiniSparkline(color: metricData.color)
                .frame(width: 50, height: 30)
        }
        .responsivePadding(base: 12)
        .background(
            RoundedRectangle(cornerRadius: ResponsiveDimensions.cornerRadius(10))
                .fill(Color.gray.opacity(0.08))
        )
    }
}

struct ExpandedMetricChart: View {
    let metric: String
    @ObservedObject var viewModel: HealthDashboardViewModel
    
    var body: some View {
        // Simplified chart view
        RoundedRectangle(cornerRadius: ResponsiveDimensions.cornerRadius())
            .fill(Color.gray.opacity(0.08))
            .overlay(
                VStack {
                    Text("Chart for \(metric)")
                        .responsiveFont(.headline, weight: .semibold)
                    
                    // Chart would go here
                    Color.clear
                }
                .responsivePadding()
            )
    }
}

struct FloatingButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .responsiveFont(.body, weight: .semibold)
                .foregroundColor(.white)
                .frame(width: ResponsiveDimensions.iconSize(56), height: ResponsiveDimensions.iconSize(56))
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.3), radius: isPressed ? 2 : 8, y: isPressed ? 1 : 4)
                )
                .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.spring(response: 0.3)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

// ScaleButtonStyle removed - using PlainButtonStyle instead

struct RefreshableScrollView<Content: View>: View {
    let onRefresh: () async -> Void
    let content: Content
    
    @State private var isRefreshing = false
    
    init(onRefresh: @escaping () async -> Void, @ViewBuilder content: () -> Content) {
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        content
            .refreshable {
                await onRefresh()
            }
    }
}