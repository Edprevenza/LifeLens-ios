// Managers/BluetoothManager.swift
import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Singleton
    static let shared = BluetoothManager()
    
    // MARK: - Published Properties
    @Published var connectionState: BLEConnectionState = .disconnected
    @Published var discoveredDevices: [LifeLensDevice] = []
    @Published var connectedDevice: LifeLensDevice?
    @Published var latestHealthSnapshot: HealthSnapshot?
    @Published var isScanning = false
    @Published var signalStrength: Int = -100 // RSSI
    @Published var dataStreamActive = false
    
    // Real-time data streams
    @Published var currentHeartRate: Int = 0
    @Published var currentBloodPressure: BloodPressureData?
    @Published var currentGlucose: GlucoseData?
    @Published var currentSpO2: SpO2Data?
    @Published var currentECG: ECGData?
    @Published var currentTroponin: TroponinData?
    
    // Latest data for dashboard
    @Published var latestECGData: ECGData?
    @Published var latestBloodPressureData: BloodPressureData?
    @Published var latestGlucoseData: GlucoseData?
    @Published var latestSpO2Data: SpO2Data?
    @Published var latestTroponinData: TroponinData?
    @Published var currentAlerts: [HealthAlert] = []
    
    // Alerts
    @Published var activeAlerts: [HealthAlert] = []
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    private var dataCharacteristics: [CBUUID: CBCharacteristic] = [:]
    
    // Data buffers for streaming
    private var ecgBuffer: [Double] = []
    private let ecgBufferSize = 2500 // 5 seconds at 500Hz
    
    // Timers
    private var rssiTimer: Timer?
    private var reconnectTimer: Timer?
    
    // Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // API Service
    private let apiService = APIService.shared
    
    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        setupMockDataForTesting()
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }
        
        isScanning = true
        connectionState = .scanning
        discoveredDevices.removeAll()
        discoveredPeripherals.removeAll()
        
        let services = [LifeLensUUIDs.primaryService, LifeLensUUIDs.dataService]
        centralManager.scanForPeripherals(withServices: services, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        // Stop scanning after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.stopScanning()
        }
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        if connectionState == .scanning {
            connectionState = .disconnected
        }
    }
    
    func connect(to device: LifeLensDevice) {
        guard let peripheral = discoveredPeripherals.first(where: { 
            $0.identifier.uuidString == device.serialNumber 
        }) else {
            print("Peripheral not found for device: \(device.name)")
            return
        }
        
        connectionState = .connecting
        centralManager.connect(peripheral, options: nil)
        connectedPeripheral = peripheral
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        
        stopDataStreaming()
        centralManager.cancelPeripheralConnection(peripheral)
        connectedPeripheral = nil
        connectedDevice = nil
        connectionState = .disconnected
        dataStreamActive = false
        
        // Clear timers
        rssiTimer?.invalidate()
        rssiTimer = nil
    }
    
    func startDataStreaming() {
        guard let peripheral = connectedPeripheral,
              let commandChar = dataCharacteristics[LifeLensUUIDs.commandCharacteristic] else {
            print("Cannot start streaming: device not ready")
            return
        }
        
        let packet = BLEPacket(command: .startStreaming, payload: Data())
        peripheral.writeValue(packet.toData(), for: commandChar, type: .withResponse)
        
        dataStreamActive = true
        connectionState = .streaming
        
        // Start RSSI monitoring
        startRSSIMonitoring()
    }
    
    func stopDataStreaming() {
        guard let peripheral = connectedPeripheral,
              let commandChar = dataCharacteristics[LifeLensUUIDs.commandCharacteristic] else {
            return
        }
        
        let packet = BLEPacket(command: .stopStreaming, payload: Data())
        peripheral.writeValue(packet.toData(), for: commandChar, type: .withResponse)
        
        dataStreamActive = false
        if connectionState == .streaming {
            connectionState = .connected
        }
    }
    
    func performCalibration() {
        guard let peripheral = connectedPeripheral,
              let commandChar = dataCharacteristics[LifeLensUUIDs.commandCharacteristic] else {
            print("Cannot calibrate: device not ready")
            return
        }
        
        let packet = BLEPacket(command: .performCalibration, payload: Data())
        peripheral.writeValue(packet.toData(), for: commandChar, type: .withResponse)
    }
    
    // MARK: - Private Methods
    private func startRSSIMonitoring() {
        rssiTimer?.invalidate()
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.connectedPeripheral?.readRSSI()
        }
    }
    
    private func processReceivedData(_ data: Data, for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case LifeLensUUIDs.troponinCharacteristic:
            processTroponinData(data)
        case LifeLensUUIDs.ecgCharacteristic:
            processECGData(data)
        case LifeLensUUIDs.bpCharacteristic:
            processBloodPressureData(data)
        case LifeLensUUIDs.glucoseCharacteristic:
            processGlucoseData(data)
        case LifeLensUUIDs.spo2Characteristic:
            processSpO2Data(data)
        case LifeLensUUIDs.batteryCharacteristic:
            processBatteryData(data)
        default:
            break
        }
    }
    
    private func processTroponinData(_ data: Data) {
        guard data.count >= 32 else { return }
        
        let troponinI = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Double.self) }
        let troponinT = data.withUnsafeBytes { $0.load(fromByteOffset: 8, as: Double.self) }
        let confidence = data.withUnsafeBytes { $0.load(fromByteOffset: 16, as: Double.self) }
        let riskScore = data.withUnsafeBytes { $0.load(fromByteOffset: 24, as: Double.self) }
        
        let troponinData = TroponinData(
            timestamp: Date(),
            troponinI: troponinI,
            troponinT: troponinT,
            confidence: confidence,
            riskScore: riskScore
        )
        currentTroponin = troponinData
        latestTroponinData = troponinData
        
        // Upload to API as vitals data
        let vitalsData: [String: Any] = [
            "troponinI": troponinI,
            "troponinT": troponinT,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        apiService.sendVitals(vitalsData)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to upload troponin data: \(error)")
                    }
                },
                receiveValue: { success in
                    if success {
                        print("Troponin data uploaded successfully")
                    }
                }
            )
            .store(in: &cancellables)
        
        // Check for critical levels (MI detection)
        if troponinI > 0.04 || troponinT > 0.01 {
            let alert = HealthAlert(
                id: UUID().uuidString,
                title: "Elevated Troponin Detected",
                message: "Troponin levels indicate possible myocardial injury. Seek immediate medical attention.",
                severity: .critical,
                timestamp: Date(),
                metricType: "Troponin",
                value: max(troponinI, troponinT),
                actionRequired: true
            )
            activeAlerts.append(alert)
            triggerEmergencyProtocol()
        }
    }
    
    private func processECGData(_ data: Data) {
        guard data.count >= 1004 else { return } // 500 samples * 2 bytes + 4 bytes metadata
        
        var samples: [Double] = []
        for i in stride(from: 0, to: 1000, by: 2) {
            let value = data.withUnsafeBytes { $0.load(fromByteOffset: i, as: Int16.self) }
            samples.append(Double(value) / 1000.0) // Convert to mV
        }
        
        let heartRate = Int(data.withUnsafeBytes { $0.load(fromByteOffset: 1000, as: UInt8.self) })
        let arrhythmia = data.withUnsafeBytes { $0.load(fromByteOffset: 1001, as: UInt8.self) } > 0
        
        let ecgData = ECGData(
            timestamp: Date(),
            samples: samples,
            heartRate: heartRate,
            prInterval: nil,
            qrsComplex: nil,
            qtInterval: nil,
            stDeviation: nil,
            arrhythmiaDetected: arrhythmia,
            arrhythmiaType: arrhythmia ? "Atrial Fibrillation" : nil
        )
        
        currentECG = ecgData
        latestECGData = ecgData
        currentHeartRate = heartRate
        ecgBuffer.append(contentsOf: samples)
        if ecgBuffer.count > ecgBufferSize {
            ecgBuffer.removeFirst(ecgBuffer.count - ecgBufferSize)
        }
    }
    
    private func processBloodPressureData(_ data: Data) {
        guard data.count >= 12 else { return }
        
        let systolic = Int(data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt16.self) })
        let diastolic = Int(data.withUnsafeBytes { $0.load(fromByteOffset: 2, as: UInt16.self) })
        let map = Int(data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt16.self) })
        let pwv = data.withUnsafeBytes { $0.load(fromByteOffset: 6, as: Float.self) }
        let confidence = data.withUnsafeBytes { $0.load(fromByteOffset: 10, as: UInt16.self) }
        
        let bpData = BloodPressureData(
            timestamp: Date(),
            systolic: systolic,
            diastolic: diastolic,
            meanArterialPressure: map,
            pulseWaveVelocity: Double(pwv),
            confidence: Double(confidence) / 100.0
        )
        currentBloodPressure = bpData
        latestBloodPressureData = bpData
        
        // Upload to API as vitals data
        let vitalsData: [String: Any] = [
            "systolic": systolic,
            "diastolic": diastolic,
            "meanArterialPressure": map,
            "pulseWaveVelocity": pwv,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        apiService.sendVitals(vitalsData)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Check for hypertensive crisis
        if systolic > 180 || diastolic > 120 {
            let alert = HealthAlert(
                id: UUID().uuidString,
                title: "Hypertensive Crisis",
                message: "Blood pressure is dangerously high. Seek emergency medical care immediately.",
                severity: .critical,
                timestamp: Date(),
                metricType: "Blood Pressure",
                value: Double(systolic),
                actionRequired: true
            )
            activeAlerts.append(alert)
        }
    }
    
    private func processGlucoseData(_ data: Data) {
        guard data.count >= 12 else { return }
        
        let glucose = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Float.self) }
        let trendValue = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt8.self) }
        let rateOfChange = data.withUnsafeBytes { $0.load(fromByteOffset: 5, as: Float.self) }
        
        let trend: GlucoseData.GlucoseTrend
        switch trendValue {
        case 0: trend = .rapidlyFalling
        case 1: trend = .falling
        case 2: trend = .stable
        case 3: trend = .rising
        case 4: trend = .rapidlyRising
        default: trend = .stable
        }
        
        let glucoseData = GlucoseData(
            timestamp: Date(),
            glucoseLevel: Double(glucose),
            trend: trend,
            rateOfChange: Double(rateOfChange),
            predictedLow: glucose < 80 ? Date().addingTimeInterval(1800) : nil,
            predictedHigh: glucose > 180 ? Date().addingTimeInterval(1800) : nil
        )
        currentGlucose = glucoseData
        latestGlucoseData = glucoseData
        
        // Check for hypoglycemia
        if glucose < 70 {
            let alert = HealthAlert(
                id: UUID().uuidString,
                title: "Low Blood Sugar",
                message: "Blood glucose is \(Int(glucose)) mg/dL. Consider consuming fast-acting carbohydrates.",
                severity: .urgent,
                timestamp: Date(),
                metricType: "Glucose",
                value: Double(glucose),
                actionRequired: true
            )
            activeAlerts.append(alert)
        }
    }
    
    private func processSpO2Data(_ data: Data) {
        guard data.count >= 8 else { return }
        
        let spo2 = Int(data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt8.self) })
        let perfusionIndex = data.withUnsafeBytes { $0.load(fromByteOffset: 1, as: Float.self) }
        let respiratoryRate = Int(data.withUnsafeBytes { $0.load(fromByteOffset: 5, as: UInt8.self) })
        let confidence = data.withUnsafeBytes { $0.load(fromByteOffset: 6, as: UInt16.self) }
        
        let spo2Data = SpO2Data(
            timestamp: Date(),
            oxygenSaturation: spo2,
            perfusionIndex: Double(perfusionIndex),
            respiratoryRate: respiratoryRate,
            confidence: Double(confidence) / 100.0
        )
        currentSpO2 = spo2Data
        latestSpO2Data = spo2Data
        
        // Check for hypoxia
        if spo2 < 90 {
            let alert = HealthAlert(
                id: UUID().uuidString,
                title: "Low Oxygen Saturation",
                message: "SpO2 is \(spo2)%. Seek medical attention if symptoms persist.",
                severity: .critical,
                timestamp: Date(),
                metricType: "SpO2",
                value: Double(spo2),
                actionRequired: true
            )
            activeAlerts.append(alert)
        }
    }
    
    private func processBatteryData(_ data: Data) {
        guard data.count >= 1 else { return }
        
        let batteryLevel = Int(data[0])
        connectedDevice?.batteryLevel = batteryLevel
        
        if batteryLevel < 20 {
            let alert = HealthAlert(
                id: UUID().uuidString,
                title: "Low Battery",
                message: "LifeLens device battery is at \(batteryLevel)%. Please charge soon.",
                severity: .warning,
                timestamp: Date(),
                metricType: "Battery",
                value: Double(batteryLevel),
                actionRequired: false
            )
            activeAlerts.append(alert)
        }
    }
    
    private func triggerEmergencyProtocol() {
        // Send emergency notification
        NotificationCenter.default.post(
            name: Notification.Name("EmergencyAlert"),
            object: nil,
            userInfo: ["alerts": activeAlerts]
        )
        
        // Upload critical data to cloud
        uploadEmergencyData()
    }
    
    private func uploadEmergencyData() {
        // Implementation would upload data to cloud platform
        print("Emergency data upload triggered")
    }
    
    // MARK: - Mock Data for Testing
    private func setupMockDataForTesting() {
        #if DEBUG
        // Add mock device for testing when no real device is available
        // Note: In production, devices are only added through real BLE discovery
        #endif
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            connectionState = .error("Bluetooth is turned off")
        case .resetting:
            connectionState = .error("Bluetooth is resetting")
        case .unauthorized:
            connectionState = .error("Bluetooth is unauthorized")
        case .unsupported:
            connectionState = .error("Bluetooth is not supported")
        case .unknown:
            connectionState = .error("Bluetooth state unknown")
        @unknown default:
            connectionState = .error("Unknown Bluetooth error")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, 
                       advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Check if it's a LifeLens device
        guard let name = peripheral.name,
              name.contains("LifeLens") || name.contains("LL-") else {
            return
        }
        
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            let device = LifeLensDevice(peripheral: peripheral)
            discoveredDevices.append(device)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "device")")
        connectionState = .connected
        
        peripheral.delegate = self
        peripheral.discoverServices([LifeLensUUIDs.dataService])
        
        // Update connected device
        if let index = discoveredDevices.firstIndex(where: { 
            $0.serialNumber == peripheral.identifier.uuidString 
        }) {
            discoveredDevices[index].isConnected = true
            discoveredDevices[index].lastSyncDate = Date()
            connectedDevice = discoveredDevices[index]
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        connectionState = .error("Failed to connect")
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "device")")
        connectionState = .disconnected
        connectedPeripheral = nil
        connectedDevice = nil
        dataStreamActive = false
        
        // Attempt to reconnect if it was an unexpected disconnection
        if error != nil {
            reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                self?.centralManager.connect(peripheral, options: nil)
            }
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil,
              let services = peripheral.services else {
            print("Error discovering services: \(error?.localizedDescription ?? "Unknown")")
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil,
              let characteristics = service.characteristics else {
            print("Error discovering characteristics: \(error?.localizedDescription ?? "Unknown")")
            return
        }
        
        for characteristic in characteristics {
            dataCharacteristics[characteristic.uuid] = characteristic
            
            // Subscribe to notifications for data characteristics
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            // Read initial values
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
        }
        
        connectionState = .syncing
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil,
              let data = characteristic.value else {
            print("Error reading characteristic: \(error?.localizedDescription ?? "Unknown")")
            return
        }
        
        processReceivedData(data, for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else { return }
        signalStrength = RSSI.intValue
        connectedDevice?.signalStrength = RSSI.intValue
    }
}

// Extension for notifications
extension Notification.Name {
    static let vitalsDataReceived = Notification.Name("vitalsDataReceived")
}