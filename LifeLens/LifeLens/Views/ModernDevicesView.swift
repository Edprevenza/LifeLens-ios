//
//  ModernDevicesView.swift
//  LifeLens
//
//  Production-ready Devices view
//

import SwiftUI

struct ModernDevicesView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    
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
                    // Logo at the top
                    LifeLensLogo(size: .small, style: .standalone)
                        .padding(.top, 20)
                    
                    // Header
                    DevicesHeader()
                        .padding(.horizontal, 50)
                        .padding(.top, 10)
                    
                    // Connection Status
                    ConnectionStatusSection()
                        .padding(.horizontal, 50)
                        .frame(maxWidth: 1400)
                    
                    // Device Management
                    DeviceManagementSection()
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

struct DevicesHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Connected Devices")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Manage your LifeLens wearable devices")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Sync Button
            Button(action: {}) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Sync")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }
}

struct ConnectionStatusSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Connection Status")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            // Status Card
            HStack(spacing: 20) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("LifeLens Pro Connected")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Signal strength: Strong • Battery: 85%")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("Online")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct DeviceManagementSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Device Management")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                DeviceActionCard(
                    icon: "gear",
                    title: "Device Settings",
                    description: "Configure your device preferences",
                    color: .blue
                )
                
                DeviceActionCard(
                    icon: "arrow.down.circle",
                    title: "Firmware Update",
                    description: "Keep your device up to date",
                    color: .orange
                )
                
                DeviceActionCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Calibration",
                    description: "Ensure accurate readings",
                    color: .purple
                )
                
                DeviceActionCard(
                    icon: "exclamationmark.triangle",
                    title: "Troubleshooting",
                    description: "Resolve connection issues",
                    color: .red
                )
            }
        }
    }
}

struct DeviceActionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .frame(height: 140)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ModernDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        ModernDevicesView()
    }
}