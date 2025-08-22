// AccessibilityEnhancements.swift
import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    func enhancedAccessibility(
        label: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        isModal: Bool = false,
        sortPriority: Double = 0
    ) -> some View {
        self
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityElement(children: .combine)
            .accessibilitySortPriority(sortPriority)
            .if(isModal) { view in
                view.accessibilityElement(children: .contain)
            }
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func healthMetricAccessibility(
        metric: String,
        value: String,
        unit: String,
        trend: String? = nil,
        status: String? = nil
    ) -> some View {
        let label = "\(metric): \(value) \(unit)"
        let hint = [trend, status].compactMap { $0 }.joined(separator: ". ")
        
        return self
            .enhancedAccessibility(
                label: label,
                hint: hint.isEmpty ? nil : hint,
                traits: .updatesFrequently
            )
    }
    
    func chartAccessibility(
        title: String,
        dataPoints: Int,
        range: String,
        currentValue: String
    ) -> some View {
        let label = "\(title) chart"
        let hint = "\(dataPoints) data points. Range: \(range). Current value: \(currentValue)"
        
        return self
            .enhancedAccessibility(
                label: label,
                hint: hint,
                traits: .allowsDirectInteraction
            )
    }
    
    func buttonAccessibility(
        title: String,
        action: String,
        isDestructive: Bool = false
    ) -> some View {
        let traits: AccessibilityTraits = [.isButton]
        
        return self
            .enhancedAccessibility(
                label: title,
                hint: "Double tap to \(action)",
                traits: traits
            )
    }
}

// MARK: - Accessibility Manager

class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var isVoiceOverRunning = false
    @Published var isReduceMotionEnabled = false
    @Published var isReduceTransparencyEnabled = false
    @Published var isBoldTextEnabled = false
    @Published var isLargerTextEnabled = false
    @Published var preferredTextSize: CGFloat = 17.0
    
    private init() {
        setupAccessibilityObservers()
        updateAccessibilitySettings()
    }
    
    private func setupAccessibilityObservers() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAccessibilitySettings()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAccessibilitySettings()
        }
    }
    
    private func updateAccessibilitySettings() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        #if canImport(UIKit)
        isLargerTextEnabled = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        #else
        isLargerTextEnabled = false
        #endif
        preferredTextSize = UIFont.preferredFont(forTextStyle: .body).pointSize
    }
    
    func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    func announceHealthAlert(_ alert: String) {
        let announcement = "Health Alert: \(alert)"
        announce(announcement)
    }
    
    func announceMetricChange(_ metric: String, value: String, trend: String) {
        let announcement = "\(metric) changed to \(value). \(trend)"
        announce(announcement)
    }
}

// MARK: - Accessible Health Components

struct AccessibleHealthCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: String?
    let status: String?
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let status = status {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(color)
                        .accessibilityHidden(true)
                }
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                
                if let trend = trend {
                    Text(trend)
                        .font(.caption)
                        .foregroundColor(color)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .healthMetricAccessibility(
            metric: title,
            value: value,
            unit: unit,
            trend: trend,
            status: status
        )
    }
}

struct AccessibleChartView: View {
    let title: String
    let dataPoints: [ChartDataPoint]
    let currentValue: String
    let range: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Chart placeholder - in real implementation, this would be your actual chart
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .overlay(
                    Text("Chart visualization")
                        .foregroundColor(.secondary)
                )
                .chartAccessibility(
                    title: title,
                    dataPoints: dataPoints.count,
                    range: range,
                    currentValue: currentValue
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct AccessibleTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == index ? tabs[index].color : .gray)
                        
                        Text(tabs[index].title)
                            .font(.caption)
                            .foregroundColor(selectedTab == index ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonAccessibility(
                    title: tabs[index].title,
                    action: "navigate to \(tabs[index].title) tab"
                )
                .accessibilityValue(selectedTab == index ? "Selected" : "Not selected")
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

// MARK: - Accessibility-Friendly Animations

extension Animation {
    static var accessibleSpring: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .linear(duration: 0)
        } else {
            return .spring(response: 0.5, dampingFraction: 0.8)
        }
    }
    
    static var accessibleEaseInOut: Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .linear(duration: 0)
        } else {
            return .easeInOut(duration: 0.3)
        }
    }
}

// MARK: - Accessibility-Friendly Colors

extension Color {
    static var accessiblePrimary: Color {
        if UIAccessibility.isReduceTransparencyEnabled {
            return .primary
        } else {
            return .primary.opacity(0.9)
        }
    }
    
    static var accessibleBackground: Color {
        if UIAccessibility.isReduceTransparencyEnabled {
            return Color(.systemBackground)
        } else {
            return Color(.systemBackground).opacity(0.95)
        }
    }
}

// MARK: - Accessibility-Friendly Text

extension Text {
    func accessibleFont(_ style: Font.TextStyle = .body) -> some View {
        self.font(.system(style, design: .default))
            .dynamicTypeSize(.large ... .accessibility3)
    }
    
    func accessibleBold() -> some View {
        if UIAccessibility.isBoldTextEnabled {
            return self.fontWeight(.bold)
        } else {
            return self.fontWeight(.semibold)
        }
    }
}

// MARK: - Accessibility Testing Helper

struct AccessibilityTestingView: View {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Accessibility Settings")
                .font(.title)
                .accessibleFont(.title)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("VoiceOver: \(accessibilityManager.isVoiceOverRunning ? "On" : "Off")")
                Text("Reduce Motion: \(accessibilityManager.isReduceMotionEnabled ? "On" : "Off")")
                Text("Reduce Transparency: \(accessibilityManager.isReduceTransparencyEnabled ? "On" : "Off")")
                Text("Bold Text: \(accessibilityManager.isBoldTextEnabled ? "On" : "Off")")
                Text("Larger Text: \(accessibilityManager.isLargerTextEnabled ? "On" : "Off")")
                Text("Text Size: \(String(format: "%.1f", accessibilityManager.preferredTextSize))")
            }
            .font(.body)
            
            Button("Test Announcement") {
                accessibilityManager.announce("This is a test announcement for accessibility testing")
            }
            .buttonAccessibility(title: "Test Announcement", action: "test voice announcement")
            
            Button("Test Health Alert") {
                accessibilityManager.announceHealthAlert("Heart rate is elevated")
            }
            .buttonAccessibility(title: "Test Health Alert", action: "test health alert announcement")
        }
        .padding()
    }
}
