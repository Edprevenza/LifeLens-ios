//
//  MainAppView.swift
//  LifeLens
//
//  Production-ready main app view with enhanced UI
//

import SwiftUI

struct MainAppView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var selectedTab = 0
    @State private var showLaunchScreen = true
    @State private var showingAuthView = false
    @State private var showUnauthorizedAlert = false
    @State private var hasShownUnauthorizedMessage = false
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
            } else if !authService.isAuthenticated {
                // Show authentication view if not logged in
                AuthenticationContainerView()
                    .environmentObject(authService)
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        // Show unauthorized alert when user first tries to access the app
                        if !hasShownUnauthorizedMessage && !showLaunchScreen {
                            showUnauthorizedAlert = true
                            hasShownUnauthorizedMessage = true
                        }
                    }
            } else {
                // Show main app only if authenticated
                MainTabContainer(selectedTab: $selectedTab)
                    .environmentObject(authService)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showLaunchScreen = false
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if !isAuthenticated {
                // Reset to dashboard when logging out
                selectedTab = 0
                // Show unauthorized alert when user logs out or session expires
                if hasShownUnauthorizedMessage {
                    showUnauthorizedAlert = true
                }
            }
        }
        .alert("Registration Required", isPresented: $showUnauthorizedAlert) {
            Button("Register Now", role: .none) {
                // User will be taken to registration screen
            }
            Button("Sign In", role: .cancel) {
                // User will be taken to login screen
            }
        } message: {
            Text("Welcome to LifeLens! You must register or sign in to access your personalized health monitoring dashboard. Create a free account to:\n\n• Track vital health metrics\n• Receive real-time health alerts\n• Connect wearable devices\n• Get AI-powered health insights\n• Access your health history\n\nYour health data is encrypted and securely stored.")
        }
    }
}

struct MainTabContainer: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authService: AuthenticationService
    @Namespace private var animation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()
            
            // Content
            TabView(selection: $selectedTab) {
                ResponsiveHealthDashboard()
                    .tag(0)
                
                SensorReadingsView()
                    .tag(1)
                
                HealthAlertsView()
                    .tag(2)
                
                ModernDevicesView()
                    .tag(3)
                
                ModernInsightsView()
                    .tag(4)
                
                ModernProfileView()
                    .tag(5)
            }
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, animation: animation)
        }
    }
}

// Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let animation: Namespace.ID
    
    let tabs = [
        TabItem(icon: "square.grid.2x2", title: "Dashboard", color: Color.blue),
        TabItem(icon: "chart.line.uptrend.xyaxis", title: "Readings", color: Color.green),
        TabItem(icon: "exclamationmark.triangle", title: "Alerts", color: Color.orange),
        TabItem(icon: "antenna.radiowaves.left.and.right", title: "Devices", color: Color.purple),
        TabItem(icon: "brain.head.profile", title: "Insights", color: Color.indigo),
        TabItem(icon: "person.crop.circle", title: "Profile", color: Color.gray)
    ]
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabBarButton(
                    tab: tabs[index],
                    isSelected: selectedTab == index,
                    animation: animation,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Blur background
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

struct TabItem {
    let icon: String
    let title: String
    let color: Color
}

struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(tab.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .matchedGeometryEffect(id: "TabBackground", in: animation)
                    }
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? tab.color : Color.white.opacity(0.5))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(height: 40)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? tab.color : Color.white.opacity(0.5))
                    .lineLimit(1)
            }
            .frame(minWidth: 50, maxWidth: 70)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Modern Dashboard View
struct ModernDashboardView: View {
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var selectedMetric: HealthMetric = .heartRate
    
    enum HealthMetric: String, CaseIterable {
        case heartRate = "Heart Rate"
        case bloodPressure = "Blood Pressure"
        case glucose = "Glucose"
        case spo2 = "SpO2"
        
        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .bloodPressure: return "waveform.path.ecg"
            case .glucose: return "drop.fill"
            case .spo2: return "lungs.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .heartRate: return .red
            case .bloodPressure: return .pink
            case .glucose: return .purple
            case .spo2: return .blue
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
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    DashboardHeader(viewModel: viewModel)
                        .padding(.horizontal, 50)
                        .padding(.top, 30)
                    
                    // Status Card
                    HealthStatusCard(viewModel: viewModel)
                        .padding(.horizontal, 50)
                        .frame(maxWidth: 1400)
                    
                    // Metrics Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(HealthMetric.allCases, id: \.self) { metric in
                                MetricSelectorCard(
                                    metric: metric,
                                    isSelected: selectedMetric == metric,
                                    action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedMetric = metric
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 50)
                    }
                    .frame(height: 120)
                    
                    // Main Chart
                    MainHealthChart(
                        metric: selectedMetric,
                        viewModel: viewModel
                    )
                    .padding(.horizontal, 50)
                    .frame(maxWidth: 1400)
                    .frame(height: 350)
                    
                    // Recent Readings
                    RecentReadingsSection(viewModel: viewModel)
                        .padding(.horizontal, 50)
                        .frame(maxWidth: 1400)
                    
                    // Quick Actions
                    QuickActionsGrid()
                        .padding(.horizontal, 50)
                        .frame(maxWidth: 1400)
                        .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Dashboard Header
struct DashboardHeader: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(getTimeOfDay())")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("Your Health Today")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Notification Bell
            ZStack(alignment: .topTrailing) {
                Button(action: {}) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                if !viewModel.currentAlerts.isEmpty {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .offset(x: -8, y: 8)
                }
            }
        }
    }
    
    func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }
}

// Health Status Card
struct HealthStatusCard: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Overall Health Score", systemImage: "shield.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("92")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("/100")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                    }
                    
                    Text("Excellent")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: 0.92)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                        
                        Text("\(viewModel.currentHeartRate)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("BPM")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Status Pills
            HStack(spacing: 8) {
                StatusPill(text: "Connected", color: .green)
                StatusPill(text: "Monitoring Active", color: .blue)
                if !viewModel.currentAlerts.isEmpty {
                    StatusPill(text: "\(viewModel.currentAlerts.count) Alerts", color: .orange)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .clipShape(Capsule())
    }
}

// Metric Selector Card
struct MetricSelectorCard: View {
    let metric: ModernDashboardView.HealthMetric
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? metric.color.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? metric.color : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Image(systemName: metric.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? metric.color : .gray)
                }
                
                Text(metric.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Continue in next part...