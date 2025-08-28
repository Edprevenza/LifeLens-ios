//
//  SensorReadingsView.swift
//  LifeLens
//
//  Sensor readings display matching Android design
//

import SwiftUI
import Charts

struct SensorReadingsView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var isLiveMode = true
    
    var body: some View {
        ZStack {
            // Dark background matching Android
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    
                    Text("Sensor Readings")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Text("Live")
                            .font(.system(size: 14))
                            .foregroundColor(isLiveMode ? .green : .gray)
                        
                        Toggle("", isOn: $isLiveMode)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            .scaleEffect(0.8)
                        
                        Text("History")
                            .font(.system(size: 14))
                            .foregroundColor(!isLiveMode ? .white : .gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black)
                
                // Tab Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SensorTabButton(title: "All", isSelected: true)
                        SensorTabButton(title: "ECG", isSelected: false)
                        SensorTabButton(title: "Blood Pressure", isSelected: false)
                        SensorTabButton(title: "Glucose", isSelected: false)
                        SensorTabButton(title: "SpO2", isSelected: false)
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
                        Text("02:19")
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
                        // Temperature Card
                        SensorCard(
                            icon: "thermometer",
                            title: "Temperature",
                            value: "97.7",
                            unit: "°F",
                            status: "Low Reading",
                            confidence: "99%",
                            iconColor: Color.orange
                        )
                        
                        // Recent Readings Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Readings")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                SensorReadingCard(
                                    icon: "thermometer",
                                    title: "Temperature",
                                    value: "97.7°F",
                                    confidence: "99% Confidence",
                                    iconColor: Color.orange
                                )
                                
                                SensorReadingCard(
                                    icon: "drop.fill",
                                    title: "Glucose",
                                    value: "115 mg/dL",
                                    confidence: "97% Confidence",
                                    iconColor: Color.purple
                                )
                                
                                SensorReadingCard(
                                    icon: "waveform.path.ecg",
                                    title: "ECG",
                                    value: "68 BPM",
                                    confidence: "87% Confidence",
                                    iconColor: Color.green
                                )
                                
                                SensorReadingCard(
                                    icon: "heart.fill",
                                    title: "Blood Pressure",
                                    value: "137/75 mmHg",
                                    confidence: "94% Confidence",
                                    iconColor: Color.red
                                )
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
    }
}

// MARK: - Sensor Tab Button
struct SensorTabButton: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(hex: "2a2a2a") : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Sensor Card
struct SensorCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let status: String
    let confidence: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(iconColor)
            
            // Title
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            // Value
            HStack(alignment: .top, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            
            // Status
            Text(status)
                .font(.system(size: 14))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(hex: "1a1a1a"))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

// MARK: - Sensor Reading Card
struct SensorReadingCard: View {
    let icon: String
    let title: String
    let value: String
    let confidence: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Confidence
            Text(confidence)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color(hex: "0f0f0f"))
        .cornerRadius(12)
    }
}