//
import Foundation
//  HealthDashboardView_Simplified.swift
//  LifeLens
//
//  Simplified version to fix type-checking issues
//

import SwiftUI
import Combine

// MARK: - View Model

// MARK: - Connection Status Component
struct ConnectionStatusView: View {
    let status: String
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status == "Connected" ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
                .overlay(pulseAnimation)
            
            Text(status)
                .font(.caption)
                
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.gray.opacity(0.1)))
        .onAppear { isAnimating = true }
    }
    
    private var pulseAnimation: some View {
        Circle()
            .stroke(status == "Connected" ? Color.green.opacity(0.5) : Color.clear, lineWidth: 8)
            .scaleEffect(isAnimating ? 2 : 1)
            .opacity(isAnimating ? 0 : 1)
            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
    }
}

// MARK: - Dashboard Header Component
struct DashboardHeaderView: View {
    let connectionStatus: String
    
    var body: some View {
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
            
            ConnectionStatusView(status: connectionStatus)
        }
    }
}

// MARK: - ECG Header Component
struct ECGHeaderView: View {
    let heartRate: Int
    let isExpanded: Bool
    let toggleAction: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            Label("ECG Monitor", systemImage: "waveform.path.ecg")
                .font(.headline)
                
            .foregroundColor(.primary)
            
            Spacer()
            
            liveIndicator
            
            expandButton
        }
        .onAppear { isAnimating = true }
    }
    
    private var liveIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .overlay(livePulse)
            
            Text("LIVE")
                .font(.caption)
                .fontWeight(.semibold)
                
            .foregroundColor(.green)
            
            Text("\(heartRate) BPM")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                
            .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(liveBackground)
    }
    
    private var livePulse: some View {
        Circle()
            .stroke(Color.green.opacity(0.5), lineWidth: 8)
            .scaleEffect(isAnimating ? 2 : 1)
            .opacity(isAnimating ? 0 : 1)
            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
    }
    
    private var liveBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.green.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var expandButton: some View {
        Button(action: toggleAction) {
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                
            .foregroundColor(.gray)
                .font(.title3)
        }
    }
}

// MARK: - Vital Card Component
struct VitalCardView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    
            .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    
            .foregroundColor(.secondary)
                
                Spacer()
                
                if let trend = trend {
                    Text(trend)
                        .font(.caption2)
                        
            .foregroundColor(.secondary)
                }
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    
            .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    
            .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(cardBackground)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Alert Banner Component
struct EnhancedAlertBanner: View {
    let alerts: [HealthAlert]
    
    var body: some View {
        if !alerts.isEmpty {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    
            .foregroundColor(.orange)
                
                Text("\(alerts.count) Active Alert\(alerts.count > 1 ? "s" : "")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    
            .foregroundColor(.secondary)
            }
            .padding()
            .background(alertBackground)
        }
    }
    
    private var alertBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.orange.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Simplified Main Dashboard View
struct HealthDashboardView: View {
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var ecgExpanded = false
    @State private var showingAlerts = false
    @State private var contentLoaded = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        headerSection
                        
                        if !viewModel.currentAlerts.isEmpty {
                            alertSection
                        }
                        
                        if contentLoaded {
                            ecgSection
                            vitalsGrid
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    contentLoaded = true
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        DashboardHeaderView(connectionStatus: viewModel.connectionStatus)
    }
    
    private var alertSection: some View {
        EnhancedAlertBanner(alerts: viewModel.currentAlerts)
            .onTapGesture {
                withAnimation(.spring()) {
                    showingAlerts = true
                }
            }
    }
    
    private var ecgSection: some View {
        VStack(spacing: 0) {
            ECGHeaderView(
                heartRate: viewModel.currentHeartRate,
                isExpanded: ecgExpanded,
                toggleAction: {
                    withAnimation(.spring()) {
                        ecgExpanded.toggle()
                    }
                }
            )
            .padding()
            
            if ecgExpanded {
                SimplifiedECGWaveformView(samples: viewModel.ecgSamples)
                    .frame(height: 150)
                    .padding(.horizontal)
            }
        }
        .background(sectionBackground)
    }
    
    private var vitalsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            VitalCardView(
                title: "Blood Pressure",
                value: "\(viewModel.currentBP.systolic)/\(viewModel.currentBP.diastolic)",
                unit: "mmHg",
                icon: "heart.fill",
                color: .red,
                trend: "↓ 2%"
            )
            
            VitalCardView(
                title: "Glucose",
                value: String(format: "%.0f", viewModel.currentGlucose),
                unit: "mg/dL",
                icon: "drop.fill",
                color: .orange,
                trend: "→ Stable"
            )
            
            VitalCardView(
                title: "SpO2",
                value: "\(viewModel.currentSpO2)",
                unit: "%",
                icon: "lungs.fill",
                color: .blue,
                trend: "↑ 1%"
            )
            
            VitalCardView(
                title: "Troponin I",
                value: String(format: "%.3f", viewModel.currentTroponin.i),
                unit: "ng/mL",
                icon: "waveform.path",
                color: .purple,
                trend: "Normal"
            )
        }
    }
    
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - ECG Waveform View (Simplified)
struct SimplifiedECGWaveformView: View {
    let samples: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard samples.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(samples.count - 1)
                
                path.move(to: CGPoint(x: 0, y: height / 2))
                
                for (index, sample) in samples.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height / 2 - (CGFloat(sample) * height / 2)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.green, lineWidth: 2)
        }
        .background(Color.black.opacity(0.02))
        .cornerRadius(8)
    }
}

// MARK: - Models
// Using ChartDataPoint from APIService.swift

// Helper functions
func adaptiveSpacing(for size: CGSize) -> CGFloat {
    size.width > 768 ? 24 : 16
}

func adaptivePadding(for size: CGSize) -> CGFloat {
    size.width > 768 ? 24 : 16
}