//
//  ECGMonitorView.swift
//  LifeLens
//
//  Production-grade ECG Monitor Widget
//

import SwiftUI
import Combine

struct ECGMonitorView: View {
    @StateObject private var viewModel = ECGViewModel()
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ECGHeader(
                isLive: viewModel.isLive,
                heartRate: viewModel.currentHeartRate,
                isExpanded: $isExpanded
            )
            
            // Main ECG Display
            ECGWaveformView()
            .frame(height: isExpanded ? 300 : 200)
            .background(Color.black)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            
            // Controls (shown when expanded)
            if isExpanded {
                ECGControls(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Metrics Bar
            ECGMetricsBar(viewModel: viewModel)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
}

// MARK: - ECG Header
struct ECGHeader: View {
    let isLive: Bool
    let heartRate: Int
    @Binding var isExpanded: Bool
    
    var body: some View {
        HStack {
            // Heart Icon
            Image(systemName: "heart.fill")
                .font(.system(size: 20))
                
            .foregroundColor(.red)
                .scaleEffect(isLive ? 1.2 : 1.0)
                .animation(
                    isLive ? Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                    value: isLive
                )
            
            Text("ECG Monitor")
                .font(.system(size: 18, weight: .semibold))
                
            .foregroundColor(.primary)
            
            Spacer()
            
            // Heart Rate Display
            if isLive {
                HStack(spacing: 4) {
                    Text("\(heartRate)")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        
            .foregroundColor(.green)
                    Text("BPM")
                        .font(.system(size: 12, weight: .medium))
                        
            .foregroundColor(.gray)
                }
            }
            
            // Live Indicator
            if isLive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.system(size: 12, weight: .bold))
                        
            .foregroundColor(.red)
                }
            }
            
            // Expand Button
            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    
            .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Live Indicator

// MARK: - ECG Waveform View - Removed (Using consolidated version)
/* Duplicate removed - using shared components
struct ECGWaveformView: View {
    let dataPoints: [CGFloat]
    let isLive: Bool
    let gridEnabled: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var sweepPosition: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                
                // Grid
                if gridEnabled {
                    ECGGridView()
                }
                
                // Waveform
                ECGWaveformPath(
                    dataPoints: dataPoints,
                    size: geometry.size,
                    animationProgress: animationProgress
                )
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.8),
                            Color.green,
                            Color.green.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: .green, radius: 3)
                .animation(.linear(duration: 0.05), value: dataPoints)
                
                // Sweep line effect for live data
                if isLive {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0),
                                    Color.green.opacity(0.3),
                                    Color.green.opacity(0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 30)
                        .offset(x: sweepPosition - geometry.size.width/2)
                        .animation(
                            Animation.linear(duration: 3).repeatForever(autoreverses: false),
                            value: sweepPosition
                        )
                }
                
                // Glow effect at current point
                if isLive && !dataPoints.isEmpty {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .shadow(color: .green, radius: 5)
                        .position(
                            x: geometry.size.width * 0.95,
                            y: geometry.size.height/2 - (dataPoints.last ?? 0) * geometry.size.height * 0.4
                        )
                }
            }
            .onAppear {
                if isLive {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        sweepPosition = geometry.size.width * 2
                    }
                }
                withAnimation(.easeOut(duration: 0.5)) {
                    animationProgress = 1
                }
            }
        }
    }
}

*/ // End duplicate ECGWaveformView

// MARK: - ECG Grid - Also removed
/* Duplicate removed - using shared components
struct ECGGridView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Major grid lines
                Path { path in
                    let majorSpacing: CGFloat = 50
                    
                    // Vertical lines
                    for i in stride(from: 0, through: geometry.size.width, by: majorSpacing) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i, y: geometry.size.height))
                    }
                    
                    // Horizontal lines
                    for i in stride(from: 0, through: geometry.size.height, by: majorSpacing) {
                        path.move(to: CGPoint(x: 0, y: i))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: i))
                    }
                }
                .stroke(Color.green.opacity(0.1), lineWidth: 0.5)
                
                // Minor grid lines
                Path { path in
                    let minorSpacing: CGFloat = 10
                    
                    // Vertical lines
                    for i in stride(from: 0, through: geometry.size.width, by: minorSpacing) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i, y: geometry.size.height))
                    }
                    
                    // Horizontal lines
                    for i in stride(from: 0, through: geometry.size.height, by: minorSpacing) {
                        path.move(to: CGPoint(x: 0, y: i))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: i))
                    }
                }
                .stroke(Color.green.opacity(0.05), lineWidth: 0.25)
            }
        }
    }
}
*/ // End duplicate ECGGridView

// MARK: - ECG Waveform Path
/* Duplicate removed
struct ECGWaveformPath: Shape {
    let dataPoints: [CGFloat]
    let size: CGSize
    var animationProgress: CGFloat
    
    var animatableData: CGFloat {
        get { animationProgress }
        set { animationProgress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard dataPoints.count > 1 else { return path }
        
        let stepX = size.width / CGFloat(dataPoints.count - 1)
        let midY = size.height / 2
        let maxAmplitude = size.height * 0.4
        
        let visiblePoints = Int(CGFloat(dataPoints.count) * animationProgress)
        
        for i in 0..<visiblePoints {
            let x = CGFloat(i) * stepX
            let y = midY - (dataPoints[i] * maxAmplitude)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                // Smooth curve using quadratic bezier
                let prevX = CGFloat(i - 1) * stepX
                let prevY = midY - (dataPoints[i - 1] * maxAmplitude)
                let midX = (prevX + x) / 2
                let midY = (prevY + y) / 2
                
                path.addQuadCurve(
                    to: CGPoint(x: x, y: y),
                    control: CGPoint(x: midX, y: midY)
                )
            }
        }
        
        return path
    }
}
*/ // End duplicate ECGWaveformPath

// MARK: - ECG Controls
struct ECGControls: View {
    @ObservedObject var viewModel: ECGViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause Button
            Button(action: { viewModel.togglePlayPause() }) {
                Label(
                    viewModel.isLive ? "Pause" : "Resume",
                    systemImage: viewModel.isLive ? "pause.fill" : "play.fill"
                )
                .font(.system(size: 14, weight: .medium))
                
            .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewModel.isLive ? Color.orange : Color.green)
                .cornerRadius(8)
            }
            
            // Speed Control
            Menu {
                ForEach(ECGSpeed.allCases, id: \.self) { speed in
                    Button(action: { viewModel.setSpeed(speed) }) {
                        HStack {
                            Text(speed.label)
                            if viewModel.currentSpeed == speed {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Speed: \(viewModel.currentSpeed.label)", systemImage: "speedometer")
                    .font(.system(size: 14, weight: .medium))
                    
            .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Grid Toggle
            Button(action: { viewModel.toggleGrid() }) {
                Image(systemName: viewModel.showGrid ? "grid" : "grid.slash")
                    .font(.system(size: 14, weight: .medium))
                    
            .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(viewModel.showGrid ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Export Button
            Button(action: { viewModel.exportData() }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
                    
            .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - ECG Metrics Bar
struct ECGMetricsBar: View {
    @ObservedObject var viewModel: ECGViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            MetricItem(
                label: "HR",
                value: "\(viewModel.currentHeartRate)",
                unit: "bpm",
                color: viewModel.heartRateStatus.color
            )
            
            Divider()
                .frame(height: 30)
            
            MetricItem(
                label: "QT",
                value: "\(viewModel.qtInterval)",
                unit: "ms",
                color: .blue
            )
            
            Divider()
                .frame(height: 30)
            
            MetricItem(
                label: "PR",
                value: "\(viewModel.prInterval)",
                unit: "ms",
                color: .purple
            )
            
            Divider()
                .frame(height: 30)
            
            MetricItem(
                label: "QRS",
                value: "\(viewModel.qrsComplex)",
                unit: "ms",
                color: .orange
            )
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                
            .foregroundColor(.gray)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    
            .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    
            .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - ECG View Model - Removed (Using consolidated ECGViewModel from ViewModels folder)
/* Duplicate removed - using shared ECGViewModel
// Duplicate removed
// class ECGViewModel: ObservableObject {
    @Published var ecgData: [CGFloat] = []
    @Published var isLive = true
    @Published var showGrid = true
    @Published var currentHeartRate = 72
    @Published var qtInterval = 420
    @Published var prInterval = 160
    @Published var qrsComplex = 90
    @Published var currentSpeed: ECGSpeed = .normal
    
    private var timer: Timer?
    private let maxDataPoints = 200
    private var timeStep = 0.0
    
    enum HeartRateStatus {
        case low, normal, elevated, high
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .normal: return .green
            case .elevated: return .orange
            case .high: return .red
            }
        }
    }
    
    var heartRateStatus: HeartRateStatus {
        switch currentHeartRate {
        case ..<60: return .low
        case 60..<100: return .normal
        case 100..<120: return .elevated
        default: return .high
        }
    }
    
    init() {
        generateInitialData()
        startLiveUpdates()
    }
    
    private func generateInitialData() {
        ecgData = (0..<maxDataPoints).map { i in
            generateECGPoint(at: Double(i) * 0.02)
        }
    }
    
    private func generateECGPoint(at time: Double) -> CGFloat {
        // Simulate realistic ECG waveform with PQRST complex
        let heartRate = Double(currentHeartRate)
        let period = 60.0 / heartRate
        let t = time.truncatingRemainder(dividingBy: period)
        let normalizedT = t / period
        
        var amplitude: Double = 0
        
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
        
        return CGFloat(amplitude)
    }
    
    private func startLiveUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.02 * currentSpeed.multiplier, repeats: true) { _ in
            guard self.isLive else { return }
            
            self.timeStep += 0.02
            let newPoint = self.generateECGPoint(at: self.timeStep)
            
            DispatchQueue.main.async {
                self.ecgData.append(newPoint)
                if self.ecgData.count > self.maxDataPoints {
                    self.ecgData.removeFirst()
                }
                
                // Occasionally vary heart rate for realism
                if Int.random(in: 0..<100) < 5 {
                    self.currentHeartRate = min(max(self.currentHeartRate + Int.random(in: -2...2), 50), 120)
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
    
    func setSpeed(_ speed: ECGSpeed) {
        currentSpeed = speed
        timer?.invalidate()
        if isLive {
            startLiveUpdates()
        }
    }
    
    func exportData() {
        // Export functionality
        print("Exporting ECG data...")
    }
    
    deinit {
        timer?.invalidate()
    }
}

// ECGSpeed enum moved to ECGViewModel.swift
*/ // End of duplicate ECGViewModel

// MARK: - Preview
struct ECGMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        ECGMonitorView()
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color(UIColor.systemBackground))
    }
}