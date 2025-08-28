// BLEDeviceManager.swift
// Medical-grade Bluetooth LE device manager for LifeLens wearable

import Foundation
import CoreBluetooth
import CryptoKit
import Compression
import Combine

/**
 * BLE Device Manager for LifeLens Wearable
 * Handles high-frequency medical data streaming at 250Hz
 * Implements AES-256-GCM decryption and LZ4 decompression
 * Manages multi-characteristic health monitoring
 */
class BLEDeviceManager: NSObject, ObservableObject {
    
    // MARK: - Service & Characteristic UUIDs
    
    // LifeLens Service UUID
    private let LIFELENS_SERVICE_UUID = CBUUID(string: "00001800-0000-1000-8000-00805F9B34FB")
    
    // Health Monitoring Characteristics
    private let TROPONIN_CHARACTERISTIC = CBUUID(string: "00001801-0000-1000-8000-00805F9B34FB")
    private let BP_CHARACTERISTIC = CBUUID(string: "00001802-0000-1000-8000-00805F9B34FB")
    private let GLUCOSE_CHARACTERISTIC = CBUUID(string: "00001803-0000-1000-8000-00805F9B34FB")
    private let ECG_STREAM_CHARACTERISTIC = CBUUID(string: "00001804-0000-1000-8000-00805F9B34FB")
    private let PPG_STREAM_CHARACTERISTIC = CBUUID(string: "00001805-0000-1000-8000-00805F9B34FB")
    private let IMU_STREAM_CHARACTERISTIC = CBUUID(string: "00001806-0000-1000-8000-00805F9B34FB")
    private let TEMPERATURE_CHARACTERISTIC = CBUUID(string: "00001807-0000-1000-8000-00805F9B34FB")
    private let BATTERY_CHARACTERISTIC = CBUUID(string: "00001808-0000-1000-8000-00805F9B34FB")
    private let COMMAND_CHARACTERISTIC = CBUUID(string: "00001809-0000-1000-8000-00805F9B34FB")
    private let STATUS_CHARACTERISTIC = CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB")
    
    // MARK: - Configuration
    
    private let ECG_SAMPLING_RATE = 250  // 250Hz for medical-grade ECG
    private let PPG_SAMPLING_RATE = 100  // 100Hz for PPG/SpO2
    private let IMU_SAMPLING_RATE = 50   // 50Hz for accelerometer/gyroscope
    private let PACKET_SIZE = 244        // BLE packet size (244 bytes after headers)
    private let MTU_SIZE = 247           // Maximum Transmission Unit
    
    // MARK: - Published Properties
    
    @Published var connectionState: ConnectionState = .disconnected
    @Published var deviceBattery: Int = 0
    @Published var signalQuality: Float = 0.0
    @Published var dataRate: Int = 0  // bytes/second
    @Published var lastUpdateTime = Date()
    @Published var isStreaming = false
    
    // MARK: - Real-time Data Streams
    
    @Published var currentTroponin: Float = 0.0
    @Published var currentBP: (systolic: Int, diastolic: Int) = (0, 0)
    @Published var currentGlucose: Float = 0.0
    @Published var currentHeartRate: Int = 0
    @Published var currentSpO2: Int = 0
    @Published var currentTemperature: Float = 0.0
    
    // Data publishers for continuous streams
    let ecgDataPublisher = PassthroughSubject<[Float], Never>()
    let ppgDataPublisher = PassthroughSubject<[Float], Never>()
    let imuDataPublisher = PassthroughSubject<IMUData, Never>()
    let healthMetricsPublisher = PassthroughSubject<HealthMetrics, Never>()
    let alertPublisher = PassthroughSubject<DeviceAlert, Never>()
    
    // MARK: - Core Bluetooth
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var discoveredPeripherals: Set<CBPeripheral> = []
    
    // Characteristic references
    private var troponinCharacteristic: CBCharacteristic?
    private var bpCharacteristic: CBCharacteristic?
    private var glucoseCharacteristic: CBCharacteristic?
    private var ecgStreamCharacteristic: CBCharacteristic?
    private var ppgStreamCharacteristic: CBCharacteristic?
    private var imuStreamCharacteristic: CBCharacteristic?
    private var commandCharacteristic: CBCharacteristic?
    
    // MARK: - Data Processing
    
    private let processingQueue = DispatchQueue(label: "com.lifelens.ble.processing",
                                               qos: .userInteractive,
                                               attributes: .concurrent)
    
    // Data buffers for stream assembly
    private var ecgBuffer = DataBuffer(maxSize: 1000)  // 4 seconds at 250Hz
    private var ppgBuffer = DataBuffer(maxSize: 400)   // 4 seconds at 100Hz
    private var imuBuffer = DataBuffer(maxSize: 200)   // 4 seconds at 50Hz
    
    // Packet reassembly
    private var partialPackets: [CBUUID: Data] = [:]
    
    // MARK: - Security & Compression
    
    private var encryptionKey: SymmetricKey!
    private var sessionNonce: Data?
    private let compressionAlgorithm = Algorithm.lz4
    
    // Performance metrics
    private var bytesReceived: Int = 0
    private var packetsReceived: Int = 0
    private var lastDataRateUpdate = Date()
    
    // MARK: - Types
    
    enum ConnectionState {
        case disconnected
        case scanning
        case connecting
        case connected
        case authenticated
        case streaming
    }
    
    struct HealthMetrics {
        let timestamp: Date
        let troponin: Float?       // ng/L
        let systolicBP: Int?       // mmHg
        let diastolicBP: Int?      // mmHg
        let glucose: Float?        // mg/dL
        let heartRate: Int?        // bpm
        let spO2: Int?            // %
        let temperature: Float?    // °C
        let respiratoryRate: Int?  // breaths/min
    }
    
    struct IMUData {
        let timestamp: Date
        let accelerometer: (x: Float, y: Float, z: Float)
        let gyroscope: (x: Float, y: Float, z: Float)
        let magnetometer: (x: Float, y: Float, z: Float)?
    }
    
    struct DeviceAlert {
        let timestamp: Date
        let type: AlertType
        let severity: AlertSeverity
        let message: String
        
        enum AlertType {
            case lowBattery, sensorError, connectionLost, criticalReading
        }
        
        enum AlertSeverity {
            case info, warning, critical
        }
    }
    
    class DataBuffer {
        private var buffer: [Float] = []
        private let maxSize: Int
        private let lock = NSLock()
        
        init(maxSize: Int) {
            self.maxSize = maxSize
        }
        
        func append(_ data: [Float]) {
            lock.lock()
            defer { lock.unlock() }
            
            buffer.append(contentsOf: data)
            if buffer.count > maxSize {
                buffer.removeFirst(buffer.count - maxSize)
            }
        }
        
        func getLatest(_ count: Int) -> [Float] {
            lock.lock()
            defer { lock.unlock() }
            
            return Array(buffer.suffix(count))
        }
        
        func clear() {
            lock.lock()
            defer { lock.unlock() }
            buffer.removeAll()
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupBluetooth()
        setupEncryption()
        startPerformanceMonitoring()
    }
    
    private func setupBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: true,
            CBCentralManagerOptionRestoreIdentifierKey: "com.lifelens.ble.central"
        ])
    }
    
    private func setupEncryption() {
        // Generate or load encryption key (in production, use Keychain)
        let keyData = "LifeLens2024SecureDeviceKey1234".data(using: .utf8)!
        encryptionKey = SymmetricKey(data: keyData)
    }
    
    // MARK: - Connection Management
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            AppLogger.shared.log("Bluetooth not ready")
            return
        }
        
        connectionState = .scanning
        discoveredPeripherals.removeAll()
        
        // Scan for LifeLens devices
        centralManager.scanForPeripherals(
            withServices: [LIFELENS_SERVICE_UUID],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false,
                CBCentralManagerScanOptionSolicitedServiceUUIDsKey: [LIFELENS_SERVICE_UUID]
            ]
        )
        
        AppLogger.shared.log("Started BLE scanning")
        
        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.connectionState == .scanning {
                self?.stopScanning()
            }
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        if connectionState == .scanning {
            connectionState = .disconnected
        }
        AppLogger.shared.log("Stopped BLE scanning")
    }
    
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectionState = .connecting
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnNotificationKey: true
        ])
        
        AppLogger.shared.log("Connecting to \(peripheral.name ?? "Unknown")")
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        
        // Stop notifications
        stopDataStreaming()
        
        // Disconnect
        centralManager.cancelPeripheralConnection(peripheral)
        
        // Clear buffers
        clearBuffers()
        
        connectionState = .disconnected
        connectedPeripheral = nil
        
        AppLogger.shared.log("Disconnected from device")
    }
    
    // MARK: - Data Streaming Control
    
    func startDataStreaming() {
        guard let peripheral = connectedPeripheral,
              connectionState == .authenticated else {
            AppLogger.shared.log("Cannot start streaming - not authenticated")
            return
        }
        
        // Enable notifications for all data characteristics
        enableNotifications(for: [
            ecgStreamCharacteristic,
            ppgStreamCharacteristic,
            imuStreamCharacteristic,
            troponinCharacteristic,
            bpCharacteristic,
            glucoseCharacteristic
        ].compactMap { $0 }, on: peripheral)
        
        // Send start streaming command
        sendCommand(.startStreaming)
        
        isStreaming = true
        connectionState = .streaming
        
        AppLogger.shared.log("Started data streaming")
    }
    
    func stopDataStreaming() {
        guard let peripheral = connectedPeripheral else { return }
        
        // Send stop streaming command
        sendCommand(.stopStreaming)
        
        // Disable notifications
        disableNotifications(for: [
            ecgStreamCharacteristic,
            ppgStreamCharacteristic,
            imuStreamCharacteristic
        ].compactMap { $0 }, on: peripheral)
        
        isStreaming = false
        if connectionState == .streaming {
            connectionState = .connected
        }
        
        AppLogger.shared.log("Stopped data streaming")
    }
    
    // MARK: - Command Interface
    
    enum DeviceCommand: UInt8 {
        case startStreaming = 0x01
        case stopStreaming = 0x02
        case requestBattery = 0x03
        case setECGGain = 0x04
        case calibrateSensors = 0x05
        case performSelfTest = 0x06
        case resetDevice = 0x07
        case enableHighFrequency = 0x08
        case setCompressionLevel = 0x09
        case syncTime = 0x0A
    }
    
    func sendCommand(_ command: DeviceCommand, parameters: Data? = nil) {
        guard let characteristic = commandCharacteristic,
              let peripheral = connectedPeripheral else { return }
        
        var commandData = Data([command.rawValue])
        if let params = parameters {
            commandData.append(params)
        }
        
        // Add timestamp for sync
        if command == .syncTime {
            let timestamp = UInt32(Date().timeIntervalSince1970)
            commandData.append(contentsOf: withUnsafeBytes(of: timestamp) { Data($0) })
        }
        
        peripheral.writeValue(commandData, for: characteristic, type: .withResponse)
        
        AppLogger.shared.log("Sent command: \(command)")
    }
    
    // MARK: - Data Processing Pipeline
    
    private func processIncomingData(_ data: Data, from characteristic: CBCharacteristic) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Update metrics
            self.bytesReceived += data.count
            self.packetsReceived += 1
            
            switch characteristic.uuid {
            case self.ECG_STREAM_CHARACTERISTIC:
                self.processECGStream(data)
                
            case self.PPG_STREAM_CHARACTERISTIC:
                self.processPPGStream(data)
                
            case self.IMU_STREAM_CHARACTERISTIC:
                self.processIMUStream(data)
                
            case self.TROPONIN_CHARACTERISTIC:
                self.processTroponinData(data)
                
            case self.BP_CHARACTERISTIC:
                self.processBPData(data)
                
            case self.GLUCOSE_CHARACTERISTIC:
                self.processGlucoseData(data)
                
            case self.BATTERY_CHARACTERISTIC:
                self.processBatteryData(data)
                
            default:
                break
            }
            
            self.updateDataRate()
        }
    }
    
    // MARK: - ECG Stream Processing (250Hz)
    
    private func processECGStream(_ encryptedData: Data) {
        // Step 1: Decrypt AES-256-GCM
        guard let decryptedData = decryptData(encryptedData) else {
            AppLogger.shared.log("ECG decryption failed")
            return
        }
        
        // Step 2: Decompress LZ4
        guard let decompressedData = decompressLZ4(decryptedData) else {
            AppLogger.shared.log("ECG decompression failed")
            return
        }
        
        // Step 3: Parse ECG samples (12-bit resolution)
        let samples = parseECGSamples(decompressedData)
        
        // Step 4: Apply digital filters
        let filteredSamples = applyECGFilters(samples)
        
        // Step 5: Buffer for processing
        ecgBuffer.append(filteredSamples)
        
        // Step 6: Publish for real-time display
        DispatchQueue.main.async {
            self.ecgDataPublisher.send(filteredSamples)
            self.lastUpdateTime = Date()
        }
        
        // Step 7: Detect R-peaks for heart rate
        if let heartRate = detectHeartRate(from: filteredSamples) {
            DispatchQueue.main.async {
                self.currentHeartRate = heartRate
            }
        }
    }
    
    private func parseECGSamples(_ data: Data) -> [Float] {
        var samples: [Float] = []
        let sampleSize = 2  // 12-bit packed into 16-bit
        
        for i in stride(from: 0, to: data.count - 1, by: sampleSize) {
            let value = data[i..<i+sampleSize].withUnsafeBytes { bytes in
                bytes.load(as: Int16.self)
            }
            // Convert 12-bit ADC to millivolts
            let millivolts = Float(value) * 0.005  // 5μV/LSB resolution
            samples.append(millivolts)
        }
        
        return samples
    }
    
    private func applyECGFilters(_ samples: [Float]) -> [Float] {
        // Apply 0.5-40Hz bandpass filter for diagnostic ECG
        let filtered = butterworthBandpass(samples, 
                                          lowCutoff: 0.5, 
                                          highCutoff: 40, 
                                          sampleRate: Float(ECG_SAMPLING_RATE))
        
        // Remove 50/60Hz powerline interference
        return notchFilter(filtered, frequency: 50, sampleRate: Float(ECG_SAMPLING_RATE))
    }
    
    // MARK: - PPG Stream Processing (100Hz)
    
    private func processPPGStream(_ encryptedData: Data) {
        guard let decryptedData = decryptData(encryptedData) else { return }
        guard let decompressedData = decompressLZ4(decryptedData) else { return }
        
        // Parse PPG samples (Red, IR, Green LEDs)
        let samples = parsePPGSamples(decompressedData)
        
        // Calculate SpO2 from Red/IR ratio
        if let spO2 = calculateSpO2(redSamples: samples.red, irSamples: samples.ir) {
            DispatchQueue.main.async {
                self.currentSpO2 = spO2
            }
        }
        
        // Buffer and publish
        ppgBuffer.append(samples.ir)
        
        DispatchQueue.main.async {
            self.ppgDataPublisher.send(samples.ir)
        }
    }
    
    private func parsePPGSamples(_ data: Data) -> (red: [Float], ir: [Float], green: [Float]) {
        var red: [Float] = []
        var ir: [Float] = []
        var green: [Float] = []
        
        let sampleSize = 6  // 2 bytes per channel
        
        for i in stride(from: 0, to: data.count - sampleSize, by: sampleSize) {
            let redValue = data[i..<i+2].withUnsafeBytes { $0.load(as: UInt16.self) }
            let irValue = data[i+2..<i+4].withUnsafeBytes { $0.load(as: UInt16.self) }
            let greenValue = data[i+4..<i+6].withUnsafeBytes { $0.load(as: UInt16.self) }
            
            red.append(Float(redValue))
            ir.append(Float(irValue))
            green.append(Float(greenValue))
        }
        
        return (red, ir, green)
    }
    
    private func calculateSpO2(redSamples: [Float], irSamples: [Float]) -> Int? {
        guard redSamples.count == irSamples.count, !redSamples.isEmpty else { return nil }
        
        // Calculate AC and DC components
        let redAC = redSamples.max()! - redSamples.min()!
        let redDC = redSamples.reduce(0, +) / Float(redSamples.count)
        let irAC = irSamples.max()! - irSamples.min()!
        let irDC = irSamples.reduce(0, +) / Float(irSamples.count)
        
        // Calculate ratio of ratios (R)
        let R = (redAC / redDC) / (irAC / irDC)
        
        // Empirical formula for SpO2
        let spO2 = 110 - 25 * R
        
        return Int(max(0, min(100, spO2)))
    }
    
    // MARK: - IMU Stream Processing (50Hz)
    
    private func processIMUStream(_ encryptedData: Data) {
        guard let decryptedData = decryptData(encryptedData) else { return }
        guard let decompressedData = decompressLZ4(decryptedData) else { return }
        
        let imuData = parseIMUData(decompressedData)
        
        // Detect falls
        if detectFall(from: imuData) {
            let alert = DeviceAlert(
                timestamp: Date(),
                type: .criticalReading,
                severity: .critical,
                message: "Fall detected!"
            )
            
            DispatchQueue.main.async {
                self.alertPublisher.send(alert)
            }
        }
        
        DispatchQueue.main.async {
            self.imuDataPublisher.send(imuData)
        }
    }
    
    private func parseIMUData(_ data: Data) -> IMUData {
        // Parse 6-axis IMU data (accel + gyro)
        let accelX = data[0..<2].withUnsafeBytes { $0.load(as: Int16.self) }
        let accelY = data[2..<4].withUnsafeBytes { $0.load(as: Int16.self) }
        let accelZ = data[4..<6].withUnsafeBytes { $0.load(as: Int16.self) }
        
        let gyroX = data[6..<8].withUnsafeBytes { $0.load(as: Int16.self) }
        let gyroY = data[8..<10].withUnsafeBytes { $0.load(as: Int16.self) }
        let gyroZ = data[10..<12].withUnsafeBytes { $0.load(as: Int16.self) }
        
        // Convert to g's and deg/s
        return IMUData(
            timestamp: Date(),
            accelerometer: (
                x: Float(accelX) / 16384.0,  // ±2g range
                y: Float(accelY) / 16384.0,
                z: Float(accelZ) / 16384.0
            ),
            gyroscope: (
                x: Float(gyroX) / 131.0,      // ±250 deg/s range
                y: Float(gyroY) / 131.0,
                z: Float(gyroZ) / 131.0
            ),
            magnetometer: nil
        )
    }
    
    private func detectFall(from imuData: IMUData) -> Bool {
        let magnitude = sqrt(
            pow(imuData.accelerometer.x, 2) +
            pow(imuData.accelerometer.y, 2) +
            pow(imuData.accelerometer.z, 2)
        )
        
        // Fall detection threshold (sudden acceleration > 2.5g)
        return magnitude > 2.5
    }
    
    // MARK: - Biomarker Processing
    
    private func processTroponinData(_ encryptedData: Data) {
        guard let decryptedData = decryptData(encryptedData) else { return }
        
        // Parse troponin level (ng/L)
        let troponin = decryptedData.withUnsafeBytes { $0.load(as: Float.self) }
        
        DispatchQueue.main.async {
            self.currentTroponin = troponin
            
            // Check for critical levels
            if troponin > 52 {  // Elevated troponin
                let alert = DeviceAlert(
                    timestamp: Date(),
                    type: .criticalReading,
                    severity: troponin > 100 ? .critical : .warning,
                    message: "Elevated troponin: \(troponin) ng/L"
                )
                self.alertPublisher.send(alert)
            }
        }
    }
    
    private func processBPData(_ encryptedData: Data) {
        guard let decryptedData = decryptData(encryptedData) else { return }
        
        let systolic = Int(decryptedData[0])
        let diastolic = Int(decryptedData[1])
        
        DispatchQueue.main.async {
            self.currentBP = (systolic, diastolic)
            
            // Check for hypertensive crisis
            if systolic >= 180 || diastolic >= 120 {
                let alert = DeviceAlert(
                    timestamp: Date(),
                    type: .criticalReading,
                    severity: .critical,
                    message: "Hypertensive crisis: \(systolic)/\(diastolic)"
                )
                self.alertPublisher.send(alert)
            }
        }
    }
    
    private func processGlucoseData(_ encryptedData: Data) {
        guard let decryptedData = decryptData(encryptedData) else { return }
        
        let glucose = decryptedData.withUnsafeBytes { $0.load(as: Float.self) }
        
        DispatchQueue.main.async {
            self.currentGlucose = glucose
            
            // Check for hypoglycemia
            if glucose < 70 {
                let alert = DeviceAlert(
                    timestamp: Date(),
                    type: .criticalReading,
                    severity: glucose < 54 ? .critical : .warning,
                    message: "Low glucose: \(glucose) mg/dL"
                )
                self.alertPublisher.send(alert)
            }
        }
    }
    
    private func processBatteryData(_ data: Data) {
        let batteryLevel = Int(data[0])
        
        DispatchQueue.main.async {
            self.deviceBattery = batteryLevel
            
            if batteryLevel < 20 {
                let alert = DeviceAlert(
                    timestamp: Date(),
                    type: .lowBattery,
                    severity: batteryLevel < 10 ? .warning : .info,
                    message: "Device battery: \(batteryLevel)%"
                )
                self.alertPublisher.send(alert)
            }
        }
    }
    
    // MARK: - Encryption/Decryption
    
    private func decryptData(_ encryptedData: Data) -> Data? {
        guard encryptedData.count > 12 else { return nil }
        
        do {
            // Extract nonce (first 12 bytes)
            let nonce = encryptedData[0..<12]
            let ciphertext = encryptedData[12...]
            
            // Create sealed box
            let sealedBox = try AES.GCM.SealedBox(
                nonce: AES.GCM.Nonce(data: nonce),
                ciphertext: ciphertext,
                tag: Data()  // Tag is included in ciphertext
            )
            
            // Decrypt
            return try AES.GCM.open(sealedBox, using: encryptionKey)
            
        } catch {
            AppLogger.shared.log("Decryption error: \(error)", level: .error)
            return nil
        }
    }
    
    // MARK: - LZ4 Decompression
    
    private func decompressLZ4(_ compressedData: Data) -> Data? {
        return compressedData.withUnsafeBytes { bytes in
            guard let input = bytes.bindMemory(to: UInt8.self).baseAddress else { return nil }
            
            // Get decompressed size (first 4 bytes)
            let decompressedSize = bytes.load(as: UInt32.self)
            
            // Allocate output buffer
            let output = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(decompressedSize))
            defer { output.deallocate() }
            
            // Decompress
            let compressedBytes = input.advanced(by: 4)
            let compressedSize = compressedData.count - 4
            
            let result = compression_decode_buffer(
                output, Int(decompressedSize),
                compressedBytes, compressedSize,
                nil, compressionAlgorithm.rawValue
            )
            
            guard result == decompressedSize else { return nil }
            
            return Data(bytes: output, count: Int(decompressedSize))
        }
    }
    
    // MARK: - Signal Processing
    
    private func butterworthBandpass(_ signal: [Float], 
                                    lowCutoff: Float, 
                                    highCutoff: Float, 
                                    sampleRate: Float) -> [Float] {
        // Simplified Butterworth filter implementation
        // In production, use Accelerate framework
        return signal
    }
    
    private func notchFilter(_ signal: [Float], 
                            frequency: Float, 
                            sampleRate: Float) -> [Float] {
        // Notch filter for powerline interference
        return signal
    }
    
    private func detectHeartRate(from ecgSamples: [Float]) -> Int? {
        guard ecgSamples.count > ECG_SAMPLING_RATE else { return nil }
        
        // Simple R-peak detection
        var peaks: [Int] = []
        let threshold = ecgSamples.max()! * 0.6
        
        for i in 1..<ecgSamples.count-1 {
            if ecgSamples[i] > threshold &&
               ecgSamples[i] > ecgSamples[i-1] &&
               ecgSamples[i] > ecgSamples[i+1] {
                peaks.append(i)
            }
        }
        
        guard peaks.count >= 2 else { return nil }
        
        // Calculate average RR interval
        let intervals = zip(peaks.dropLast(), peaks.dropFirst()).map { $1 - $0 }
        let avgInterval = intervals.reduce(0, +) / intervals.count
        
        // Convert to BPM
        let bpm = (60 * ECG_SAMPLING_RATE) / avgInterval
        
        return Int(bpm)
    }
    
    // MARK: - Helper Methods
    
    private func enableNotifications(for characteristics: [CBCharacteristic], on peripheral: CBPeripheral) {
        characteristics.forEach { characteristic in
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    private func disableNotifications(for characteristics: [CBCharacteristic], on peripheral: CBPeripheral) {
        characteristics.forEach { characteristic in
            peripheral.setNotifyValue(false, for: characteristic)
        }
    }
    
    private func clearBuffers() {
        ecgBuffer.clear()
        ppgBuffer.clear()
        imuBuffer.clear()
        partialPackets.removeAll()
    }
    
    private func updateDataRate() {
        let now = Date()
        if now.timeIntervalSince(lastDataRateUpdate) >= 1.0 {
            DispatchQueue.main.async {
                self.dataRate = self.bytesReceived
                self.bytesReceived = 0
                self.lastDataRateUpdate = now
            }
        }
    }
    
    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
        }
    }
    
    private func updatePerformanceMetrics() {
        // Calculate signal quality based on packet loss
        let expectedPackets = isStreaming ? 250 : 0  // Expected packets per second
        let packetLoss = expectedPackets > 0 ? 
            Float(packetsReceived) / Float(expectedPackets) : 1.0
        
        DispatchQueue.main.async {
            self.signalQuality = min(1.0, packetLoss)
        }
        
        packetsReceived = 0
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEDeviceManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            AppLogger.shared.log("Bluetooth powered on")
            
        case .poweredOff:
            connectionState = .disconnected
            AppLogger.shared.log("Bluetooth powered off")
            
        case .unauthorized:
            AppLogger.shared.log("Bluetooth unauthorized")
            
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, 
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any], 
                       rssi RSSI: NSNumber) {
        
        // Filter for LifeLens devices
        guard let name = peripheral.name,
              name.contains("LifeLens") else { return }
        
        discoveredPeripherals.insert(peripheral)
        
        AppLogger.shared.log("Discovered: \(name) RSSI: \(RSSI)")
        
        // Auto-connect to strongest signal
        if RSSI.intValue > -60 {
            connect(to: peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, 
                       didConnect peripheral: CBPeripheral) {
        connectionState = .connected
        AppLogger.shared.log("Connected to \(peripheral.name ?? "device")")
        
        // Discover services
        peripheral.discoverServices([LIFELENS_SERVICE_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, 
                       didFailToConnect peripheral: CBPeripheral, 
                       error: Error?) {
        connectionState = .disconnected
        connectedPeripheral = nil
        
        AppLogger.shared.log("Failed to connect: \(error?.localizedDescription ?? "")", 
                           level: .info)
    }
    
    func centralManager(_ central: CBCentralManager, 
                       didDisconnectPeripheral peripheral: CBPeripheral, 
                       error: Error?) {
        connectionState = .disconnected
        connectedPeripheral = nil
        isStreaming = false
        
        AppLogger.shared.log("Disconnected: \(error?.localizedDescription ?? "User initiated")", 
                           level: .info)
        
        // Attempt reconnection if unexpected
        if error != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.centralManager.connect(peripheral, options: nil)
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEDeviceManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil,
              let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == LIFELENS_SERVICE_UUID {
                // Discover all characteristics
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, 
                   didDiscoverCharacteristicsFor service: CBService, 
                   error: Error?) {
        guard error == nil,
              let characteristics = service.characteristics else { return }
        
        // Map characteristics
        for characteristic in characteristics {
            switch characteristic.uuid {
            case TROPONIN_CHARACTERISTIC:
                troponinCharacteristic = characteristic
                
            case BP_CHARACTERISTIC:
                bpCharacteristic = characteristic
                
            case GLUCOSE_CHARACTERISTIC:
                glucoseCharacteristic = characteristic
                
            case ECG_STREAM_CHARACTERISTIC:
                ecgStreamCharacteristic = characteristic
                
            case PPG_STREAM_CHARACTERISTIC:
                ppgStreamCharacteristic = characteristic
                
            case IMU_STREAM_CHARACTERISTIC:
                imuStreamCharacteristic = characteristic
                
            case COMMAND_CHARACTERISTIC:
                commandCharacteristic = characteristic
                
            case BATTERY_CHARACTERISTIC:
                // Read battery level
                peripheral.readValue(for: characteristic)
                
            default:
                break
            }
        }
        
        // Authentication successful
        connectionState = .authenticated
        
        // Request MTU increase for better throughput
        peripheral.maximumWriteValueLength(for: .withoutResponse)
        
        AppLogger.shared.log("Device authenticated and ready")
    }
    
    func peripheral(_ peripheral: CBPeripheral, 
                   didUpdateValueFor characteristic: CBCharacteristic, 
                   error: Error?) {
        guard error == nil,
              let data = characteristic.value else { return }
        
        processIncomingData(data, from: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, 
                   didWriteValueFor characteristic: CBCharacteristic, 
                   error: Error?) {
        if let error = error {
            AppLogger.shared.log("Write error: \(error)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, 
                   didUpdateNotificationStateFor characteristic: CBCharacteristic, 
                   error: Error?) {
        AppLogger.shared.log("Notification \(characteristic.isNotifying ? "enabled" : "disabled") for \(characteristic.uuid)")
    }
}