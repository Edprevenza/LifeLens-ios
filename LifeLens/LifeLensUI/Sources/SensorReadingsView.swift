//
//  SensorReadingsView.swift
//  LifeLens
//
//  Real-time sensor readings display with live data streaming
//

import SwiftUI
import Charts

struct SensorReadingsView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var selectedSensor: SensorType = .ecg
    @State private var isLiveMode = true
    @State private var refreshTimer: Timer?
    
    enum SensorType: String, CaseIterable {
        case ecg = "ECG"
        case bloodPressure = "Blood Pressure"
        case glucose = "Glucose"
        case spo2 = "SpO2"
        case troponin = "Troponin"
        case temperature = "Temperature"
        
        var icon: String {
            switch self {
            case .ecg: return "waveform.path.ecg"
            case .bloodPressure: return "heart.fill"
            case .glucose: return "drop.fill"
            case .spo2: return "lungs.fill"
            case .troponin: return "waveform.badge.exclamationmark"
            case .temperature: return "thermometer"
            }
        }
        
        var color: Color {
            switch self {
            case .ecg: return .green
            case .bloodPressure: return .red
            case .glucose: return .purple
            case .spo2: return .blue
            case .troponin: return .orange
            case .temperature: return .yellow
            }
        }
        
        var unit: String {
            switch self {
            case .ecg: return "BPM"
            case .bloodPressure: return "mmHg"
            case .glucose: return "mg/dL"
            case .spo2: return "%"
            case .troponin: return "ng/mL"
            case .temperature: return "°F"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Logo at the top
                    LifeLensLogo(size: .small, style: .standalone)
                        .padding(.top, 20)
                    
                    // Header
                    SensorReadingsHeader(
                        isLiveMode: $isLiveMode,
                        connectionStatus: bluetoothManager.connectionState
                    )
                    .padding(.horizontal, 50)
                    .padding(.top, 10)
                    
                    // Live Status Banner
                    if isLiveMode {
                        LiveStatusBanner()
                            .padding(.horizontal, 50)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Sensor Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(SensorType.allCases, id: \.self) { sensor in
                                SensorSelectionCard(
                                    sensor: sensor,
                                    isSelected: selectedSensor == sensor,
                                    isActive: isSensorActive(sensor),
                                    action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedSensor = sensor
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 50)
                    }
                    .frame(height: 130)
                    
                    // Main Sensor Display
                    MainSensorDisplay(
                        sensor: selectedSensor,
                        bluetoothManager: bluetoothManager,
                        viewModel: viewModel,
                        isLiveMode: isLiveMode
                    )
                    .padding(.horizontal, 50)
                    .frame(maxWidth: 1400)
                    .frame(minHeight: 350)
                    
                    // Real-time Values Grid
                    RealTimeValuesGrid(
                        bluetoothManager: bluetoothManager,
                        viewModel: viewModel
                    )
                    .padding(.horizontal, 50)
                    .frame(maxWidth: 1400)
                    
                    // Historical Data
                    if !isLiveMode {
                        HistoricalDataSection(
                            sensor: selectedSensor,
                            viewModel: viewModel
                        )
                        .padding(.horizontal, 50)
                        .frame(maxWidth: 1400)
                        .transition(.opacity)
                    }
                    
                    // Sensor Status Cards
                    SensorStatusSection(bluetoothManager: bluetoothManager)
                        .padding(.horizontal, 50)
                        .frame(maxWidth: 1400)
                        .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startLiveUpdates()
        }
        .onDisappear {
            stopLiveUpdates()
        }
    }
    
    private func isSensorActive(_ sensor: SensorType) -> Bool {
        guard bluetoothManager.connectedDevice != nil else { return false }
        
        switch sensor {
        case .ecg:
            return bluetoothManager.currentECG != nil
        case .bloodPressure:
            return bluetoothManager.currentBloodPressure != nil
        case .glucose:
            return bluetoothManager.currentGlucose != nil
        case .spo2:
            return bluetoothManager.currentSpO2 != nil
        case .troponin:
            return bluetoothManager.currentTroponin != nil
        case .temperature:
            return true // Always active if device connected
        }
    }
    
    private func startLiveUpdates() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Trigger UI updates for live data
        }
    }
    
    private func stopLiveUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Header

struct SensorReadingsHeader: View {
    @Binding var isLiveMode: Bool
    let connectionStatus: BLEConnectionState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sensor Readings")
                    .font(.system(size: 28, weight: .bold))
                    
            .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(connectionStatus == .connected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(connectionStatus == .connected ? "Device Connected" : "No Device")
                        .font(.system(size: 14))
                        
            .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Live/History Toggle
            HStack(spacing: 0) {
                Button(action: { isLiveMode = true }) {
                    Text("Live")
                        .font(.system(size: 12, weight: .medium))
                        
            .foregroundColor(isLiveMode ? .white : .gray)
                        .frame(width: 50, height: 30)
                        .background(isLiveMode ? Color.green : Color.clear)
                }
                
                Button(action: { isLiveMode = false }) {
                    Text("History")
                        .font(.system(size: 12, weight: .medium))
                        
            .foregroundColor(!isLiveMode ? .white : .gray)
                        .frame(width: 60, height: 30)
                        .background(!isLiveMode ? Color.blue : Color.clear)
                }
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
    }
}

// MARK: - Live Status Banner

struct LiveStatusBanner: View {
    @State private var pulseAnimation = false
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Text("LIVE DATA STREAMING")
                    .font(.system(size: 11, weight: .bold))
                    
            .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(Date(), style: .time)
                .font(.system(size: 11, design: .monospaced))
                
            .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - Sensor Selection Card

struct SensorSelectionCard: View {
    let sensor: SensorReadingsView.SensorType
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? sensor.color.opacity(0.15) : Color.white.opacity(0.03))
                        .frame(width: 90, height: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? sensor.color : Color.white.opacity(0.08),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                        .shadow(
                            color: isSelected ? sensor.color.opacity(0.3) : .clear,
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                    
                    VStack(spacing: 6) {
                        Image(systemName: sensor.icon)
                            .font(.system(size: 28, weight: isSelected ? .semibold : .regular))
                            
            .foregroundColor(isSelected ? sensor.color : .gray.opacity(0.6))
                        
                        if isActive {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                                        .frame(width: 12, height: 12)
                                )
                        }
                    }
                }
                
                Text(sensor.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    
            .foregroundColor(isSelected ? .white : .gray)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Main Sensor Display

struct MainSensorDisplay: View {
    let sensor: SensorReadingsView.SensorType
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var viewModel: HealthDashboardViewModel
    let isLiveMode: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Title and Status
            HStack {
                Label(sensor.rawValue, systemImage: sensor.icon)
                    .font(.system(size: 18, weight: .semibold))
                    
            .foregroundColor(.white)
                
                Spacer()
                
                if isLiveMode {
                    Text("Real-time")
                        .font(.system(size: 11))
                        
            .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            // Main Display based on sensor type
            Group {
                switch sensor {
                case .ecg:
                    // Simple ECG data display - NOT the full monitor widget
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40))
                                
            .foregroundColor(.red)
                                .scaleEffect(isLiveMode ? 1.1 : 1.0)
                                .animation(
                                    isLiveMode ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                                    value: isLiveMode
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Heart Rate")
                                    .font(.system(size: 14, weight: .medium))
                                    
            .foregroundColor(.secondary)
                                
                                HStack(alignment: .bottom, spacing: 4) {
                                    Text("\(viewModel.currentHeartRate)")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        
            .foregroundColor(.primary)
                                    Text("BPM")
                                        .font(.system(size: 16, weight: .medium))
                                        
            .foregroundColor(.secondary)
                                        .padding(.bottom, 8)
                                }
                            }
                        }
                        
                        // Simple waveform visualization
                        if !viewModel.ecgSamples.isEmpty {
                            GeometryReader { geometry in
                                Path { path in
                                    let width = geometry.size.width
                                    let height = geometry.size.height
                                    let midY = height / 2
                                    let samples = Array(viewModel.ecgSamples.prefix(100))
                                    
                                    for (index, sample) in samples.enumerated() {
                                        let x = CGFloat(index) * width / CGFloat(samples.count)
                                        let y = midY - CGFloat(sample) * height * 0.3
                                        
                                        if index == 0 {
                                            path.move(to: CGPoint(x: x, y: y))
                                        } else {
                                            path.addLine(to: CGPoint(x: x, y: y))
                                        }
                                    }
                                }
                                .stroke(Color.green, lineWidth: 2)
                            }
                            .frame(height: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.8))
                            )
                        }
                    }
                    
                case .bloodPressure:
                    BloodPressureLiveDisplay(
                        systolic: viewModel.currentBP.systolic,
                        diastolic: viewModel.currentBP.diastolic
                    )
                    
                case .glucose:
                    GlucoseLiveDisplay(
                        glucose: viewModel.currentGlucose,
                        trend: bluetoothManager.currentGlucose?.trend
                    )
                    
                case .spo2:
                    SpO2LiveDisplay(
                        spo2: viewModel.currentSpO2,
                        perfusionIndex: bluetoothManager.currentSpO2?.perfusionIndex ?? 0
                    )
                    
                case .troponin:
                    TroponinLiveDisplay(
                        troponinI: viewModel.currentTroponin.i,
                        troponinT: viewModel.currentTroponin.t
                    )
                    
                case .temperature:
                    TemperatureLiveDisplay(temperature: 98.6)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(sensor.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Sensor-Specific Live Displays

struct BloodPressureLiveDisplay: View {
    let systolic: Int
    let diastolic: Int
    
    var body: some View {
        HStack(spacing: 40) {
            VStack(spacing: 8) {
                Text("SYS")
                    .font(.system(size: 12, weight: .medium))
                    
            .foregroundColor(.gray)
                
                Text("\(systolic)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    
            .foregroundColor(.red)
                
                Text("mmHg")
                    .font(.system(size: 11))
                    
            .foregroundColor(.gray)
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 80)
            
            VStack(spacing: 8) {
                Text("DIA")
                    .font(.system(size: 12, weight: .medium))
                    
            .foregroundColor(.gray)
                
                Text("\(diastolic)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    
            .foregroundColor(.pink)
                
                Text("mmHg")
                    .font(.system(size: 11))
                    
            .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct GlucoseLiveDisplay: View {
    let glucose: Double
    let trend: GlucoseData.GlucoseTrend?
    
    var trendIcon: String {
        switch trend {
        case .rapidlyRising: return "arrow.up.right"
        case .rising: return "arrow.up.forward"
        case .stable: return "arrow.right"
        case .falling: return "arrow.down.forward"
        case .rapidlyFalling: return "arrow.down.right"
        case .none: return "minus"
        }
    }
    
    func getTrendText(_ trend: GlucoseData.GlucoseTrend?) -> String {
        switch trend {
        case .rapidlyRising: return "Rising Fast"
        case .rising: return "Rising"
        case .stable: return "Stable"
        case .falling: return "Falling"
        case .rapidlyFalling: return "Falling Fast"
        case .none: return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                Text(String(format: "%.0f", glucose))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    
            .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("mg/dL")
                        .font(.system(size: 14))
                        
            .foregroundColor(.gray)
                    
                    if trend != nil {
                        HStack(spacing: 4) {
                            Image(systemName: trendIcon)
                                .font(.system(size: 14))
                            Text(getTrendText(trend))
                                .font(.system(size: 12))
                        }
                        
            .foregroundColor(.orange)
                    }
                }
            }
            
            // Glucose Range Indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Normal range
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.3))
                        .frame(width: geometry.size.width * 0.5, height: 8)
                        .offset(x: geometry.size.width * 0.25)
                    
                    // Current value indicator
                    Circle()
                        .fill(glucose < 70 || glucose > 180 ? Color.red : Color.green)
                        .frame(width: 16, height: 16)
                        .offset(x: min(max(0, (glucose - 40) / 260 * geometry.size.width - 8), geometry.size.width - 16))
                }
            }
            .frame(height: 16)
        }
        .padding(.vertical, 10)
    }
}

struct SpO2LiveDisplay: View {
    let spo2: Int
    let perfusionIndex: Double
    
    var body: some View {
        VStack(spacing: 20) {
            // SpO2 Value
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(spo2)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    
            .foregroundColor(spo2 >= 95 ? .blue : .orange)
                
                Text("%")
                    .font(.system(size: 24))
                    
            .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }
            
            // Perfusion Index
            VStack(spacing: 4) {
                Text("Perfusion Index")
                    .font(.system(size: 11, weight: .medium))
                    
            .foregroundColor(.gray)
                
                HStack {
                    ForEach(0..<5) { i in
                        Rectangle()
                            .fill(i < Int(perfusionIndex * 2.5) ? Color.blue : Color.gray.opacity(0.2))
                            .frame(width: 30, height: 8)
                            .cornerRadius(2)
                    }
                }
                
                Text(String(format: "%.1f", perfusionIndex))
                    .font(.system(size: 14, weight: .medium))
                    
            .foregroundColor(.white)
            }
        }
    }
}

struct TroponinLiveDisplay: View {
    let troponinI: Double
    let troponinT: Double
    
    var isElevated: Bool {
        troponinI > 0.04 || troponinT > 0.01
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if isElevated {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        
            .foregroundColor(.red)
                    Text("ELEVATED LEVELS DETECTED")
                        .font(.system(size: 12, weight: .bold))
                        
            .foregroundColor(.red)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("Troponin I")
                        .font(.system(size: 12, weight: .medium))
                        
            .foregroundColor(.gray)
                    
                    Text(String(format: "%.3f", troponinI))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        
            .foregroundColor(troponinI > 0.04 ? .red : .orange)
                    
                    Text("ng/mL")
                        .font(.system(size: 11))
                        
            .foregroundColor(.gray)
                }
                
                VStack(spacing: 8) {
                    Text("Troponin T")
                        .font(.system(size: 12, weight: .medium))
                        
            .foregroundColor(.gray)
                    
                    Text(String(format: "%.3f", troponinT))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        
            .foregroundColor(troponinT > 0.01 ? .red : .orange)
                    
                    Text("ng/mL")
                        .font(.system(size: 11))
                        
            .foregroundColor(.gray)
                }
            }
        }
    }
}

struct TemperatureLiveDisplay: View {
    let temperature: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 4) {
                Text(String(format: "%.1f", temperature))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    
            .foregroundColor(temperature > 99.5 ? .orange : .green)
                
                Text("°F")
                    .font(.system(size: 24))
                    
            .foregroundColor(.gray)
                    .padding(.top, 10)
            }
            
            Text(temperature > 99.5 ? "Slightly Elevated" : "Normal")
                .font(.system(size: 14, weight: .medium))
                
            .foregroundColor(temperature > 99.5 ? .orange : .green)
        }
    }
}

// MARK: - Real-time Values Grid

struct RealTimeValuesGrid: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var viewModel: HealthDashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Sensor Values")
                .font(.system(size: 18, weight: .semibold))
                
            .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SensorValueCard(
                    icon: "heart.fill",
                    label: "Heart Rate",
                    value: "\(viewModel.currentHeartRate)",
                    unit: "BPM",
                    color: .red,
                    status: .normal
                )
                
                SensorValueCard(
                    icon: "waveform.path",
                    label: "Blood Pressure",
                    value: "\(viewModel.currentBP.systolic)/\(viewModel.currentBP.diastolic)",
                    unit: "mmHg",
                    color: .pink,
                    status: viewModel.currentBP.systolic > 140 ? .warning : .normal
                )
                
                SensorValueCard(
                    icon: "drop.fill",
                    label: "Glucose",
                    value: String(format: "%.0f", viewModel.currentGlucose),
                    unit: "mg/dL",
                    color: .purple,
                    status: viewModel.currentGlucose > 140 ? .warning : .normal
                )
                
                SensorValueCard(
                    icon: "lungs.fill",
                    label: "SpO2",
                    value: "\(viewModel.currentSpO2)",
                    unit: "%",
                    color: .blue,
                    status: viewModel.currentSpO2 < 95 ? .warning : .normal
                )
            }
        }
    }
}

struct SensorValueCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    let status: Status
    
    enum Status {
        case normal, warning, critical
        
        var color: Color {
            switch self {
            case .normal: return .green
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    
            .foregroundColor(color)
                
                Spacer()
                
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
            }
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                
            .foregroundColor(.gray)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    
            .foregroundColor(.white)
                
                Text(unit)
                    .font(.system(size: 10))
                    
            .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

// MARK: - Historical Data Section

struct HistoricalDataSection: View {
    let sensor: SensorReadingsView.SensorType
    @ObservedObject var viewModel: HealthDashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Historical Data")
                    .font(.system(size: 18, weight: .semibold))
                    
            .foregroundColor(.white)
                
                Spacer()
                
                Text("Last 24 Hours")
                    .font(.system(size: 12))
                    
            .foregroundColor(.gray)
            }
            
            // Chart would go here based on sensor type
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .frame(height: 200)
                .overlay(
                    Text("Historical chart for \(sensor.rawValue)")
                        
            .foregroundColor(.gray.opacity(0.5))
                )
        }
    }
}

// MARK: - Sensor Status Section

struct SensorStatusSection: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sensor Status")
                .font(.system(size: 18, weight: .semibold))
                
            .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SensorStatusRow(
                    name: "ECG Sensor",
                    status: bluetoothManager.currentECG != nil ? "Active" : "Inactive",
                    quality: "Good",
                    lastUpdate: Date()
                )
                
                SensorStatusRow(
                    name: "Blood Pressure",
                    status: bluetoothManager.currentBloodPressure != nil ? "Active" : "Inactive",
                    quality: "Good",
                    lastUpdate: Date()
                )
                
                SensorStatusRow(
                    name: "Glucose Monitor",
                    status: bluetoothManager.currentGlucose != nil ? "Active" : "Inactive",
                    quality: "Fair",
                    lastUpdate: Date()
                )
                
                SensorStatusRow(
                    name: "Pulse Oximeter",
                    status: bluetoothManager.currentSpO2 != nil ? "Active" : "Inactive",
                    quality: "Excellent",
                    lastUpdate: Date()
                )
            }
        }
    }
}

struct SensorStatusRow: View {
    let name: String
    let status: String
    let quality: String
    let lastUpdate: Date
    
    var statusColor: Color {
        status == "Active" ? .green : .gray
    }
    
    var qualityColor: Color {
        switch quality {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    
            .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(status)
                            .font(.system(size: 11))
                            
            .foregroundColor(statusColor)
                    }
                    
                    Text("Signal: \(quality)")
                        .font(.system(size: 11))
                        
            .foregroundColor(qualityColor)
                }
            }
            
            Spacer()
            
            Text(lastUpdate, style: .time)
                .font(.system(size: 11, design: .monospaced))
                
            .foregroundColor(.gray)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.02))
        )
    }
}

// Preview
struct SensorReadingsView_Previews: PreviewProvider {
    static var previews: some View {
        SensorReadingsView()
    }
}