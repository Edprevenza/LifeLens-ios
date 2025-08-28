// View/DevicesView.swift
import SwiftUI
import CoreBluetooth

struct DevicesView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showingDeviceDetails = false
    @State private var selectedDevice: LifeLensDevice?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Connection Status Header
                ConnectionStatusHeader()
                    .environmentObject(bluetoothManager)
                
                // Main Content
                if bluetoothManager.connectedDevice != nil {
                    ConnectedDeviceView()
                        .environmentObject(bluetoothManager)
                } else {
                    AvailableDevicesView()
                        .environmentObject(bluetoothManager)
                }
            }
            .navigationTitle("Devices")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .sheet(item: $selectedDevice) { device in
                DeviceDetailsSheet(device: device)
                    .environmentObject(bluetoothManager)
            }
        }
    }
}

struct ConnectionStatusHeader: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(bluetoothManager.connectionState.displayText)
                    .font(.headline)
                
                Spacer()
                
                if bluetoothManager.connectionState.isActive {
                    Image(systemName: "wifi")
                        
            .foregroundColor(signalColor)
                    Text("\(bluetoothManager.signalStrength) dBm")
                        .font(.caption)
                        
            .foregroundColor(.secondary)
                }
            }
            
            if bluetoothManager.dataStreamActive {
                HStack {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        
            .foregroundColor(.green)
                    Text("Live data streaming")
                        .font(.caption)
                        
            .foregroundColor(.green)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var statusColor: Color {
        switch bluetoothManager.connectionState {
        case .connected, .syncing, .streaming:
            return .green
        case .connecting, .scanning:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
    
    private var signalColor: Color {
        let rssi = bluetoothManager.signalStrength
        if rssi > -60 { return .green }
        else if rssi > -70 { return .yellow }
        else if rssi > -80 { return .orange }
        else { return .red }
    }
}

struct AvailableDevicesView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Scan Button
                VStack(spacing: 16) {
                    Image(systemName: "applewatch.radiowaves.left.and.right")
                        .font(.system(size: 60))
                        
            .foregroundColor(.blue)
                    
                    Text("No LifeLens Device Connected")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Make sure your LifeLens device is nearby and powered on")
                        .font(.body)
                        
            .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        if bluetoothManager.isScanning {
                            bluetoothManager.stopScanning()
                        } else {
                            bluetoothManager.startScanning()
                        }
                    }) {
                        HStack {
                            if bluetoothManager.isScanning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(bluetoothManager.isScanning ? "Scanning..." : "Scan for Devices")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(bluetoothManager.isScanning ? Color.gray : Color.blue)
                        
            .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(bluetoothManager.connectionState == .connecting)
                    .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Discovered Devices
                if !bluetoothManager.discoveredDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Devices")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(bluetoothManager.discoveredDevices) { device in
                            DeviceRow(device: device)
                                .environmentObject(bluetoothManager)
                        }
                    }
                    .padding(.top)
                }
            }
        }
    }
}

struct DeviceRow: View {
    let device: LifeLensDevice
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        Button(action: {
            bluetoothManager.connect(to: device)
        }) {
            HStack {
                Image(systemName: "applewatch")
                    .font(.title2)
                    
            .foregroundColor(.blue)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                        
            .foregroundColor(.primary)
                    
                    Text("SN: \(String(device.serialNumber.prefix(8)))")
                        .font(.caption)
                        
            .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: "wifi")
                            .font(.caption)
                        Text("\(device.signalStrength) dBm")
                            .font(.caption)
                    }
                    
            .foregroundColor(.secondary)
                    
                    if device.batteryLevel < 100 {
                        HStack {
                            Image(systemName: batteryIcon(for: device.batteryLevel))
                                .font(.caption)
                            Text("\(device.batteryLevel)%")
                                .font(.caption)
                        }
                        
            .foregroundColor(batteryColor(for: device.batteryLevel))
                    }
                }
                
                Image(systemName: "chevron.right")
                    
            .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func batteryIcon(for level: Int) -> String {
        if level > 75 { return "battery.100" }
        else if level > 50 { return "battery.75" }
        else if level > 25 { return "battery.25" }
        else { return "battery.0" }
    }
    
    private func batteryColor(for level: Int) -> Color {
        if level > 50 { return .green }
        else if level > 20 { return .orange }
        else { return .red }
    }
}

struct ConnectedDeviceView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showingCalibration = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Device Info Card
                if let device = bluetoothManager.connectedDevice {
                    VStack(spacing: 16) {
                        Image(systemName: "applewatch.radiowaves.left.and.right")
                            .font(.system(size: 80))
                            
            .foregroundColor(.blue)
                        
                        Text(device.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("Battery")
                                    .font(.caption)
                                    
            .foregroundColor(.secondary)
                                Text("\(device.batteryLevel)%")
                                    .font(.headline)
                                    
            .foregroundColor(batteryColor(for: device.batteryLevel))
                            }
                            
                            Divider()
                                .frame(height: 30)
                            
                            VStack {
                                Text("Signal")
                                    .font(.caption)
                                    
            .foregroundColor(.secondary)
                                Text("\(bluetoothManager.signalStrength) dBm")
                                    .font(.headline)
                            }
                            
                            Divider()
                                .frame(height: 30)
                            
                            VStack {
                                Text("Firmware")
                                    .font(.caption)
                                    
            .foregroundColor(.secondary)
                                Text(device.firmwareVersion)
                                    .font(.headline)
                            }
                        }
                        
                        if let lastSync = device.lastSyncDate {
                            Text("Last synced \(lastSync, style: .relative) ago")
                                .font(.caption)
                                
            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // Live Data Status
                LiveDataStatusView()
                    .environmentObject(bluetoothManager)
                    .padding(.horizontal)
                
                // Control Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        if bluetoothManager.dataStreamActive {
                            bluetoothManager.stopDataStreaming()
                        } else {
                            bluetoothManager.startDataStreaming()
                        }
                    }) {
                        HStack {
                            Image(systemName: bluetoothManager.dataStreamActive ? "stop.fill" : "play.fill")
                            Text(bluetoothManager.dataStreamActive ? "Stop Streaming" : "Start Streaming")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(bluetoothManager.dataStreamActive ? Color.red : Color.green)
                        
            .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingCalibration = true
                        bluetoothManager.performCalibration()
                    }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Calibrate Device")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        
            .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        bluetoothManager.disconnect()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Disconnect")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.15))
                        
            .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Active Alerts
                if !bluetoothManager.activeAlerts.isEmpty {
                    AlertsView()
                        .environmentObject(bluetoothManager)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .alert("Calibration", isPresented: $showingCalibration) {
            Button("OK") { }
        } message: {
            Text("Device calibration started. Please remain still for 30 seconds.")
        }
    }
    
    private func batteryColor(for level: Int) -> Color {
        if level > 50 { return .green }
        else if level > 20 { return .orange }
        else { return .red }
    }
}

struct LiveDataStatusView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Monitoring")
                .font(.headline)
            
            VStack(spacing: 8) {
                DataStatusRow(
                    icon: "heart.fill",
                    label: "Heart Rate",
                    value: "\(bluetoothManager.currentHeartRate) BPM",
                    color: .red,
                    isActive: bluetoothManager.currentECG != nil
                )
                
                DataStatusRow(
                    icon: "drop.fill",
                    label: "Blood Pressure",
                    value: bluetoothManager.currentBloodPressure != nil ? 
                        "\(bluetoothManager.currentBloodPressure!.systolic)/\(bluetoothManager.currentBloodPressure!.diastolic)" : "--/--",
                    color: .purple,
                    isActive: bluetoothManager.currentBloodPressure != nil
                )
                
                DataStatusRow(
                    icon: "circle.hexagongrid.fill",
                    label: "Glucose",
                    value: bluetoothManager.currentGlucose != nil ? 
                        "\(Int(bluetoothManager.currentGlucose!.glucoseLevel)) mg/dL" : "-- mg/dL",
                    color: .orange,
                    isActive: bluetoothManager.currentGlucose != nil
                )
                
                DataStatusRow(
                    icon: "lungs.fill",
                    label: "SpO2",
                    value: bluetoothManager.currentSpO2 != nil ? 
                        "\(bluetoothManager.currentSpO2!.oxygenSaturation)%" : "--%",
                    color: .blue,
                    isActive: bluetoothManager.currentSpO2 != nil
                )
                
                DataStatusRow(
                    icon: "waveform.path.ecg",
                    label: "Troponin",
                    value: bluetoothManager.currentTroponin != nil ? 
                        String(format: "%.3f ng/mL", bluetoothManager.currentTroponin!.troponinI) : "-- ng/mL",
                    color: .green,
                    isActive: bluetoothManager.currentTroponin != nil
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DataStatusRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                
            .foregroundColor(isActive ? color : .gray)
                .frame(width: 30)
            
            Text(label)
                .font(.subheadline)
                
            .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                
            .foregroundColor(isActive ? .primary : .secondary)
            
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
    }
}

struct AlertsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Alerts")
                .font(.headline)
            
            ForEach(bluetoothManager.activeAlerts) { alert in
                AlertRow(alert: alert)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AlertRow: View {
    let alert: HealthAlert
    
    var body: some View {
        HStack {
            Image(systemName: alertIcon)
                
            .foregroundColor(alertColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(alert.message)
                    .font(.caption)
                    
            .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if alert.actionRequired {
                Image(systemName: "exclamationmark.triangle.fill")
                    
            .foregroundColor(.red)
            }
        }
        .padding()
        .background(alertBackgroundColor)
        .cornerRadius(8)
    }
    
    private var alertIcon: String {
        switch alert.severity {
        case .info: return "info.circle.fill"
        case .low: return "exclamationmark.circle"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    private var alertColor: Color {
        switch alert.severity {
        case .info: return .blue
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    private var alertBackgroundColor: Color {
        switch alert.severity {
        case .info: return Color.blue.opacity(0.1)
        case .low: return Color.green.opacity(0.1)
        case .medium: return Color.yellow.opacity(0.1)
        case .high: return Color.orange.opacity(0.1)
        case .critical: return Color.red.opacity(0.2)
        }
    }
}

struct DeviceDetailsSheet: View {
    let device: LifeLensDevice
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Device Information") {
                    DetailRow(label: "Name", value: device.name)
                    DetailRow(label: "Serial Number", value: device.serialNumber)
                    DetailRow(label: "Firmware Version", value: device.firmwareVersion)
                    DetailRow(label: "Signal Strength", value: "\(device.signalStrength) dBm")
                    DetailRow(label: "Battery Level", value: "\(device.batteryLevel)%")
                }
                
                Section {
                    Button(action: {
                        bluetoothManager.connect(to: device)
                        dismiss()
                    }) {
                        Text("Connect to Device")
                            .frame(maxWidth: .infinity)
                            
            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Device Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                #endif
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                
            .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}