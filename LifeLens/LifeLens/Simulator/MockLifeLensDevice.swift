import Foundation
import CoreBluetooth
import Combine
import CryptoKit
import Compression
import Accelerate

// MARK: - GATT Service and Characteristics
struct LifeLensGATT {
    static let serviceUUID = CBUUID(string: "00001810-0000-1000-8000-00805F9B34FB")
    
    // Characteristics
    static let ecgCharacteristic = CBUUID(string: "00002A37-0000-1000-8000-00805F9B34FB")
    static let troponinCharacteristic = CBUUID(string: "00002A38-0000-1000-8000-00805F9B34FB")
    static let glucoseCharacteristic = CBUUID(string: "00002A39-0000-1000-8000-00805F9B34FB")
    static let lactateCharacteristic = CBUUID(string: "00002A3A-0000-1000-8000-00805F9B34FB")
    static let cortisolCharacteristic = CBUUID(string: "00002A3B-0000-1000-8000-00805F9B34FB")
    static let temperatureCharacteristic = CBUUID(string: "00002A3C-0000-1000-8000-00805F9B34FB")
    static let spo2Characteristic = CBUUID(string: "00002A3D-0000-1000-8000-00805F9B34FB")
    static let bloodPressureCharacteristic = CBUUID(string: "00002A3E-0000-1000-8000-00805F9B34FB")
    static let accelerometerCharacteristic = CBUUID(string: "00002A3F-0000-1000-8000-00805F9B34FB")
    static let cartridgeStatusCharacteristic = CBUUID(string: "00002A40-0000-1000-8000-00805F9B34FB")
    static let deviceInfoCharacteristic = CBUUID(string: "00002A41-0000-1000-8000-00805F9B34FB")
    static let batteryCharacteristic = CBUUID(string: "00002A42-0000-1000-8000-00805F9B34FB")
    
    // Descriptors
    static let clientConfigDescriptor = CBUUID(string: "00002902-0000-1000-8000-00805F9B34FB")
}

// MARK: - Patient Profiles
enum PatientProfile {
    case healthy
    case atrialFibrillation
    case myocardialInfarction
    case heartFailure
    case diabetic
    case hypertensive
    case athlete
    case elderly
    case stressTest
    case sleepMode
}

// MARK: - Data Models
struct SensorData {
    let timestamp: Date
    let ecgSamples: [Float]
    let heartRate: Int
    let heartRateVariability: Float
    let troponinI: Float
    let troponinT: Float
    let glucose: Float
    let lactate: Float
    let cortisol: Float
    let temperature: Float
    let spo2: Int
    let systolicBP: Int
    let diastolicBP: Int
    let accelerometer: [Float]
    let respiratoryRate: Int
    let qualityScore: Float
}

struct CartridgeStatus {
    let id: String
    let type: CartridgeType
    var remainingTests: Int
    let expiryDate: Date
    let calibrationDate: Date
    let lotNumber: String
    var isExpired: Bool
    var needsCalibration: Bool
    var temperature: Float
    var humidity: Float
    
    init(type: CartridgeType = .standard) {
        self.id = UUID().uuidString
        self.type = type
        self.remainingTests = 100
        self.expiryDate = Date(timeIntervalSinceNow: 90 * 24 * 60 * 60)
        self.calibrationDate = Date()
        self.lotNumber = "LOT-2024-\(Int.random(in: 1000...9999))"
        self.isExpired = false
        self.needsCalibration = false
        self.temperature = 25.0
        self.humidity = 45.0
    }
}

enum CartridgeType {
    case standard
    case highSensitivity
    case rapidTest
    case extendedPanel
    case researchGrade
}

struct DeviceInfo {
    let serialNumber: String
    let firmwareVersion: String
    let hardwareVersion: String
    let modelNumber: String
    let manufacturer: String
    let regulatoryInfo: String
    let lastCalibration: Date
    var uptime: TimeInterval
    let totalMeasurements: Int
    
    init() {
        self.serialNumber = "LLS-\(Int.random(in: 100000...999999))"
        self.firmwareVersion = "2.1.0"
        self.hardwareVersion = "1.0"
        self.modelNumber = "LifeLens-Pro"
        self.manufacturer = "LifeLens Medical Inc."
        self.regulatoryInfo = "FDA 510(k) K123456"
        self.lastCalibration = Date()
        self.uptime = 0
        self.totalMeasurements = Int.random(in: 1000...10000)
    }
}

// MARK: - MockLifeLensDevice
class MockLifeLensDevice: NSObject {
    
    // Device Properties
    private let deviceName: String
    private var peripheralManager: CBPeripheralManager?
    private var service: CBMutableService?
    
    // State Management
    private var isAdvertising = false
    private var connectedCentrals = Set<CBCentral>()
    private var subscribedCentrals: [CBUUID: Set<CBCentral>] = [:]
    
    // Sensor Simulation
    private var patientProfile = PatientProfile.healthy
    private var cartridgeStatus = CartridgeStatus()
    private var deviceInfo = DeviceInfo()
    private var batteryLevel = 85
    
    // Data Generation Parameters
    private let samplingRate = 250 // Hz for ECG
    private let ecgBufferSize = 250 // 1 second of data
    private var currentHeartRate = 72
    private var isExercising = false
    private var stressLevel: Float = 0.3
    
    // Timers
    private var sensorTimer: Timer?
    private var cartridgeTimer: Timer?
    private var batteryTimer: Timer?
    
    // Combine Publishers
    private let sensorDataSubject = PassthroughSubject<SensorData, Never>()
    var sensorDataPublisher: AnyPublisher<SensorData, Never> {
        sensorDataSubject.eraseToAnyPublisher()
    }
    
    // Encryption
    private let encryptionKey = SymmetricKey(size: .bits256)
    
    init(deviceName: String? = nil) {
        self.deviceName = deviceName ?? "LifeLens-\(Int.random(in: 1000...9999))"
        super.init()
        setupPeripheralManager()
    }
    
    // MARK: - Device Lifecycle
    
    func startDevice() {
        print("Starting mock device: \(deviceName)")
        startAdvertising()
        startSensorSimulation()
        startCartridgeMonitoring()
        startBatterySimulation()
    }
    
    func stopDevice() {
        print("Stopping mock device")
        stopAdvertising()
        sensorTimer?.invalidate()
        cartridgeTimer?.invalidate()
        batteryTimer?.invalidate()
    }
    
    func setPatientProfile(_ profile: PatientProfile) {
        patientProfile = profile
        print("Patient profile changed to: \(profile)")
    }
    
    func simulateExercise(_ exercising: Bool) {
        isExercising = exercising
    }
    
    func setStressLevel(_ level: Float) {
        stressLevel = min(max(level, 0), 1)
    }
    
    func replaceCartridge(type: CartridgeType = .standard) {
        cartridgeStatus = CartridgeStatus(type: type)
        print("Cartridge replaced with type: \(type)")
    }
    
    // MARK: - Bluetooth Setup
    
    private func setupPeripheralManager() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    private func setupService() {
        let service = CBMutableService(type: LifeLensGATT.serviceUUID, primary: true)
        
        // Add characteristics
        var characteristics: [CBMutableCharacteristic] = []
        
        // ECG Characteristic
        let ecgChar = CBMutableCharacteristic(
            type: LifeLensGATT.ecgCharacteristic,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
        characteristics.append(ecgChar)
        
        // Troponin Characteristic
        let troponinChar = CBMutableCharacteristic(
            type: LifeLensGATT.troponinCharacteristic,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
        characteristics.append(troponinChar)
        
        // Glucose Characteristic
        let glucoseChar = CBMutableCharacteristic(
            type: LifeLensGATT.glucoseCharacteristic,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
        characteristics.append(glucoseChar)
        
        // Other vital signs
        for uuid in [LifeLensGATT.lactateCharacteristic,
                     LifeLensGATT.cortisolCharacteristic,
                     LifeLensGATT.temperatureCharacteristic,
                     LifeLensGATT.spo2Characteristic,
                     LifeLensGATT.bloodPressureCharacteristic,
                     LifeLensGATT.accelerometerCharacteristic] {
            let char = CBMutableCharacteristic(
                type: uuid,
                properties: [.read, .notify],
                value: nil,
                permissions: [.readable]
            )
            characteristics.append(char)
        }
        
        // Device info characteristics (read-only)
        let cartridgeChar = CBMutableCharacteristic(
            type: LifeLensGATT.cartridgeStatusCharacteristic,
            properties: [.read],
            value: nil,
            permissions: [.readable]
        )
        characteristics.append(cartridgeChar)
        
        let deviceInfoChar = CBMutableCharacteristic(
            type: LifeLensGATT.deviceInfoCharacteristic,
            properties: [.read],
            value: nil,
            permissions: [.readable]
        )
        characteristics.append(deviceInfoChar)
        
        let batteryChar = CBMutableCharacteristic(
            type: LifeLensGATT.batteryCharacteristic,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
        characteristics.append(batteryChar)
        
        service.characteristics = characteristics
        self.service = service
        
        peripheralManager?.add(service)
    }
    
    private func startAdvertising() {
        guard !isAdvertising else { return }
        
        let advertisementData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: deviceName,
            CBAdvertisementDataServiceUUIDsKey: [LifeLensGATT.serviceUUID]
        ]
        
        peripheralManager?.startAdvertising(advertisementData)
        isAdvertising = true
    }
    
    private func stopAdvertising() {
        guard isAdvertising else { return }
        peripheralManager?.stopAdvertising()
        isAdvertising = false
    }
    
    // MARK: - Sensor Data Generation
    
    private func startSensorSimulation() {
        sensorTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(samplingRate), repeats: true) { _ in
            let sensorData = self.generateSensorData()
            self.sensorDataSubject.send(sensorData)
            self.notifySubscribedCentrals(with: sensorData)
        }
    }
    
    private func generateSensorData() -> SensorData {
        let ecgSamples = generateECG()
        let (hr, hrv) = generateHeartRateMetrics()
        let (troponinI, troponinT) = generateTroponin()
        let glucose = generateGlucose()
        let lactate = generateLactate()
        let cortisol = generateCortisol()
        let temperature = generateTemperature()
        let spo2 = generateSpO2()
        let (systolic, diastolic) = generateBloodPressure()
        let accelerometer = generateAccelerometer()
        let respiratoryRate = generateRespiratoryRate()
        let qualityScore = calculateQualityScore(ecgSamples)
        
        return SensorData(
            timestamp: Date(),
            ecgSamples: ecgSamples,
            heartRate: hr,
            heartRateVariability: hrv,
            troponinI: troponinI,
            troponinT: troponinT,
            glucose: glucose,
            lactate: lactate,
            cortisol: cortisol,
            temperature: temperature,
            spo2: spo2,
            systolicBP: systolic,
            diastolicBP: diastolic,
            accelerometer: accelerometer,
            respiratoryRate: respiratoryRate,
            qualityScore: qualityScore
        )
    }
    
    private func generateECG() -> [Float] {
        var samples: [Float] = []
        let heartRateInHz = Float(currentHeartRate) / 60.0
        
        for i in 0..<ecgBufferSize {
            let t = Float(i) / Float(samplingRate)
            var ecg: Float = 0
            
            // Generate PQRST complex
            let pWaveTime = fmodf(t * heartRateInHz, 1.0)
            
            // P wave
            if pWaveTime < 0.1 {
                ecg += 0.2 * sin(.pi * pWaveTime / 0.1)
            }
            
            // QRS complex
            let qrsTime = pWaveTime - 0.15
            if qrsTime >= 0 && qrsTime < 0.08 {
                if qrsTime < 0.02 {
                    ecg -= 0.3 * sin(.pi * qrsTime / 0.02)
                } else if qrsTime < 0.04 {
                    ecg += 1.5 * sin(.pi * (qrsTime - 0.02) / 0.02)
                } else {
                    ecg -= 0.4 * sin(.pi * (qrsTime - 0.04) / 0.04)
                }
            }
            
            // T wave
            let tWaveTime = pWaveTime - 0.35
            if tWaveTime >= 0 && tWaveTime < 0.2 {
                ecg += 0.3 * sin(.pi * tWaveTime / 0.2)
            }
            
            // Add profile-specific artifacts
            ecg = addProfileArtifacts(ecg, sampleIndex: i, phase: pWaveTime)
            
            // Add realistic noise
            ecg += generateNoise() * 0.05
            
            // Add baseline wander
            ecg += 0.1 * sin(2 * .pi * 0.15 * t)
            
            samples.append(ecg)
        }
        
        return samples
    }
    
    private func addProfileArtifacts(_ baseEcg: Float, sampleIndex: Int, phase: Float) -> Float {
        var ecg = baseEcg
        
        switch patientProfile {
        case .atrialFibrillation:
            // Irregular rhythm and absent P waves
            if Float.random(in: 0...1) < 0.3 {
                ecg *= Float.random(in: 0.7...1.3)
            }
            
        case .myocardialInfarction:
            // ST elevation
            if phase >= 0.25 && phase <= 0.35 {
                ecg += 0.3
            }
            // Pathological Q waves
            if phase >= 0.13 && phase <= 0.15 {
                ecg -= 0.2
            }
            
        case .heartFailure:
            // Wide QRS complex and reduced amplitude
            ecg *= 0.84 // 1.2 * 0.7
            
        case .hypertensive:
            // Left ventricular hypertrophy pattern
            if phase >= 0.15 && phase <= 0.23 {
                ecg *= 1.3
            }
            
        case .athlete:
            // Sinus bradycardia with increased amplitude
            ecg *= 1.1
            
        default:
            break
        }
        
        // Add exercise effects
        if isExercising {
            ecg *= 1.2
            ecg += Float.random(in: -0.05...0.05) // Motion artifacts
        }
        
        // Add stress effects
        ecg *= (1.0 + stressLevel * 0.2)
        
        return ecg
    }
    
    private func generateHeartRateMetrics() -> (Int, Float) {
        let baseHR: Int
        switch patientProfile {
        case .athlete: baseHR = 55
        case .elderly: baseHR = 65
        case .atrialFibrillation: baseHR = 110
        case .myocardialInfarction: baseHR = 85
        case .heartFailure: baseHR = 80
        case .stressTest: baseHR = 95
        case .sleepMode: baseHR = 58
        default: baseHR = 72
        }
        
        let exerciseHR = isExercising ? 40 : 0
        let stressHR = Int(stressLevel * 20)
        let variation = Int.random(in: -5...5)
        
        currentHeartRate = min(max(baseHR + exerciseHR + stressHR + variation, 40), 180)
        
        // Calculate HRV (RMSSD in ms)
        let baseHRV: Float
        switch patientProfile {
        case .athlete: baseHRV = 55
        case .elderly: baseHRV = 25
        case .heartFailure: baseHRV = 15
        case .diabetic: baseHRV = 20
        case .stressTest: baseHRV = 18
        default: baseHRV = 35
        }
        
        let hrv = baseHRV * (1 - stressLevel * 0.5) * (isExercising ? 0.6 : 1.0)
        
        return (currentHeartRate, hrv)
    }
    
    private func generateTroponin() -> (Float, Float) {
        let baseTnI: Float
        let baseTnT: Float
        
        switch patientProfile {
        case .myocardialInfarction:
            baseTnI = 2.5
            baseTnT = 0.8
        case .heartFailure:
            baseTnI = 0.5
            baseTnT = 0.15
        case .athlete:
            baseTnI = 0.03
            baseTnT = 0.02
        default:
            baseTnI = 0.01
            baseTnT = 0.01
        }
        
        let exerciseFactor: Float = isExercising ? 1.5 : 1.0
        let tnI = baseTnI * exerciseFactor * Float.random(in: 0.9...1.1)
        let tnT = baseTnT * exerciseFactor * Float.random(in: 0.9...1.1)
        
        return (tnI, tnT)
    }
    
    private func generateGlucose() -> Float {
        let baseGlucose: Float
        switch patientProfile {
        case .diabetic: baseGlucose = 180
        case .athlete: baseGlucose = isExercising ? 85 : 95
        case .stressTest: baseGlucose = 110
        default: baseGlucose = 95
        }
        
        // Add meal effect simulation
        let hour = Calendar.current.component(.hour, from: Date())
        let mealEffect: Float = (hour == 8 || hour == 13 || hour == 19) ? 30 : 0
        
        let stressEffect = stressLevel * 15
        
        return baseGlucose + mealEffect + stressEffect + Float.random(in: -5...5)
    }
    
    private func generateLactate() -> Float {
        let baseLactate: Float
        if isExercising {
            baseLactate = 4.5
        } else {
            switch patientProfile {
            case .athlete: baseLactate = 1.2
            case .heartFailure: baseLactate = 2.8
            default: baseLactate = 1.5
            }
        }
        
        return baseLactate + Float.random(in: -0.15...0.15)
    }
    
    private func generateCortisol() -> Float {
        // Cortisol follows circadian rhythm
        let hour = Calendar.current.component(.hour, from: Date())
        let circadianFactor: Float
        switch hour {
        case 6...9: circadianFactor = 1.5 // Morning peak
        case 10...16: circadianFactor = 1.0
        case 17...22: circadianFactor = 0.7
        default: circadianFactor = 0.5 // Night low
        }
        
        let baseCortisol: Float = 15 * circadianFactor
        let stressCortisol = baseCortisol * (1 + stressLevel)
        
        return stressCortisol + Float.random(in: -1...1)
    }
    
    private func generateTemperature() -> Float {
        let baseTemp: Float
        if isExercising {
            baseTemp = 37.8
        } else if patientProfile == .myocardialInfarction {
            baseTemp = 37.5
        } else {
            baseTemp = 36.8
        }
        
        return baseTemp + Float.random(in: -0.1...0.1)
    }
    
    private func generateSpO2() -> Int {
        let baseSpO2: Int
        switch patientProfile {
        case .heartFailure: baseSpO2 = 93
        case .elderly: baseSpO2 = 95
        case .sleepMode: baseSpO2 = 96
        case .athlete: baseSpO2 = isExercising ? 97 : 99
        default: baseSpO2 = 98
        }
        
        return min(max(baseSpO2 + Int.random(in: -1...1), 88), 100)
    }
    
    private func generateBloodPressure() -> (Int, Int) {
        let baseSystolic: Int
        let baseDiastolic: Int
        
        switch patientProfile {
        case .hypertensive:
            baseSystolic = 145
            baseDiastolic = 95
        case .athlete:
            baseSystolic = 110
            baseDiastolic = 65
        case .elderly:
            baseSystolic = 135
            baseDiastolic = 85
        case .heartFailure:
            baseSystolic = 105
            baseDiastolic = 65
        default:
            baseSystolic = 120
            baseDiastolic = 80
        }
        
        let exerciseSystolic = isExercising ? 30 : 0
        let exerciseDiastolic = isExercising ? 10 : 0
        let stressSystolic = Int(stressLevel * 15)
        let stressDiastolic = Int(stressLevel * 10)
        
        let systolic = min(max(baseSystolic + exerciseSystolic + stressSystolic + Int.random(in: -5...5), 80), 200)
        let diastolic = min(max(baseDiastolic + exerciseDiastolic + stressDiastolic + Int.random(in: -3...3), 50), 120)
        
        return (systolic, diastolic)
    }
    
    private func generateAccelerometer() -> [Float] {
        let activity: Float
        if isExercising {
            activity = 2.5
        } else if patientProfile == .sleepMode {
            activity = 0.1
        } else {
            activity = 0.5
        }
        
        return [
            activity * Float.random(in: -0.5...0.5),
            activity * Float.random(in: -0.5...0.5),
            9.8 + activity * Float.random(in: -0.5...0.5) // Gravity + motion
        ]
    }
    
    private func generateRespiratoryRate() -> Int {
        let baseRate: Int
        if isExercising {
            baseRate = 25
        } else {
            switch patientProfile {
            case .heartFailure: baseRate = 20
            case .sleepMode: baseRate = 12
            default: baseRate = 16
            }
        }
        
        return baseRate + Int.random(in: -2...2)
    }
    
    private func generateNoise() -> Float {
        // Combine different noise sources
        let whiteNoise = Float.random(in: -0.5...0.5)
        let powerlineNoise = sin(2 * .pi * 60 * Float(Date().timeIntervalSince1970)) * 0.1
        let muscleNoise = isExercising ? Float.random(in: -0.15...0.15) : 0
        
        return whiteNoise + powerlineNoise + muscleNoise
    }
    
    private func calculateQualityScore(_ ecgSamples: [Float]) -> Float {
        // Calculate signal-to-noise ratio
        let signal = ecgSamples.map { abs($0) }.reduce(0, +) / Float(ecgSamples.count)
        let noise = zip(ecgSamples.dropLast(), ecgSamples.dropFirst())
            .map { abs($1 - $0) }
            .reduce(0, +) / Float(ecgSamples.count - 1)
        
        let snr = noise > 0 ? signal / noise : 10
        
        // Convert to quality score (0-1)
        return min(max(snr / 10, 0), 1)
    }
    
    // MARK: - Cartridge Lifecycle
    
    private func startCartridgeMonitoring() {
        cartridgeTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateCartridgeStatus()
        }
    }
    
    private func updateCartridgeStatus() {
        cartridgeStatus.remainingTests = max(0, cartridgeStatus.remainingTests - 1)
        cartridgeStatus.isExpired = Date() > cartridgeStatus.expiryDate
        cartridgeStatus.needsCalibration = Float.random(in: 0...1) < 0.01 // 1% chance
        cartridgeStatus.temperature = 25 + Float.random(in: -1...1)
        cartridgeStatus.humidity = 45 + Float.random(in: -5...5)
        
        if cartridgeStatus.remainingTests == 0 {
            print("Warning: Cartridge depleted - needs replacement")
        }
        
        if cartridgeStatus.isExpired {
            print("Warning: Cartridge expired - needs replacement")
        }
    }
    
    // MARK: - Battery Simulation
    
    private func startBatterySimulation() {
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.batteryLevel = max(0, self.batteryLevel - 1)
            if self.batteryLevel < 20 {
                print("Warning: Low battery: \(self.batteryLevel)%")
            }
            self.notifyBatteryLevel()
        }
    }
    
    func chargeBattery() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { timer in
            self.batteryLevel = min(100, self.batteryLevel + 5)
            if self.batteryLevel >= 100 {
                timer.invalidate()
            }
            self.notifyBatteryLevel()
        }
    }
    
    // MARK: - Data Encoding
    
    private func encryptData(_ data: Data) -> Data {
        do {
            let sealed = try AES.GCM.seal(data, using: encryptionKey)
            return sealed.combined ?? data
        } catch {
            print("Encryption failed: \(error)")
            return data
        }
    }
    
    private func compressData(_ data: Data) -> Data {
        guard let compressed = data.compressed(using: .lz4) else { return data }
        return compressed
    }
    
    private func encodeECG(_ samples: [Float]) -> Data {
        var data = Data()
        let timestamp = Date().timeIntervalSince1970
        data.append(contentsOf: withUnsafeBytes(of: timestamp) { Array($0) })
        
        for sample in samples {
            data.append(contentsOf: withUnsafeBytes(of: sample) { Array($0) })
        }
        
        return data
    }
    
    private func encodeTroponin(_ sensorData: SensorData) -> Data {
        var data = Data()
        let timestamp = sensorData.timestamp.timeIntervalSince1970
        data.append(contentsOf: withUnsafeBytes(of: timestamp) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: sensorData.troponinI) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: sensorData.troponinT) { Array($0) })
        return data
    }
    
    private func encodeDeviceInfo() -> Data {
        let info: [String: Any] = [
            "serialNumber": deviceInfo.serialNumber,
            "firmwareVersion": deviceInfo.firmwareVersion,
            "hardwareVersion": deviceInfo.hardwareVersion,
            "modelNumber": deviceInfo.modelNumber,
            "manufacturer": deviceInfo.manufacturer
        ]
        
        return (try? JSONSerialization.data(withJSONObject: info)) ?? Data()
    }
    
    private func encodeCartridgeStatus() -> Data {
        let status: [String: Any] = [
            "id": cartridgeStatus.id,
            "type": "\(cartridgeStatus.type)",
            "remainingTests": cartridgeStatus.remainingTests,
            "expiryDate": cartridgeStatus.expiryDate.timeIntervalSince1970,
            "isExpired": cartridgeStatus.isExpired
        ]
        
        return (try? JSONSerialization.data(withJSONObject: status)) ?? Data()
    }
    
    // MARK: - Notification Handling
    
    private func notifySubscribedCentrals(with sensorData: SensorData) {
        guard let peripheralManager = peripheralManager,
              peripheralManager.state == .poweredOn else { return }
        
        // ECG notification
        notifyCharacteristic(LifeLensGATT.ecgCharacteristic, data: encodeECG(sensorData.ecgSamples))
        
        // Troponin notification
        notifyCharacteristic(LifeLensGATT.troponinCharacteristic, data: encodeTroponin(sensorData))
        
        // Other notifications
        var glucoseData = Data()
        glucoseData.append(contentsOf: withUnsafeBytes(of: sensorData.glucose) { Array($0) })
        notifyCharacteristic(LifeLensGATT.glucoseCharacteristic, data: glucoseData)
        
        notifyCharacteristic(LifeLensGATT.spo2Characteristic, data: Data([UInt8(sensorData.spo2)]))
    }
    
    private func notifyCharacteristic(_ uuid: CBUUID, data: Data) {
        guard let characteristic = service?.characteristics?.first(where: { $0.uuid == uuid }) as? CBMutableCharacteristic else { return }
        
        let processedData = compressData(encryptData(data))
        
        let centrals = subscribedCentrals[uuid] ?? []
        for central in centrals {
            peripheralManager?.updateValue(processedData, for: characteristic, onSubscribedCentrals: [central])
        }
    }
    
    private func notifyBatteryLevel() {
        notifyCharacteristic(LifeLensGATT.batteryCharacteristic, data: Data([UInt8(batteryLevel)]))
    }
}

// MARK: - CBPeripheralManagerDelegate
extension MockLifeLensDevice: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peripheral manager powered on")
            setupService()
            startAdvertising()
        case .poweredOff:
            print("Peripheral manager powered off")
            stopAdvertising()
        default:
            print("Peripheral manager state: \(peripheral.state)")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("Failed to add service: \(error)")
        } else {
            print("Service added successfully")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Failed to start advertising: \(error)")
        } else {
            print("Started advertising successfully")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Central subscribed to \(characteristic.uuid)")
        
        if subscribedCentrals[characteristic.uuid] == nil {
            subscribedCentrals[characteristic.uuid] = Set<CBCentral>()
        }
        subscribedCentrals[characteristic.uuid]?.insert(central)
        connectedCentrals.insert(central)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Central unsubscribed from \(characteristic.uuid)")
        subscribedCentrals[characteristic.uuid]?.remove(central)
        
        // Check if central is still subscribed to any characteristic
        let stillSubscribed = subscribedCentrals.values.contains { $0.contains(central) }
        if !stillSubscribed {
            connectedCentrals.remove(central)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Received read request for \(request.characteristic.uuid)")
        
        var responseData: Data?
        
        switch request.characteristic.uuid {
        case LifeLensGATT.deviceInfoCharacteristic:
            responseData = encodeDeviceInfo()
        case LifeLensGATT.cartridgeStatusCharacteristic:
            responseData = encodeCartridgeStatus()
        case LifeLensGATT.batteryCharacteristic:
            responseData = Data([UInt8(batteryLevel)])
        default:
            break
        }
        
        if let data = responseData {
            request.value = data
            peripheral.respond(to: request, withResult: .success)
        } else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            print("Received write request for \(request.characteristic.uuid)")
            peripheral.respond(to: request, withResult: .success)
        }
    }
}