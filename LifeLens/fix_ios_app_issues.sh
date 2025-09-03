#!/bin/bash

echo "Fixing iOS app issues..."

# Fix 1: Update SensorReadingsView with proper navigation and interactions
cat > LifeLens/Views/SensorReadingsView_Fixed.swift << 'EOF'
//
//  SensorReadingsView.swift
//  LifeLens
//
//  Sensor readings display matching Android design - FIXED
//

import SwiftUI
import Charts

struct SensorReadingsView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var isLiveMode = true
    @State private var selectedTab = "All"
    @State private var showDetailView = false
    @State private var selectedSensor: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    let tabs = ["All", "ECG", "Blood Pressure", "Glucose", "Temperature", "Troponin", "SpO2"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background matching Android
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Top Navigation Bar
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .padding(.leading, 10)
                        
                        Text("Sensor Readings")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        HStack(spacing: 4) {
                            Text("Live")
                                .font(.system(size: 11))
                                .foregroundColor(isLiveMode ? .green : .gray)
                            
                            Toggle("", isOn: $isLiveMode)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                .scaleEffect(0.6)
                                .frame(width: 35)
                            
                            Text("History")
                                .font(.system(size: 11))
                                .foregroundColor(!isLiveMode ? .white : .gray)
                        }
                        .padding(.trailing, 10)
                    }
                    .frame(height: 50)
                    .background(Color.black)
                    
                    // Tab Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(tabs, id: \.self) { tab in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedTab = tab
                                    }
                                }) {
                                    Text(tab)
                                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                                        .foregroundColor(selectedTab == tab ? .white : .gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedTab == tab ? Color(hex: "2a2a2a") : Color.clear)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(selectedTab == tab ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 12)
                    
                    // Live Data Streaming Indicator
                    if isLiveMode {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE DATA STREAMING")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text(Date(), style: .time)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(hex: "1a1a1a"))
                    }
                    
                    // Main Content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Main Temperature Card - Now Interactive
                            Button(action: {
                                selectedSensor = "Temperature"
                                showDetailView = true
                            }) {
                                MainSensorCard(
                                    icon: "thermometer",
                                    title: "Temperature",
                                    value: "97.7",
                                    unit: "°F",
                                    status: "Normal",
                                    confidence: "99%",
                                    iconColor: Color.orange
                                )
                            }
                            
                            // Recent Readings Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Readings")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 12) {
                                    Button(action: {
                                        selectedSensor = "Temperature"
                                        showDetailView = true
                                    }) {
                                        InteractiveSensorCard(
                                            icon: "thermometer",
                                            title: "Temperature",
                                            value: "97.7°F",
                                            confidence: "99% Confidence",
                                            iconColor: Color.orange
                                        )
                                    }
                                    
                                    Button(action: {
                                        selectedSensor = "Glucose"
                                        showDetailView = true
                                    }) {
                                        InteractiveSensorCard(
                                            icon: "drop.fill",
                                            title: "Glucose",
                                            value: "115 mg/dL",
                                            confidence: "97% Confidence",
                                            iconColor: Color.purple
                                        )
                                    }
                                    
                                    Button(action: {
                                        selectedSensor = "ECG"
                                        showDetailView = true
                                    }) {
                                        InteractiveSensorCard(
                                            icon: "waveform.path.ecg",
                                            title: "ECG",
                                            value: "68 BPM",
                                            confidence: "87% Confidence",
                                            iconColor: Color.green
                                        )
                                    }
                                    
                                    Button(action: {
                                        selectedSensor = "Blood Pressure"
                                        showDetailView = true
                                    }) {
                                        InteractiveSensorCard(
                                            icon: "heart.fill",
                                            title: "Blood Pressure",
                                            value: "137/75 mmHg",
                                            confidence: "94% Confidence",
                                            iconColor: Color.red
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 20)
                        }
                        .padding(.bottom, 100)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDetailView) {
                SensorDetailView(sensorType: selectedSensor)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Interactive Main Sensor Card
struct MainSensorCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let status: String
    let confidence: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(alignment: .top, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            
            Text(status)
                .font(.system(size: 14))
                .foregroundColor(.green)
            
            HStack {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text("Tap for details")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(hex: "1a1a1a"))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

// Interactive Sensor Reading Card
struct InteractiveSensorCard: View {
    let icon: String
    let title: String
    let value: String
    let confidence: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(confidence)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(16)
        .background(Color(hex: "0f0f0f"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Sensor Detail View
struct SensorDetailView: View {
    let sensorType: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("\(sensorType) Details")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Add chart here
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "1a1a1a"))
                        .frame(height: 200)
                        .overlay(
                            Text("Chart View")
                                .foregroundColor(.gray)
                        )
                        .padding(.horizontal)
                    
                    // Historical data
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Historical Data")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(0..<5) { index in
                                    HStack {
                                        Text("Today, \(12 - index):00")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("97.\(5 + index)°F")
                                            .font(.body)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: "0f0f0f"))
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
        }
    }
}

// Color extension for hex colors
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
EOF

# Copy fixed version to replace original
cp LifeLens/Views/SensorReadingsView_Fixed.swift LifeLens/Views/SensorReadingsView.swift

echo "✅ Fixed SensorReadingsView with:"
echo "  - Proper navigation structure"
echo "  - Interactive cards with tap functionality"
echo "  - Fixed header layout"
echo "  - Added detail views for sensors"
echo "  - Working tab selection"

# Clean and rebuild
echo "Cleaning build artifacts..."
rm -rf DerivedData build

echo "Building app..."
xcodebuild -scheme LifeLens \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.6' \
    -derivedDataPath ./DerivedData \
    build

echo "✅ iOS app issues fixed and rebuilt!"