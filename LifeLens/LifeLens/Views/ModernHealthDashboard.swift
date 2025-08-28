//
//  ModernHealthDashboard.swift
//  LifeLens
//
//  Health Dashboard matching Android version with all features
//

import SwiftUI
import Charts

// MARK: - Modern Health Dashboard View
struct ModernHealthDashboard: View {
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var showingAlert = true
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Content based on selected tab
            Group {
                switch selectedTab {
                case 0:
                    dashboardContent
                case 1:
                    SensorReadingsView()
                case 2:
                    HealthAlertsView()
                case 3:
                    ModernDevicesView()
                case 4:
                    ModernInsightsView()
                case 5:
                    ModernProfileView()
                default:
                    dashboardContent
                }
            }
            
            // Bottom Tab Bar overlay
            VStack {
                Spacer()
                bottomTabBar
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var dashboardContent: some View {
        ZStack {
            // Dark background exactly like Android
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("Health Dashboard")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                            Text("Disconnected")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Blood Pressure Alert
                        if showingAlert {
                            bloodPressureAlert
                                .padding(.horizontal, 20)
                        }
                        
                        // ECG Monitor Section
                        ecgMonitorSection
                            .padding(.horizontal, 20)
                        
                        // Vital Signs Grid
                        vitalSignsGrid
                            .padding(.horizontal, 20)
                        
                        // Recent Trends
                        recentTrendsSection
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100)
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Top Status Bar
    private var topStatusBar: some View {
        HStack {
            Text("9:14")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
            }
            .font(.system(size: 14))
            .foregroundColor(.white)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Blood Pressure Alert
    private var bloodPressureAlert: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Blood Pressure Alert")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("Blood pressure above normal range")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Button(action: { withAnimation { showingAlert = false } }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FFB26B")]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
    }
    
    // MARK: - ECG Monitor Section
    private var ecgMonitorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(Color.red)
                    .font(.system(size: 16))
                Text("ECG Monitor")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text("\(viewModel.heartRate)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text("BPM")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Live")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            // ECG Waveform
            ECGWaveformView()
                .frame(height: 100)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
        .background(Color(hex: "1a1a1a"))
        .cornerRadius(12)
    }
    
    // MARK: - Vital Signs Grid
    private var vitalSignsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            // Heart Rate
            VitalSignCard(
                icon: "heart.fill",
                value: "74",
                unit: "BPM",
                label: "",
                color: Color.red,
                trend: .stable
            )
            
            // SpO2
            VitalSignCard(
                icon: "drop.fill",
                value: "98",
                unit: "%",
                label: "SpO2",
                color: Color.blue,
                trend: .stable
            )
            
            // Blood Pressure
            VitalSignCard(
                icon: "heart.text.square",
                value: "140/90",
                unit: "mmHg",
                label: "",
                color: Color.orange,
                trend: .up
            )
            
            // Glucose
            VitalSignCard(
                icon: "drop.triangle.fill",
                value: "112",
                unit: "mg/dL",
                label: "Glucose",
                color: Color.purple,
                trend: .stable
            )
        }
    }
    
    // MARK: - Recent Trends Section
    private var recentTrendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Trends")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    Text("Blood Pressure")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("Heart Rate")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("Activity")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("Sleep")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("Profile")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            
            // Simple trend visualization
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<20) { index in
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.6)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 12, height: CGFloat.random(in: 20...60))
                        .cornerRadius(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(hex: "1a1a1a"))
        .cornerRadius(12)
    }
    
    // MARK: - Bottom Tab Bar
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "house.fill", label: "Dashboard", isSelected: selectedTab == 0, color: selectedTab == 0 ? Color.red : Color.gray) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 0
                }
            }
            TabBarItem(icon: "chart.line.uptrend.xyaxis", label: "Readings", isSelected: selectedTab == 1, color: selectedTab == 1 ? Color.red : Color.gray) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 1
                }
            }
            TabBarItem(icon: "bell.fill", label: "Alerts", isSelected: selectedTab == 2, color: selectedTab == 2 ? Color.red : Color.gray) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 2
                }
            }
            TabBarItem(icon: "antenna.radiowaves.left.and.right", label: "Devices", isSelected: selectedTab == 3, color: selectedTab == 3 ? Color.red : Color.gray) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 3
                }
            }
            TabBarItem(icon: "brain.head.profile", label: "Insights", isSelected: selectedTab == 4, color: selectedTab == 4 ? Color.red : Color.gray) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 4
                }
            }
            TabBarItem(icon: "person.fill", label: "Profile", isSelected: selectedTab == 5, color: selectedTab == 5 ? Color.red : Color.gray) {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = 5
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.bottom, 20)
        .background(Color.black)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

// MARK: - ECG Waveform View
struct ECGWaveformView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midY = height / 2
                
                path.move(to: CGPoint(x: 0, y: midY))
                
                for x in stride(from: 0, to: width, by: 2) {
                    let relativeX = x / width
                    let offsetX = (relativeX + phase).truncatingRemainder(dividingBy: 1)
                    
                    // Create ECG-like waveform
                    let y: CGFloat
                    if offsetX < 0.1 {
                        y = midY
                    } else if offsetX < 0.15 {
                        y = midY - height * 0.1
                    } else if offsetX < 0.2 {
                        y = midY - height * 0.4 // P wave
                    } else if offsetX < 0.25 {
                        y = midY
                    } else if offsetX < 0.3 {
                        y = midY + height * 0.1
                    } else if offsetX < 0.35 {
                        y = midY - height * 0.8 // R wave (spike)
                    } else if offsetX < 0.4 {
                        y = midY + height * 0.2 // S wave
                    } else if offsetX < 0.5 {
                        y = midY
                    } else if offsetX < 0.6 {
                        y = midY - height * 0.2 // T wave
                    } else {
                        y = midY
                    }
                    
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.green, lineWidth: 2)
            .shadow(color: Color.green.opacity(0.5), radius: 4)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// MARK: - Vital Sign Card
struct VitalSignCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color
    let trend: TrendDirection
    
    enum TrendDirection {
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
            case .up: return .red
            case .down: return .green
            case .stable: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.bottom, 2)
            }
            
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1a1a1a"))
        .cornerRadius(10)
    }
}

// MARK: - Trend Chart View
struct TrendChartView: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard data.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let maxValue = data.max() ?? 1
                let minValue = data.min() ?? 0
                let range = maxValue - minValue
                
                for (index, value) in data.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(data.count - 1)
                    let y = height - (height * CGFloat(value - minValue) / CGFloat(range))
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "ff6b35"), Color(hex: "f7931e")]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
            
            // Add gradient fill
            Path { path in
                guard data.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let maxValue = data.max() ?? 1
                let minValue = data.min() ?? 0
                let range = maxValue - minValue
                
                path.move(to: CGPoint(x: 0, y: height))
                
                for (index, value) in data.enumerated() {
                    let x = width * CGFloat(index) / CGFloat(data.count - 1)
                    let y = height - (height * CGFloat(value - minValue) / CGFloat(range))
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "ff6b35").opacity(0.3),
                        Color(hex: "f7931e").opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 9))
            }
            .foregroundColor(isSelected ? color : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct ModernHealthDashboard_Previews: PreviewProvider {
    static var previews: some View {
        ModernHealthDashboard()
    }
}