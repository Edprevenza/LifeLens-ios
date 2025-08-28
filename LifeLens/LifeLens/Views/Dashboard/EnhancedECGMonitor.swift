// EnhancedECGMonitor.swift
// Advanced ECG monitor with enhanced animations matching Android

import SwiftUI
import Combine

// MARK: - Enhanced ECG Monitor
struct EnhancedECGMonitor: View {
    @StateObject private var viewModel = EnhancedECGViewModel()
    @State private var isExpanded = false
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ECGHeaderView(
                heartRate: viewModel.heartRate,
                isExpanded: isExpanded,
                toggleAction: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }
            )
            
            // Main ECG Display
            EnhancedECGWaveformView(
                viewModel: viewModel,
                isExpanded: isExpanded
            )
            .frame(height: isExpanded ? 280 : 180)
            .background(Color.black)
            
            // Controls (when expanded)
            if isExpanded {
                ECGControlsPanel(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Metrics Bar
            ECGMetricsDisplay(viewModel: viewModel)
        }
        .background(Color.black)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Enhanced ECG Header

// MARK: - Live Status Indicator
struct LiveStatusIndicator: View {
    let isLive: Bool
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
    
    var body: some View {
        HStack(spacing: 6) {
            // Pulsing dot
            ZStack {
                Circle()
                    .fill(isLive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                if isLive {
                    Circle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                        .onAppear {
                            withAnimation(
                                Animation.easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                            ) {
                                pulseScale = 2.5
                                pulseOpacity = 0
                            }
                        }
                }
            }
            
            Text(isLive ? "Live" : "Paused")
                .font(.system(size: 12, weight: .semibold))
                
            .foregroundColor(isLive ? .green : .gray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill((isLive ? Color.green : Color.gray).opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(isLive ? Color.green : Color.gray, lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced ECG Waveform View
struct EnhancedECGWaveformView: View {
    @ObservedObject var viewModel: EnhancedECGViewModel
    let isExpanded: Bool
    
    @State private var sweepPosition: CGFloat = 0
    @State private var glowIntensity: Double = 0.5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                EnhancedECGGridBackground(size: geometry.size)
                
                // Multiple waveform layers for depth
                ForEach(0..<3) { layer in
                    ECGWaveformLayer(
                        dataPoints: viewModel.ecgData,
                        size: geometry.size,
                        opacity: layer == 0 ? 1.0 : (0.3 / Double(layer + 1)),
                        strokeWidth: layer == 0 ? 2.5 : 1.0,
                        offset: CGFloat(layer) * 2
                    )
                }
                
                // Live sweep effect
                if viewModel.isLive {
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0),
                            Color.green.opacity(0.4),
                            Color.green.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: 30)
                    .offset(x: sweepPosition - geometry.size.width/2)
                    .blur(radius: 5)
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 3)
                                .repeatForever(autoreverses: false)
                        ) {
                            sweepPosition = geometry.size.width
                        }
                    }
                }
                
                // Real-time trace point
                if viewModel.isLive && !viewModel.ecgData.isEmpty {
                    let lastPoint = viewModel.ecgData.last ?? 0
                    let x = geometry.size.width * 0.95
                    let y = geometry.size.height / 2 - (CGFloat(lastPoint) * geometry.size.height * 0.4)
                    
                    // Glowing trace point
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                            .shadow(color: .green, radius: 4)
                        
                        Circle()
                            .fill(Color.green.opacity(glowIntensity))
                            .frame(width: 20, height: 20)
                            .position(x: x, y: y)
                            .blur(radius: 3)
                            .onAppear {
                                withAnimation(
                                    Animation.easeInOut(duration: 0.5)
                                        .repeatForever(autoreverses: true)
                                ) {
                                    glowIntensity = 0.9
                                }
                            }
                    }
                }
            }
        }
    }
}

// MARK: - ECG Waveform Layer
struct ECGWaveformLayer: View {
    let dataPoints: [Float]
    let size: CGSize
    let opacity: Double
    let strokeWidth: Double
    let offset: CGFloat
    
    var body: some View {
        Path { path in
            guard !dataPoints.isEmpty else { return }
            
            let stepX = size.width / CGFloat(dataPoints.count - 1)
            let midY = size.height / 2
            
            for (index, point) in dataPoints.enumerated() {
                let x = CGFloat(index) * stepX
                let y = midY - (CGFloat(point) * size.height * 0.4) + offset
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    // Smooth cubic bezier curves
                    let prevX = CGFloat(index - 1) * stepX
                    let prevY = midY - (CGFloat(dataPoints[index - 1]) * size.height * 0.4) + offset
                    
                    let controlX1 = prevX + (x - prevX) * 0.5
                    let controlY1 = prevY
                    let controlX2 = prevX + (x - prevX) * 0.5
                    let controlY2 = y
                    
                    path.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: controlX1, y: controlY1),
                        control2: CGPoint(x: controlX2, y: controlY2)
                    )
                }
            }
        }
        .stroke(
            LinearGradient(
                colors: [
                    Color.green.opacity(0.6 * opacity),
                    Color.green.opacity(opacity),
                    Color.green.opacity(0.6 * opacity)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(
                lineWidth: strokeWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
        .shadow(color: Color.green.opacity(0.3 * opacity), radius: 2, x: 0, y: 0)
    }
}

// MARK: - Enhanced ECG Grid Background
struct EnhancedECGGridBackground: View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Major grid
            Path { path in
                let majorSpacing: CGFloat = 50
                
                // Vertical lines
                for x in stride(from: 0, through: size.width, by: majorSpacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                
                // Horizontal lines
                for y in stride(from: 0, through: size.height, by: majorSpacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
            .stroke(Color.green.opacity(0.1), lineWidth: 0.5)
            
            // Minor grid
            Path { path in
                let minorSpacing: CGFloat = 10
                
                // Vertical lines
                for x in stride(from: 0, through: size.width, by: minorSpacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                
                // Horizontal lines
                for y in stride(from: 0, through: size.height, by: minorSpacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
            .stroke(Color.green.opacity(0.05), lineWidth: 0.25)
        }
    }
}

// MARK: - ECG Controls Panel
struct ECGControlsPanel: View {
    @ObservedObject var viewModel: EnhancedECGViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause with animation
            Button(action: {
                withAnimation(.spring()) {
                    viewModel.togglePlayPause()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isLive ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                    Text(viewModel.isLive ? "Pause" : "Resume")
                        .font(.system(size: 14, weight: .medium))
                }
                
            .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(viewModel.isLive ? Color.orange : Color.green)
                )
            }
            
            // Speed selector
            Menu {
                ForEach(ECGSpeedOption.allCases, id: \.self) { speed in
                    Button(action: {
                        viewModel.setSpeed(speed)
                    }) {
                        HStack {
                            Text(speed.label)
                            if viewModel.currentSpeed == speed {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 14))
                    Text(viewModel.currentSpeed.label)
                        .font(.system(size: 14))
                }
                
            .foregroundColor(.green)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                )
            }
            
            // Grid toggle
            Button(action: {
                withAnimation {
                    viewModel.toggleGrid()
                }
            }) {
                Image(systemName: viewModel.showGrid ? "grid" : "grid.circle")
                    .font(.system(size: 18))
                    
            .foregroundColor(viewModel.showGrid ? .green : .gray)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.showGrid ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    )
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(white: 0.05))
    }
}

// MARK: - ECG Metrics Display
struct ECGMetricsDisplay: View {
    @ObservedObject var viewModel: EnhancedECGViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            MetricItemDisplay(
                label: "HR",
                value: "\(viewModel.heartRate)",
                unit: "bpm",
                color: viewModel.getHeartRateColor(),
                isAnimated: viewModel.isLive
            )
            
            MetricDivider()
            
            MetricItemDisplay(
                label: "QT",
                value: "\(viewModel.qtInterval)",
                unit: "ms",
                color: Color.blue,
                isAnimated: false
            )
            
            MetricDivider()
            
            MetricItemDisplay(
                label: "PR",
                value: "\(viewModel.prInterval)",
                unit: "ms",
                color: Color.purple,
                isAnimated: false
            )
            
            MetricDivider()
            
            MetricItemDisplay(
                label: "QRS",
                value: "\(viewModel.qrsComplex)",
                unit: "ms",
                color: Color.orange,
                isAnimated: false
            )
        }
        .padding(.vertical, 12)
        .background(Color(white: 0.05))
    }
}

// MARK: - Metric Item Display
struct MetricItemDisplay: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    let isAnimated: Bool
    
    @State private var scaleValue: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                
            .foregroundColor(.gray)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    
            .foregroundColor(color)
                    .scaleEffect(scaleValue)
                    .shadow(color: color.opacity(0.3), radius: 2)
                
                Text(unit)
                    .font(.system(size: 10))
                    
            .foregroundColor(.gray)
                    .padding(.bottom, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: value) { _ in
            if isAnimated {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scaleValue = 1.2
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                    scaleValue = 1.0
                }
            }
        }
    }
}

// MARK: - Metric Divider
struct MetricDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 1, height: 30)
    }
}

// MARK: - Enhanced ECG View Model
class EnhancedECGViewModel: ObservableObject {
    @Published var ecgData: [Float] = []
    @Published var isLive = true
    @Published var showGrid = true
    @Published var heartRate = 72
    @Published var qtInterval = 420
    @Published var prInterval = 160
    @Published var qrsComplex = 90
    @Published var currentSpeed = ECGSpeedOption.normal
    
    private let maxDataPoints = 250
    private var timeStep: Double = 0.0
    private var updateTimer: Timer?
    private var heartRateVariability: Timer?
    
    init() {
        generateRealisticECGData()
        startLiveUpdates()
        startHeartRateVariability()
    }
    
    deinit {
        updateTimer?.invalidate()
        heartRateVariability?.invalidate()
    }
    
    private func generateRealisticECGData() {
        ecgData = (0..<maxDataPoints).map { i in
            generateECGPoint(time: Double(i) * 0.015)
        }
    }
    
    private func generateECGPoint(time: Double) -> Float {
        let heartRateValue = Double(heartRate)
        let period = 60.0 / heartRateValue
        let t = time.truncatingRemainder(dividingBy: period)
        let normalizedT = t / period
        
        var amplitude: Double = 0.0
        
        // Enhanced PQRST complex generation
        // P wave (atrial depolarization)
        if normalizedT >= 0.05 && normalizedT < 0.15 {
            let pWaveT = (normalizedT - 0.05) / 0.1
            amplitude = 0.15 * sin(pWaveT * .pi) * (1 + 0.1 * sin(8 * .pi * pWaveT))
        }
        // PR segment
        else if normalizedT >= 0.15 && normalizedT < 0.19 {
            amplitude = 0.02 * sin(4 * .pi * normalizedT)
        }
        // QRS complex (ventricular depolarization)
        else if normalizedT >= 0.19 && normalizedT < 0.28 {
            let qrsT = (normalizedT - 0.19) / 0.09
            if qrsT < 0.15 {
                // Q wave
                amplitude = -0.15 * sin(qrsT * 6 * .pi)
            } else if qrsT < 0.5 {
                // R wave - sharp peak
                let rT = (qrsT - 0.15) / 0.35
                amplitude = 1.2 * exp(-pow((rT - 0.5) * 4, 2)) * (1 + 0.2 * sin(20 * .pi * rT))
            } else {
                // S wave
                let sT = (qrsT - 0.5) / 0.5
                amplitude = -0.2 * exp(-sT * 2)
            }
        }
        // ST segment
        else if normalizedT >= 0.28 && normalizedT < 0.35 {
            amplitude = 0.01 * sin(2 * .pi * normalizedT)
        }
        // T wave (ventricular repolarization)
        else if normalizedT >= 0.35 && normalizedT < 0.55 {
            let tWaveT = (normalizedT - 0.35) / 0.2
            amplitude = 0.25 * sin(tWaveT * .pi) * (1 + 0.05 * sin(10 * .pi * tWaveT))
        }
        // Baseline with slight variation
        else {
            amplitude = 0.01 * sin(20 * .pi * normalizedT)
        }
        
        // Add realistic noise and baseline wander
        amplitude += Double.random(in: -0.015...0.015) // High-frequency noise
        amplitude += 0.02 * sin(0.25 * .pi * time) // Baseline wander
        
        return Float(amplitude)
    }
    
    private func startLiveUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.015 * currentSpeed.multiplier, repeats: true) { _ in
            if self.isLive {
                self.timeStep += 0.015
                let newPoint = self.generateECGPoint(time: self.timeStep)
                
                var newData = self.ecgData
                newData.append(newPoint)
                if newData.count > self.maxDataPoints {
                    newData.removeFirst()
                }
                
                withAnimation(.linear(duration: 0.015)) {
                    self.ecgData = newData
                }
            }
        }
    }
    
    private func startHeartRateVariability() {
        heartRateVariability = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if self.isLive {
                // Simulate natural heart rate variability
                let variation = Int.random(in: -3...3)
                let newRate = (self.heartRate + variation).clamped(to: 55...95)
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.heartRate = newRate
                }
                
                // Occasionally update other metrics
                if Int.random(in: 0...10) > 7 {
                    self.qtInterval = Int.random(in: 400...440)
                    self.prInterval = Int.random(in: 150...180)
                    self.qrsComplex = Int.random(in: 80...100)
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
    
    func setSpeed(_ speed: ECGSpeedOption) {
        currentSpeed = speed
        updateTimer?.invalidate()
        startLiveUpdates()
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

// MARK: - ECG Speed Options
enum ECGSpeedOption: CaseIterable {
    case slow, normal, fast
    
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

// Note: clamped extension is already defined in AdvancedECGMonitor.swift