//
//  HealthChartView.swift
//  LifeLens
//
//  Real-time health data chart component using SwiftUI Charts
//

import SwiftUI
import Charts

// MARK: - Chart Data Models
// ChartDataPoint is now defined in APIService.swift

struct ChartRange {
    let min: Double
    let max: Double
    let normalMin: Double?
    let normalMax: Double?
    let criticalMin: Double?
    let criticalMax: Double?
}

enum ChartType {
    case line
    case bar
    case area
    case scatter
}

// MARK: - Main Chart View

struct HealthChartView: View {
    let title: String
    let data: [ChartDataPoint]
    let unit: String
    let chartType: ChartType
    let range: ChartRange?
    let color: Color
    let showLegend: Bool
    let animated: Bool
    
    @State private var selectedPoint: ChartDataPoint?
    @State private var animationProgress: Double = 0
    @State private var touchLocation: CGPoint = .zero
    @State private var showTooltip = false
    @State private var isDragging = false
    
    init(
        title: String,
        data: [ChartDataPoint],
        unit: String,
        chartType: ChartType = .line,
        range: ChartRange? = nil,
        color: Color = .blue,
        showLegend: Bool = true,
        animated: Bool = true
    ) {
        self.title = title
        self.data = data
        self.unit = unit
        self.chartType = chartType
        self.range = range
        self.color = color
        self.showLegend = showLegend
        self.animated = animated
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enhanced Header with stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if !data.isEmpty {
                        HStack(spacing: 12) {
                            Label("Avg: \(averageValue, specifier: "%.1f")\(unit)", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if let lastValue = data.last {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(lastValue.value, specifier: "%.1f")")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(getValueColor(lastValue.value))
                            Text(unit)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(lastValue.timestamp, style: .time)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Enhanced Chart with interaction
            ZStack {
                Chart(data) { point in
                switch chartType {
                case .line:
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value(title, animated ? point.value * animationProgress : point.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    if animated {
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value(title, point.value * animationProgress)
                        )
                        .foregroundStyle(color.opacity(0.1))
                    }
                    
                case .bar:
                    BarMark(
                        x: .value("Time", point.timestamp),
                        y: .value(title, animated ? point.value * animationProgress : point.value)
                    )
                    .foregroundStyle(color)
                    
                case .area:
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value(title, animated ? point.value * animationProgress : point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value(title, animated ? point.value * animationProgress : point.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                case .scatter:
                    PointMark(
                        x: .value("Time", point.timestamp),
                        y: .value(title, animated ? point.value * animationProgress : point.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(100)
                }
                
                // Add reference lines for normal/critical ranges
                if let range = range {
                    if let normalMin = range.normalMin {
                        RuleMark(y: .value("Normal Min", normalMin))
                            .foregroundStyle(Color.green.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                    
                    if let normalMax = range.normalMax {
                        RuleMark(y: .value("Normal Max", normalMax))
                            .foregroundStyle(Color.green.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                    
                    if let criticalMin = range.criticalMin {
                        RuleMark(y: .value("Critical Min", criticalMin))
                            .foregroundStyle(Color.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                    
                    if let criticalMax = range.criticalMax {
                        RuleMark(y: .value("Critical Max", criticalMax))
                            .foregroundStyle(Color.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(preset: .aligned) { _ in
                        AxisValueLabel(format: .dateTime.hour().minute())
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.0f")")
                            .font(.caption)
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.2))
                    }
                }
                .chartYScale(domain: getYDomain())
                .chartBackground { proxy in
                    // Enhanced background with gradient
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.03),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Interactive overlay
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            touchLocation = value.location
                                            showTooltip = true
                                            isDragging = true
                                            
                                            // Find nearest data point
                                            let xProgress = value.location.x / geometry.size.width
                                            let index = Int(xProgress * CGFloat(data.count))
                                            if data.indices.contains(index) {
                                                selectedPoint = data[index]
                                            }
                                        }
                                        .onEnded { _ in
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                showTooltip = false
                                                isDragging = false
                                                selectedPoint = nil
                                            }
                                        }
                                )
                        }
                    }
                }
                
                // Tooltip overlay
                if showTooltip, let selected = selectedPoint {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(selected.value, specifier: "%.1f") \(unit)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(selected.timestamp, style: .time)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .shadow(radius: 4)
                    )
                    .position(x: min(max(50, touchLocation.x), 250), y: max(30, touchLocation.y - 30))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Legend
            if showLegend && range != nil {
                HStack(spacing: 16) {
                    if range?.normalMin != nil || range?.normalMax != nil {
                        Label("Normal Range", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if range?.criticalMin != nil || range?.criticalMax != nil {
                        Label("Critical", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: isDragging ? color.opacity(0.2) : Color.black.opacity(0.05), 
                        radius: isDragging ? 12 : 8, 
                        y: isDragging ? 6 : 4)
        )
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .onAppear {
            if animated {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
    
    private func getYDomain() -> ClosedRange<Double> {
        if let range = range {
            return range.min...range.max
        }
        
        let values = data.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        let padding = (maxValue - minValue) * 0.1
        
        return (minValue - padding)...(maxValue + padding)
    }
    
    private func getValueColor(_ value: Double) -> Color {
        guard let range = range else { return color }
        
        if let criticalMin = range.criticalMin, value < criticalMin {
            return .red
        }
        if let criticalMax = range.criticalMax, value > criticalMax {
            return .red
        }
        if let normalMin = range.normalMin, value < normalMin {
            return .orange
        }
        if let normalMax = range.normalMax, value > normalMax {
            return .orange
        }
        
        return .green
    }
    
    private var averageValue: Double {
        guard !data.isEmpty else { return 0 }
        return data.map { $0.value }.reduce(0, +) / Double(data.count)
    }
}

// MARK: - ECG Waveform View

struct ECGWaveformView: View {
    let samples: [Double]
    let samplingRate: Int
    let color: Color
    
    @State private var currentIndex: Int = 0
    @State private var timer: Timer?
    
    init(samples: [Double], samplingRate: Int = 500, color: Color = .green) {
        self.samples = samples
        self.samplingRate = samplingRate
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !samples.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let midY = height / 2
                
                // Normalize samples to fit in view
                let maxAmplitude = samples.map { abs($0) }.max() ?? 1.0
                let scale = (height * 0.4) / maxAmplitude
                
                // Calculate x step based on visible samples
                let visibleSamples = min(samples.count, samplingRate * 3) // Show 3 seconds
                let xStep = width / CGFloat(visibleSamples)
                
                // Draw waveform
                for (index, sample) in samples.prefix(currentIndex).enumerated() {
                    let x = CGFloat(index) * xStep
                    let y = midY - (CGFloat(sample) * scale)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 2)
            
            // Grid overlay
            Path { path in
                let gridSpacing: CGFloat = 20
                
                // Vertical grid lines
                stride(from: 0, to: geometry.size.width, by: gridSpacing).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                // Horizontal grid lines
                stride(from: 0, to: geometry.size.height, by: gridSpacing).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        }
        .frame(height: 150)
        .background(Color.black)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(samplingRate), repeats: true) { _ in
            if currentIndex < samples.count {
                currentIndex += 1
            } else {
                currentIndex = 0 // Loop animation
            }
        }
    }
}

// MARK: - Using SparklineView from Components folder

// MARK: - Preview Provider

struct HealthChartView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Blood Pressure Chart
            HealthChartView(
                title: "Blood Pressure",
                data: generateSampleData(count: 24, baseValue: 120, variation: 15),
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
                color: .red
            )
            
            // Heart Rate Chart
            HealthChartView(
                title: "Heart Rate",
                data: generateSampleData(count: 50, baseValue: 75, variation: 10),
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
                color: .pink
            )
            
            // SpO2 Chart
            HealthChartView(
                title: "SpO2",
                data: generateSampleData(count: 30, baseValue: 97, variation: 2),
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
                color: .blue
            )
        }
        .padding()
    }
    
    static func generateSampleData(count: Int, baseValue: Double, variation: Double) -> [ChartDataPoint] {
        let now = Date()
        return (0..<count).map { i in
            let timestamp = now.addingTimeInterval(Double(i - count) * 60)
            let value = baseValue + Double.random(in: -variation...variation)
            return ChartDataPoint(timestamp: timestamp, value: value)
        }
    }
}