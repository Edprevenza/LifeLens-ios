import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MainTabView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var healthDataManager = HealthDataManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @State private var selectedTab = 0
    @Namespace private var animation
    
    var body: some View {
        ZStack(alignment: .bottom) {
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
            
            // Content - Fill entire available space
            TabView(selection: $selectedTab) {
                HealthDashboardView()
                    .tag(0)
                
                SensorReadingsView()
                    .tag(1)
                
                HealthAlertsView()
                    .tag(2)
                
                ModernDevicesView()
                    .tag(3)
                
                ModernInsightsView()
                    .tag(4)
                
                EnhancedProfileView()
                    .tag(5)
            }
            .tabViewStyle(.automatic)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80) // Fixed space for tab bar
            
            // Fixed Tab Bar at bottom
            VStack {
                Spacer()
                ModernCustomTabBar(selectedTab: $selectedTab, animation: animation)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environmentObject(healthDataManager)
        .environmentObject(locationManager)
        .environmentObject(bluetoothManager)
    }
}

// Modern Custom Tab Bar
struct ModernCustomTabBar: View {
    @Binding var selectedTab: Int
    let animation: Namespace.ID
    
    let tabs = [
        TabItem(icon: "heart.text.square.fill", title: "Dashboard", color: Color.red),
        TabItem(icon: "waveform.path.ecg.rectangle", title: "Readings", color: Color.green),
        TabItem(icon: "exclamationmark.triangle.fill", title: "Alerts", color: Color.orange),
        TabItem(icon: "dot.radiowaves.left.and.right", title: "Devices", color: Color.blue),
        TabItem(icon: "brain.head.profile", title: "Insights", color: Color.purple),
        TabItem(icon: "person.crop.circle.fill", title: "Profile", color: Color.gray)
    ]
    
    var body: some View {
        HStack(spacing: 4) {
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
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    .ultraThinMaterial.opacity(0.9)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
        .frame(maxWidth: 600) // Limit tab bar width
    }
}

struct DashboardView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            MetricCard(
                                title: "Heart Rate",
                                value: "72",
                                unit: "BPM",
                                icon: "heart.fill",
                                color: .red
                            )
                            
                            MetricCard(
                                title: "Steps",
                                value: "8,234",
                                unit: "steps",
                                icon: "figure.walk",
                                color: .green
                            )
                        }
                        
                        HStack(spacing: 16) {
                            MetricCard(
                                title: "Sleep",
                                value: "7.5",
                                unit: "hours",
                                icon: "moon.fill",
                                color: .purple
                            )
                            
                            MetricCard(
                                title: "Calories",
                                value: "1,823",
                                unit: "kcal",
                                icon: "flame.fill",
                                color: .orange
                            )
                        }
                    }
                    .padding()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activities")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(0..<3) { _ in
                            ActivityRow()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "figure.run")
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Morning Run")
                    .font(.headline)
                Text("5.2 km • 32 min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("8:30 AM")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct HealthDataView: View {
    var body: some View {
        NavigationView {
            Text("Health Data View")
                .navigationTitle("Health Data")
        }
    }
}


struct InsightsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Health Insights")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    InsightCard(
                        icon: "moon.fill",
                        title: "Sleep Quality", 
                        insight: "Your sleep quality has improved by 15% this week",
                        trend: .up,
                        color: .purple
                    )
                    
                    InsightCard(
                        icon: "figure.walk",
                        title: "Activity Level",
                        insight: "You've been more active than 80% of similar users", 
                        trend: .up,
                        color: .green
                    )
                    
                    InsightCard(
                        icon: "heart.fill",
                        title: "Heart Health",
                        insight: "Your resting heart rate is within healthy range",
                        trend: .neutral,
                        color: .red
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("Insights")
        }
    }
}

// InsightCard is defined in ModernInsightsView.swift

struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text((authService.currentUser?.firstName.prefix(1) ?? "") + (authService.currentUser?.lastName.prefix(1) ?? ""))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(authService.currentUser?.firstName ?? "") \(authService.currentUser?.lastName ?? "")")
                                .font(.headline)
                            Text(authService.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Settings") {
                    NavigationLink(destination: PersonalInformationView()) {
                        Label("Personal Information", systemImage: "person.fill")
                    }
                    
                    NavigationLink(destination: Text("Privacy")) {
                        Label("Privacy", systemImage: "lock.fill")
                    }
                    
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    
                    NavigationLink(destination: Text("Connected Apps")) {
                        Label("Connected Apps", systemImage: "app.connected.to.app.below.fill")
                    }
                }
                
                Section("Support") {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle.fill")
                    }
                    
                    NavigationLink(destination: Text("About")) {
                        Label("About", systemImage: "info.circle.fill")
                    }
                }
                
                Section {
                    Button(action: {
                        authService.logout()
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}