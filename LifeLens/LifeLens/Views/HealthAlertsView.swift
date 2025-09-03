//
//  AlertsView.swift
//  LifeLens
//
//  Real-time health alerts and notifications view
//

import SwiftUI

struct HealthAlertsView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    private let apiService = APIService.shared
    @State private var selectedFilter: AlertFilter = .all
    @State private var alerts: [HealthAlert] = []
    @State private var isRefreshing = false
    @State private var cancellables = Set<AnyCancellable>()
    
    enum AlertFilter: String, CaseIterable {
        case all = "All"
        case critical = "Critical"
        case warnings = "Warnings"
        case resolved = "Resolved"
        
        var icon: String {
            switch self {
            case .all: return "bell.fill"
            case .critical: return "exclamationmark.octagon.fill"
            case .warnings: return "exclamationmark.triangle.fill"
            case .resolved: return "checkmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .critical: return .red
            case .warnings: return .orange
            case .resolved: return .green
            }
        }
    }
    
    var filteredAlerts: [HealthAlert] {
        switch selectedFilter {
        case .all:
            return alerts
        case .critical:
            return alerts.filter { $0.severity == .critical }
        case .warnings:
            return alerts.filter { $0.severity == .high || $0.severity == .medium }
        case .resolved:
            return [] // Would track resolved alerts
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
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Logo at the top
                LifeLensLogo(size: .small, style: .standalone)
                    .padding(.top, 20)
                
                // Header
                AlertsHeader(alertCount: filteredAlerts.count)
                    .padding(.horizontal, 50)
                    .padding(.top, 10)
                
                // Emergency Banner (if needed)
                if hasEmergencyAlert() {
                    EmergencyBanner()
                        .padding(.horizontal, 50)
                        .padding(.top, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(AlertFilter.allCases, id: \.self) { filter in
                            FilterTab(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                count: getCount(for: filter),
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedFilter = filter
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 50)
                }
                .padding(.vertical, 24)
                .frame(height: 90)
                
                // Alerts List
                if filteredAlerts.isEmpty {
                    EmptyAlertsView(filter: selectedFilter)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredAlerts) { alert in
                                AlertCard(alert: alert)
                                    .padding(.horizontal, 50)
                                    .frame(maxWidth: 1000)
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadAlerts()
            startMockAlerts() // For demo purposes
        }
    }
    
    private func hasEmergencyAlert() -> Bool {
        return filteredAlerts.contains { $0.severity == .critical }
    }
    
    private func getCount(for filter: AlertFilter) -> Int {
        switch filter {
        case .all:
            return alerts.count
        case .critical:
            return alerts.filter { $0.severity == .critical }.count
        case .warnings:
            return alerts.filter { $0.severity == .high || $0.severity == .medium }.count
        case .resolved:
            return 0
        }
    }
    
    private func loadAlerts() {
        // Load from API
        // For now, just use local alerts from Bluetooth
        alerts = bluetoothManager.currentAlerts
    }
    
    // Mock alerts for demo
    private func startMockAlerts() {
        alerts = [
            HealthAlert(
                id: UUID(),
                title: "Irregular Heart Rhythm Detected",
                message: "Your heart rhythm shows signs of atrial fibrillation. Consider consulting your healthcare provider.",
                type: .emergency,
                severity: .critical,
                timestamp: Date().addingTimeInterval(-300),
                source: "ECG Monitor",
                isRead: false,
                actionRequired: true
            ),
            HealthAlert(
                id: UUID(),
                title: "Low Blood Sugar Warning",
                message: "Glucose level at 68 mg/dL. Consider having a snack.",
                type: .warning,
                severity: .medium,
                timestamp: Date().addingTimeInterval(-1800),
                source: "Glucose Monitor",
                isRead: false,
                actionRequired: false
            ),
            HealthAlert(
                id: UUID(),
                title: "Elevated Blood Pressure",
                message: "Blood pressure reading: 145/92 mmHg. Monitor closely.",
                type: .warning,
                severity: .high,
                timestamp: Date().addingTimeInterval(-3600),
                source: "BP Monitor",
                isRead: false,
                actionRequired: true
            ),
            HealthAlert(
                id: UUID(),
                title: "Daily Health Summary Ready",
                message: "Your health metrics for today have been analyzed.",
                type: .notification,
                severity: .info,
                timestamp: Date().addingTimeInterval(-7200),
                source: "Health Analytics",
                isRead: false,
                actionRequired: false
            )
        ]
    }
}

// MARK: - Components

struct AlertsHeader: View {
    let alertCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Health Alerts")
                    .font(.system(size: 28, weight: .bold))
                    
            .foregroundColor(.white)
                
                Text("\(alertCount) active alert\(alertCount == 1 ? "" : "s")")
                    .font(.system(size: 14))
                    
            .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Refresh Button
            Button(action: {}) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20))
                    
            .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}

struct EmergencyBanner: View {
    @State private var isFlashing = false
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 24))
                
            .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("EMERGENCY ALERT")
                    .font(.system(size: 14, weight: .bold))
                    
            .foregroundColor(.white)
                
                Text("Immediate attention required")
                    .font(.system(size: 12))
                    
            .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Call 911")
                    .font(.system(size: 14, weight: .bold))
                    
            .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red,
                            Color.red.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isFlashing ? 0.9 : 1.0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .red.opacity(0.5), radius: 20, x: 0, y: 10)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isFlashing = true
            }
        }
    }
}

struct FilterTab: View {
    let filter: HealthAlertsView.AlertFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        
            .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(filter.color)
                        .cornerRadius(10)
                }
            }
            
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? filter.color.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? filter.color : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AlertCard: View {
    let alert: HealthAlert
    @State private var isExpanded = false
    
    var severityIcon: String {
        switch alert.severity {
        case .critical: return "exclamationmark.octagon.fill"
        case .high: return "exclamationmark.3"
        case .medium: return "exclamationmark.triangle.fill"
        case .low: return "exclamationmark.circle"
        case .info: return "info.circle.fill"
        }
    }
    
    var severityColor: Color {
        switch alert.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        case .info: return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Severity Icon
                ZStack {
                    Circle()
                        .fill(severityColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: severityIcon)
                        .font(.system(size: 20))
                        
            .foregroundColor(severityColor)
                }
                
                // Title and Time
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title)
                        .font(.system(size: 16, weight: .semibold))
                        
            .foregroundColor(.white)
                    
                    Text(timeAgo(from: alert.timestamp))
                        .font(.system(size: 12))
                        
            .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Action Required Badge
                if alert.actionRequired {
                    Text("Action Required")
                        .font(.system(size: 10, weight: .bold))
                        
            .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(6)
                }
            }
            
            // Message
            Text(alert.message)
                .font(.system(size: 14))
                
            .foregroundColor(.white.opacity(0.8))
                .lineLimit(isExpanded ? nil : 2)
            
            // Actions
            if isExpanded {
                HStack(spacing: 12) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Acknowledge")
                                .font(.system(size: 14, weight: .medium))
                        }
                        
            .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Dismiss")
                                .font(.system(size: 14, weight: .medium))
                        }
                        
            .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            
            // Expand/Collapse Button
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    .ultraThinMaterial.opacity(0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    severityColor.opacity(0.3),
                                    severityColor.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: severityColor.opacity(0.2),
            radius: 10,
            x: 0,
            y: 5
        )
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

struct EmptyAlertsView: View {
    let filter: HealthAlertsView.AlertFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                
            .foregroundColor(.green.opacity(0.5))
            
            Text("No \(filter == .all ? "" : filter.rawValue) Alerts")
                .font(.system(size: 20, weight: .semibold))
                
            .foregroundColor(.white)
            
            Text("Your health metrics are within normal ranges")
                .font(.system(size: 14))
                
            .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Import Combine
import Combine

// Preview
struct HealthAlertsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthAlertsView()
    }
}