// AdvancedECGMonitor.swift
// Advanced ECG monitor with animations matching Android implementation

import SwiftUI
import Combine

// MARK: - Advanced ECG Monitor Widget

struct AdvancedECGMonitor: View {
    @StateObject private var viewModel = ECGMonitorViewModel()
    @State private var isExpanded = false
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 0) {
            // ECG Card
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .overlay(
                    VStack(spacing: 0) {
                        // Header
                        ECGMonitorHeader(
                            isLive: viewModel.isLive,
                            heartRate: viewModel.heartRate,
                            isExpanded: isExpanded,
                            onExpandToggle: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    isExpanded.toggle()
                                }
                            }
                        )
                        
                        // Main ECG Waveform Display
                        AdvancedECGWaveformView(
                            dataPoints: viewModel.ecgData,
                            isLive: viewModel.isLive,
                            showGrid: viewModel.showGrid
                        )
                        .frame(height: isExpanded ? 300 : 200)
                        .background(Color.black)
                        
                        // Controls (shown when expanded)
                        if isExpanded {
                            ECGControlsView(viewModel: viewModel)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Metrics Bar
                        AdvancedECGMetricsBar(viewModel: viewModel)
                    }
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .animation(.easeInOut, value: isExpanded)
    }
}

// MARK: - ECG Header

struct ECGMonitorHeader: View {
    let isLive: Bool
    let heartRate: Int
    let isExpanded: Bool
    let onExpandToggle: () -> Void
    
    @State private var heartScale: CGFloat = 1.0
    
    var body: some View {
        HStack {
            // Animated Heart Icon
            Image(systemName: "heart.fill")
                
            .foregroundColor(.red)
                .scaleEffect(heartScale)
                .animation(
                    isLive ? Animation.easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true) : .default,
                    value: heartScale
                )
                .onAppear {
                    if isLive {
                        heartScale = 1.2
                    }
                }
            
            Text("ECG Monitor")
                .font(.system(size: 18, weight: .semibold))
                
            .foregroundColor(.white)
            
            Spacer()
            
            // Heart Rate Display
            if isLive {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(heartRate)")
                        .font(.system(size: 24, weight: .bold))
                        
            .foregroundColor(.green)
                    
                    Text("BPM")
                        .font(.system(size: 12))
                        
            .foregroundColor(.gray)
                        .padding(.bottom, 2)
                }
            }
            
            // Live Indicator
            LiveIndicatorView(isLive: isLive)
            
            // Expand/Collapse Button
            Button(action: onExpandToggle) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    
            .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.1))
    }
}

// MARK: - Live Indicator

struct LiveIndicatorView: View {
    let isLive: Bool
    @State private var pulseOpacity: Double = 0.5
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isLive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
                .opacity(pulseOpacity)
                .animation(
                    isLive ? Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true) : .default,
                    value: pulseOpacity
                )
                .onAppear {
                    if isLive {
                        pulseOpacity = 1.0
                    }
                }
            
            Text(isLive ? "Live" : "Paused")
                .font(.system(size: 12, weight: .semibold))
                
            .foregroundColor(isLive ? .green : .gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((isLive ? Color.green : Color.gray).opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isLive ? Color.green : Color.gray, lineWidth: 1)
                )
        )
    }
}

// MARK: - ECG Waveform View

struct AdvancedECGWaveformView: View {
    let dataPoints: [Float]
    let isLive: Bool
    let showGrid: Bool
    
    @State private var sweepProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid Background
                if showGrid {
                    AdvancedECGGridView()
                }
                
                // ECG Waveform
                AdvancedECGWaveformPath(
                    dataPoints: dataPoints,
                    size: geometry.size
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.8),
                            Color.green,
                            Color.green.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                
                // Glow effect
                AdvancedECGWaveformPath(
                    dataPoints: dataPoints,
                    size: geometry.size
                )
                .stroke(
                    Color.green.opacity(0.3),
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .blur(radius: 2)
                
                // Sweep line for live effect
                if isLive {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0),
                                    Color.green.opacity(0.3),
                                    Color.green.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 20)
                        .offset(x: geometry.size.width * sweepProgress - geometry.size.width/2)
                        .onAppear {
                            withAnimation(
                                .linear(duration: 3.0)
                                .repeatForever(autoreverses: false)
                            ) {
                                sweepProgress = 1.0
                            }
                        }
                }
                
                // Current point indicator
                if isLive && !dataPoints.isEmpty {
                    let lastPoint = CGFloat(dataPoints.last ?? 0)
                    let x = geometry.size.width * 0.95
                    let y = geometry.size.height / 2 - (lastPoint * geometry.size.height * 0.4)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                    
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - ECG Waveform Path

struct AdvancedECGWaveformPath: Shape {
    let dataPoints: [Float]
    let size: CGSize
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !dataPoints.isEmpty else { return path }
        
        let stepX = size.width / CGFloat(dataPoints.count)
        let midY = size.height / 2
        
        for (index, point) in dataPoints.enumerated() {
            let x = CGFloat(index) * stepX
            let y = midY - (CGFloat(point) * size.height * 0.4)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                let prevX = CGFloat(index - 1) * stepX
                let prevY = midY - (CGFloat(dataPoints[index - 1]) * size.height * 0.4)
                
                // Smooth curve using quadratic bezier
                let controlX = prevX + (x - prevX) * 0.5
                path.addQuadCurve(
                    to: CGPoint(x: x, y: y),
                    control: CGPoint(x: controlX, y: prevY)
                )
            }
        }
        
        return path
    }
}

// MARK: - ECG Grid View

struct AdvancedECGGridView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let majorSpacing: CGFloat = 50
                let minorSpacing: CGFloat = 10
                
                // Minor grid lines
                for x in stride(from: 0, through: geometry.size.width, by: minorSpacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                for y in stride(from: 0, through: geometry.size.height, by: minorSpacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.green.opacity(0.05), lineWidth: 0.25)
            
            Path { path in
                let majorSpacing: CGFloat = 50
                
                // Major grid lines
                for x in stride(from: 0, through: geometry.size.width, by: majorSpacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                for y in stride(from: 0, through: geometry.size.height, by: majorSpacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.green.opacity(0.1), lineWidth: 0.5)
        }
    }
}

// MARK: - ECG Controls

struct ECGControlsView: View {
    @ObservedObject var viewModel: ECGMonitorViewModel
    @State private var showSpeedMenu = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Play/Pause Button
            Button(action: {
                viewModel.togglePlayPause()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isLive ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                    Text(viewModel.isLive ? "Pause" : "Resume")
                        .font(.system(size: 14))
                }
                
            .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(viewModel.isLive ? Color.orange : Color.green)
                .cornerRadius(8)
            }
            
            // Speed Control
            Menu {
                ForEach(AdvancedECGSpeed.allCases, id: \.self) { speed in
                    Button(speed.label) {
                        viewModel.setSpeed(speed)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 14))
                    Text("Speed: \(viewModel.currentSpeed.label)")
                        .font(.system(size: 14))
                }
                
            .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
            }
            
            // Grid Toggle
            Button(action: {
                viewModel.toggleGrid()
            }) {
                Image(systemName: viewModel.showGrid ? "grid" : "grid.circle")
                    .font(.system(size: 16))
                    
            .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(viewModel.showGrid ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Export Button
            Button(action: {
                viewModel.exportData()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                    
            .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color(white: 0.1))
    }
}

// MARK: - ECG Metrics Bar

struct AdvancedECGMetricsBar: View {
    @ObservedObject var viewModel: ECGMonitorViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            MetricItemView(
                label: "HR",
                value: "\(viewModel.heartRate)",
                unit: "bpm",
                color: viewModel.getHeartRateColor()
            )
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .frame(width: 1, height: 30)
            
            MetricItemView(
                label: "QT",
                value: "\(viewModel.qtInterval)",
                unit: "ms",
                color: .blue
            )
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .frame(width: 1, height: 30)
            
            MetricItemView(
                label: "PR",
                value: "\(viewModel.prInterval)",
                unit: "ms",
                color: Color(red: 0.61, green: 0.15, blue: 0.69)
            )
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .frame(width: 1, height: 30)
            
            MetricItemView(
                label: "QRS",
                value: "\(viewModel.qrsComplex)",
                unit: "ms",
                color: Color.orange
            )
        }
        .padding(.vertical, 16)
        .background(Color(white: 0.1))
    }
}

// MARK: - Metric Item View

struct MetricItemView: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .fontWeight(.medium)
                
            .foregroundColor(.gray)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    
            .foregroundColor(color)
                
                Text(unit)
                    .font(.system(size: 10))
                    
            .foregroundColor(.gray)
                    .padding(.bottom, 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ECG Monitor View Model

class ECGMonitorViewModel: ObservableObject {
    @Published var ecgData: [Float] = []
    @Published var isLive = true
    @Published var showGrid = true
    @Published var heartRate = 72
    @Published var qtInterval = 420
    @Published var prInterval = 160
    @Published var qrsComplex = 90
    @Published var currentSpeed = AdvancedECGSpeed.normal
    
    private let maxDataPoints = 200
    private var timeStep: Double = 0.0
    private var updateTimer: Timer?
    
    init() {
        generateInitialData()
        startLiveUpdates()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    private func generateInitialData() {
        ecgData = (0..<maxDataPoints).map { i in
            generateECGPoint(time: Double(i) * 0.02)
        }
    }
    
    private func generateECGPoint(time: Double) -> Float {
        // Simulate realistic ECG waveform with PQRST complex
        let heartRateValue = Double(heartRate)
        let period = 60.0 / heartRateValue
        let t = time.truncatingRemainder(dividingBy: period)
        let normalizedT = t / period
        
        var amplitude: Double = 0.0
        
        // P wave (atrial depolarization)
        if normalizedT >= 0.05 && normalizedT < 0.15 {
            let pWaveT = (normalizedT - 0.05) / 0.1
            amplitude = 0.2 * sin(pWaveT * .pi)
        }
        // QRS complex (ventricular depolarization)
        else if normalizedT >= 0.15 && normalizedT < 0.25 {
            let qrsT = (normalizedT - 0.15) / 0.1
            if qrsT < 0.2 {
                amplitude = -0.3 // Q wave
            } else if qrsT < 0.5 {
                amplitude = 1.5 * (qrsT - 0.2) / 0.3 // R wave
            } else {
                amplitude = -0.4 * (qrsT - 0.5) / 0.5 // S wave
            }
        }
        // T wave (ventricular repolarization)
        else if normalizedT >= 0.3 && normalizedT < 0.5 {
            let tWaveT = (normalizedT - 0.3) / 0.2
            amplitude = 0.3 * sin(tWaveT * .pi)
        }
        
        // Add slight noise for realism
        amplitude += Double.random(in: -0.02...0.02)
        
        return Float(amplitude)
    }
    
    private func startLiveUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.02 * currentSpeed.multiplier, repeats: true) { _ in
            if self.isLive {
                self.timeStep += 0.02
                let newPoint = self.generateECGPoint(time: self.timeStep)
                
                var newData = self.ecgData
                newData.append(newPoint)
                if newData.count > self.maxDataPoints {
                    newData.removeFirst()
                }
                self.ecgData = newData
                
                // Occasionally vary heart rate for realism
                if Int.random(in: 0..<100) < 5 {
                    self.heartRate = (self.heartRate + Int.random(in: -2...2)).clamped(to: 50...120)
                }
            }
        }
    }
    
    func togglePlayPause() {
        isLive.toggle()
    }
    
    func toggleGrid() {
        showGrid.toggle()
    }
    
    func setSpeed(_ speed: AdvancedECGSpeed) {
        currentSpeed = speed
        updateTimer?.invalidate()
        startLiveUpdates()
    }
    
    func exportData() {
        // Export functionality
        print("Exporting ECG data...")
    }
    
    func getHeartRateColor() -> Color {
        switch heartRate {
        case ..<60: return .blue
        case 60..<100: return .green
        case 100..<120: return .orange
        default: return .red
        }
    }
}

// MARK: - ECG Speed

enum AdvancedECGSpeed: CaseIterable {
    case slow
    case normal
    case fast
    
    var label: String {
        switch self {
        case .slow: return "0.5x"
        case .normal: return "1x"
        case .fast: return "2x"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .slow: return 2.0
        case .normal: return 1.0
        case .fast: return 0.5
        }
    }
}

// MARK: - Helper Extensions

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}