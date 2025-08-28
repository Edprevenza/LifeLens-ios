// DashboardComponents.swift
// Modular components for the health dashboard

import SwiftUI
import Charts

// MARK: - Vital Stats Grid Component

struct VitalStatsGrid: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    @State private var selectedMetric: String? = nil
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            VitalStatCard(
                title: "Heart Rate",
                value: "\(viewModel.currentHeartRate)",
                unit: "BPM",
                icon: "heart.fill",
                color: .pink,
                trend: 0.0, // viewModel.heartRateTrend,
                sparklineData: viewModel.heartRateData.suffix(20).map { $0.value }
            )
            .onTapGesture {
                withAnimation(.spring()) {
                    selectedMetric = selectedMetric == "heartRate" ? nil : "heartRate"
                }
            }
            
            VitalStatCard(
                title: "Blood Pressure",
                value: "\(viewModel.currentBP.systolic)/\(viewModel.currentBP.diastolic)",
                unit: "mmHg",
                icon: "waveform.path.ecg",
                color: .red,
                trend: 0.0, // viewModel.bloodPressureTrend,
                sparklineData: viewModel.bloodPressureData.suffix(20).map { $0.value }
            )
            .onTapGesture {
                withAnimation(.spring()) {
                    selectedMetric = selectedMetric == "bloodPressure" ? nil : "bloodPressure"
                }
            }
            
            VitalStatCard(
                title: "Glucose",
                value: String(format: "%.0f", viewModel.currentGlucose),
                unit: "mg/dL",
                icon: "drop.fill",
                color: .purple,
                trend: 0.0, // viewModel.glucoseTrend,
                sparklineData: viewModel.glucoseData.suffix(20).map { $0.value }
            )
            .onTapGesture {
                withAnimation(.spring()) {
                    selectedMetric = selectedMetric == "glucose" ? nil : "glucose"
                }
            }
            
            VitalStatCard(
                title: "SpO2",
                value: "\(viewModel.currentSpO2)",
                unit: "%",
                icon: "lungs.fill",
                color: .blue,
                trend: 0.0, // viewModel.spo2Trend,
                sparklineData: viewModel.spo2Data.suffix(20).map { $0.value }
            )
            .onTapGesture {
                withAnimation(.spring()) {
                    selectedMetric = selectedMetric == "spo2" ? nil : "spo2"
                }
            }
        }
    }
}

// MARK: - Vital Stat Card

struct VitalStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: Double
    let sparklineData: [Double]
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    
            .foregroundColor(color)
                    .font(.system(size: 20))
                
                Spacer()
                
                TrendIndicator(value: trend)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    
            .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    
            .foregroundColor(.secondary)
            }
            
            MiniSparklineView(data: sparklineData, color: color)
                .frame(height: 30)
            
            Text(title)
                .font(.caption)
                
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Trend Indicator

struct TrendIndicator: View {
    let value: Double
    
    var trendIcon: String {
        if value > 0.1 {
            return "arrow.up.right"
        } else if value < -0.1 {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }
    
    var trendColor: Color {
        if value > 0.1 {
            return .green
        } else if value < -0.1 {
            return .red
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon)
                .font(.caption)
            
            Text("\(abs(value), specifier: "%.1f")%")
                .font(.caption2)
        }
        
            .foregroundColor(trendColor)
    }
}

// MARK: - Mini Sparkline View

struct MiniSparklineView: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            if !data.isEmpty {
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let maxValue = data.max() ?? 1
                    let minValue = data.min() ?? 0
                    let range = maxValue - minValue
                    let step = width / CGFloat(data.count - 1)
                    
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * step
                        let normalizedValue = (value - minValue) / (range == 0 ? 1 : range)
                        let y = height - (normalizedValue * height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 2)
            }
        }
    }
}

// MARK: - ECG Monitor Section
// This now uses the advanced ECG monitor component with animations

struct ECGMonitorSection: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    
    var body: some View {
        // Use the enhanced ECG monitor component with animations that matches Android
        EnhancedECGMonitor()
    }
}

// MARK: - ECG Waveform Display

struct ECGWaveformDisplay: View {
    let samples: [Double]
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid background
                ECGGridBackground()
                
                // Waveform
                if !samples.isEmpty {
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let midY = height / 2
                        let stepX = width / CGFloat(samples.count - 1)
                        
                        for (index, sample) in samples.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = midY - (CGFloat(sample) * height * 0.4)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .trim(from: 0, to: animationProgress)
                    .stroke(Color.green, lineWidth: 2)
                    .shadow(color: .green.opacity(0.5), radius: 2)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - ECG Grid Background

struct ECGGridBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 20
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                var x: CGFloat = 0
                while x <= width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                    x += gridSize
                }
                
                // Horizontal lines
                var y: CGFloat = 0
                while y <= height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                    y += gridSize
                }
            }
            .stroke(Color.red.opacity(0.1), lineWidth: 0.5)
        }
    }
}

// MARK: - ECG Metric Badge

struct ECGMetricBadge: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                
            .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(unit)
                    .font(.caption2)
                    
            .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
        )
    }
}

// MARK: - Live Indicator

struct LiveIndicator: View {
    let isLive: Bool
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isLive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(isLive ? Color.green.opacity(0.5) : Color.clear, lineWidth: 8)
                        .scaleEffect(isAnimating ? 2 : 1)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            isLive ? .easeOut(duration: 1.5).repeatForever(autoreverses: false) : .default,
                            value: isAnimating
                        )
                )
            
            Text(isLive ? "Live" : "Paused")
                .font(.caption)
                .fontWeight(.semibold)
                
            .foregroundColor(isLive ? .green : .gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((isLive ? Color.green : Color.gray).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke((isLive ? Color.green : Color.gray).opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            isAnimating = isLive
        }
    }
}