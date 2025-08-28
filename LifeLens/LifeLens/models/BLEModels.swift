// Models/BLEModels.swift
import Foundation
import CoreBluetooth

// MARK: - LifeLens Device UUIDs
struct LifeLensUUIDs {
    // Service UUIDs
    static let primaryService = CBUUID(string: "00001800-0000-1000-8000-00805F9B34FB")
    static let dataService = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    // Characteristic UUIDs
    static let troponinCharacteristic = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static let ecgCharacteristic = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    static let bpCharacteristic = CBUUID(string: "6E400004-B5A3-F393-E0A9-E50E24DCCA9E")
    static let glucoseCharacteristic = CBUUID(string: "6E400005-B5A3-F393-E0A9-E50E24DCCA9E")
    static let spo2Characteristic = CBUUID(string: "6E400006-B5A3-F393-E0A9-E50E24DCCA9E")
    static let temperatureCharacteristic = CBUUID(string: "6E400007-B5A3-F393-E0A9-E50E24DCCA9E")
    static let batteryCharacteristic = CBUUID(string: "6E400008-B5A3-F393-E0A9-E50E24DCCA9E")
    static let commandCharacteristic = CBUUID(string: "6E400009-B5A3-F393-E0A9-E50E24DCCA9E")
}

// MARK: - Device Models
struct LifeLensDevice: Identifiable, Codable {
    let id: UUID
    let name: String
    let serialNumber: String
    let firmwareVersion: String
    var batteryLevel: Int
    var isConnected: Bool
    var lastSyncDate: Date?
    var signalStrength: Int // RSSI value
    
    init(peripheral: CBPeripheral) {
        self.id = UUID()
        self.name = peripheral.name ?? "LifeLens Device"
        self.serialNumber = peripheral.identifier.uuidString
        self.firmwareVersion = "1.0.0"
        self.batteryLevel = 100
        self.isConnected = false
        self.lastSyncDate = nil
        self.signalStrength = -50
    }
}

// MARK: - Sensor Data Models
struct TroponinData: Codable {
    let timestamp: Date
    let troponinI: Double // ng/mL
    let troponinT: Double // ng/mL
    let confidence: Double // 0-1
    let riskScore: Double // 0-100
}

struct ECGData: Codable {
    let timestamp: Date
    let samples: [Double] // Raw ECG samples at 500Hz
    let heartRate: Int // BPM
    let prInterval: Int? // milliseconds
    let qrsComplex: Int? // milliseconds
    let qtInterval: Int? // milliseconds
    let stDeviation: Double? // mm
    let arrhythmiaDetected: Bool
    let arrhythmiaType: String?
}

struct BloodPressureData: Codable {
    let timestamp: Date
    let systolic: Int // mmHg
    let diastolic: Int // mmHg
    let meanArterialPressure: Int // mmHg
    let pulseWaveVelocity: Double? // m/s
    let confidence: Double // 0-1
}

struct GlucoseData: Codable {
    let timestamp: Date
    let glucoseLevel: Double // mg/dL
    let trend: GlucoseTrend
    let rateOfChange: Double // mg/dL/min
    let predictedLow: Date? // Time of predicted hypoglycemia
    let predictedHigh: Date? // Time of predicted hyperglycemia
    
    enum GlucoseTrend: String, Codable {
        case rapidlyRising = "rapidly_rising"
        case rising = "rising"
        case stable = "stable"
        case falling = "falling"
        case rapidlyFalling = "rapidly_falling"
    }
}

struct SpO2Data: Codable {
    let timestamp: Date
    let oxygenSaturation: Int // Percentage
    let perfusionIndex: Double
    let respiratoryRate: Int? // breaths/min
    let confidence: Double // 0-1
}

struct TemperatureData: Codable {
    let timestamp: Date
    let temperature: Double // Celsius
    let location: MeasurementLocation
    
    enum MeasurementLocation: String, Codable {
        case wrist = "wrist"
        case forehead = "forehead"
        case ambient = "ambient"
    }
}

// MARK: - Composite Health Data
struct BLEHealthSnapshot: Codable {  // Renamed to avoid conflict with SharedTypes
    let timestamp: Date
    let deviceId: String
    let troponin: TroponinData?
    let ecg: ECGData?
    let bloodPressure: BloodPressureData?
    let glucose: GlucoseData?
    let spo2: SpO2Data?
    let temperature: TemperatureData?
    let riskScores: RiskScores
    let alerts: [HealthAlert]
}

struct RiskScores: Codable {
    let overall: Double // 0-100
    let cardiac: Double // 0-100
    let metabolic: Double // 0-100
    let respiratory: Double // 0-100
    let trend: RiskTrend
    
    enum RiskTrend: String, Codable {
        case improving = "improving"
        case stable = "stable"
        case worsening = "worsening"
        case critical = "critical"
    }
}

struct DeviceHealthAlert: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let severity: AlertSeverity
    let type: AlertType
    let title: String
    let message: String
    let actionRequired: Bool
    let predictedTimeToEvent: TimeInterval? // seconds
    
    enum AlertSeverity: String, Codable {
        case info = "info"
        case warning = "warning"
        case urgent = "urgent"
        case critical = "critical"
        case emergency = "emergency"
    }
    
    enum AlertType: String, Codable {
        case troponinElevation = "troponin_elevation"
        case arrhythmia = "arrhythmia"
        case hypoglycemia = "hypoglycemia"
        case hyperglycemia = "hyperglycemia"
        case hypertension = "hypertension"
        case hypotension = "hypotension"
        case hypoxia = "hypoxia"
        case predictiveMI = "predictive_mi"
        case deviceIssue = "device_issue"
    }
}

// MARK: - BLE Communication Protocol
enum BLECommand: UInt8 {
    case startStreaming = 0x01
    case stopStreaming = 0x02
    case syncTime = 0x03
    case requestBattery = 0x04
    case performCalibration = 0x05
    case factoryReset = 0x06
    case firmwareUpdate = 0x07
    case setStreamingRate = 0x08
    case requestDeviceInfo = 0x09
    case emergencyMode = 0x0A
}

struct BLEPacket {
    let command: BLECommand
    let payload: Data
    
    func toData() -> Data {
        var data = Data()
        data.append(command.rawValue)
        data.append(payload)
        return data
    }
    
    static func parse(_ data: Data) -> BLEPacket? {
        guard data.count >= 1,
              let command = BLECommand(rawValue: data[0]) else {
            return nil
        }
        let payload = data.count > 1 ? data.subdata(in: 1..<data.count) : Data()
        return BLEPacket(command: command, payload: payload)
    }
}

// MARK: - Connection State
enum BLEConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case connected
    case syncing
    case streaming
    case error(String)
    
    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .scanning:
            return "Searching for device..."
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .syncing:
            return "Syncing data..."
        case .streaming:
            return "Streaming live data"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .connected, .syncing, .streaming:
            return true
        default:
            return false
        }
    }
}