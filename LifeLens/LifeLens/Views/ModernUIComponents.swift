//
import Foundation
//  ModernUIComponents.swift
//  LifeLens
//
//  Production-ready UI components
//

import SwiftUI
import Charts

// Main Health Chart
struct MainHealthChart: View {
    let metric: ModernDashboardView.HealthMetric
    @ObservedObject var viewModel: HealthDashboardViewModel
    
    var chartData: [ChartDataPoint] {
        switch metric {
        case .heartRate:
            return viewModel.heartRateData
        case .bloodPressure:
            return viewModel.bloodPressureData
        case .glucose:
            return viewModel.glucoseData
        case .spo2:
            return viewModel.spo2Data
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(metric.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                    
            .foregroundColor(.white)
                
                Spacer()
                
                Text("Last 24 Hours")
                    .font(.system(size: 12, weight: .medium))
                    
            .foregroundColor(.gray)
            }
            
            // Chart Container
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        .ultraThinMaterial.opacity(0.2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.03)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: metric.color.opacity(0.1),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
                
                if chartData.isEmpty {
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            
            .foregroundColor(.gray.opacity(0.3))
                        Text("No data available")
                            .font(.system(size: 14))
                            
            .foregroundColor(.gray.opacity(0.5))
                    }
                    .frame(height: 220)
                } else {
                    Chart(chartData) { point in
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    metric.color.opacity(0.3),
                                    metric.color.opacity(0.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(metric.color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 220)
                    .padding(20)
                    .chartXAxis {
                        AxisMarks(preset: .aligned) { _ in
                            AxisValueLabel(format: .dateTime.hour())
                                .foregroundStyle(Color.gray)
                                .font(.system(size: 10))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(Color.gray)
                                .font(.system(size: 10))
                            AxisGridLine()
                                .foregroundStyle(Color.white.opacity(0.05))
                        }
                    }
                }
            }
        }
    }
}

// Recent Readings Section
struct RecentReadingsSection: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Readings")
                    .font(.system(size: 18, weight: .semibold))
                    
            .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Text("View All")
                        .font(.system(size: 12, weight: .medium))
                        
            .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 12) {
                RecentReadingCard(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    value: "\(viewModel.currentHeartRate) BPM",
                    time: "2 min ago",
                    trend: .up,
                    color: .red
                )
                
                RecentReadingCard(
                    icon: "waveform.path.ecg",
                    title: "Blood Pressure",
                    value: "\(viewModel.currentBP.systolic)/\(viewModel.currentBP.diastolic)",
                    time: "5 min ago",
                    trend: .stable,
                    color: .pink
                )
                
                RecentReadingCard(
                    icon: "drop.fill",
                    title: "Glucose",
                    value: String(format: "%.0f mg/dL", viewModel.currentGlucose),
                    time: "15 min ago",
                    trend: .down,
                    color: .purple
                )
            }
        }
    }
}

struct RecentReadingCard: View {
    let icon: String
    let title: String
    let value: String
    let time: String
    let trend: Trend
    let color: Color
    
    enum Trend {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .orange
            case .down: return .green
            case .stable: return .blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    
            .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    
            .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    Text(value)
                        .font(.system(size: 16, weight: .semibold))
                        
            .foregroundColor(.white)
                    
                    Image(systemName: trend.icon)
                        .font(.system(size: 12, weight: .medium))
                        
            .foregroundColor(trend.color)
                }
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 11))
                
            .foregroundColor(.gray.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

// Quick Actions Grid
struct QuickActionsGrid: View {
    let actions = [
        QuickAction(icon: "waveform.path.ecg.rectangle", title: "ECG Test", color: .red),
        QuickAction(icon: "drop.triangle.fill", title: "Blood Test", color: .purple),
        QuickAction(icon: "lungs.fill", title: "Breathing", color: .blue),
        QuickAction(icon: "pills.fill", title: "Medication", color: .green)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                
            .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(actions, id: \.title) { action in
                    QuickActionCard(action: action)
                }
            }
        }
    }
}

struct QuickAction {
    let icon: String
    let title: String
    let color: Color
}

struct QuickActionCard: View {
    let action: QuickAction
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.system(size: 28))
                    
            .foregroundColor(action.color)
                
                Text(action.title)
                    .font(.system(size: 14, weight: .medium))
                    
            .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                action.color.opacity(0.15),
                                action.color.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(action.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ModernDevicesView and related structs are defined in ModernDevicesView.swift

// Continue with more views...