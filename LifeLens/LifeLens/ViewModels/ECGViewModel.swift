// ECGViewModel.swift
// Consolidated ECG View Model for all ECG-related views

import Foundation
import SwiftUI
import Combine
import HealthKit

public class ECGViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var waveformData: [CGFloat] = []
    @Published public var heartRate: Int = 0
    @Published public var isRecording: Bool = false
    @Published public var classification: ECGReading.ECGClassification = ECGReading.ECGClassification.normal
    @Published public var recordingDuration: TimeInterval = 30.0
    @Published public var currentAmplitude: CGFloat = 0.0
    @Published public var lastReading: ECGReading?
    @Published public var alerts: [HealthAlert] = []
    
    // Additional properties for ECGMonitorView
    @Published public var ecgData: [CGFloat] = []
    @Published public var isLive: Bool = true
    @Published public var currentHeartRate: Int = 72
    @Published public var showGrid: Bool = true
    @Published public var currentSpeed: ECGSpeed = .normal
    @Published public var heartRateStatus: HeartRateStatus = .normal
    @Published public var qtInterval: Int = 400
    @Published public var prInterval: Int = 160
    @Published public var qrsWidth: Int = 80
    @Published public var qrsComplex: Int = 80
    
    // MARK: - Properties
    private let sampleRate: Double = 500.0 // Hz
    private var timer: Timer?
    private var recordingStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    private let maxDataPoints = 1500 // 3 seconds at 500Hz
    private var mockDataIndex = 0
    
    // MARK: - Mock ECG Pattern
    private let mockECGPattern: [CGFloat] = {
        var pattern: [CGFloat] = []
        
        // Generate realistic ECG waveform pattern
        // P wave
        for i in 0..<10 {
            pattern.append(sin(CGFloat(i) * .pi / 10) * 0.1)
        }
        
        // PR interval
        pattern.append(contentsOf: Array(repeating: CGFloat(0), count: 20))
        
        // QRS complex
        pattern.append(-0.1)  // Q
        pattern.append(1.0)   // R peak
        pattern.append(-0.3)  // S
        
        // ST segment
        pattern.append(contentsOf: Array(repeating: CGFloat(0), count: 20))
        
        // T wave
        for i in 0..<20 {
            pattern.append(sin(CGFloat(i) * .pi / 20) * 0.2)
        }
        
        // Baseline
        pattern.append(contentsOf: Array(repeating: CGFloat(0), count: 30))
        
        return pattern
    }()
    
    // MARK: - Initialization
    public init() {
        setupHealthKit()
        generateMockData()
    }
    
    deinit {
        stopRecording()
    }
    
    // MARK: - Public Methods
    public func startRecording() {
        isRecording = true
        recordingStartTime = Date()
        waveformData.removeAll()
        
        // Simulate ECG data streaming
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateWaveform()
        }
    }
    
    public func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        if let startTime = recordingStartTime {
            let duration = Date().timeIntervalSince(startTime)
            processRecording(duration: duration)
        }
    }
    
    public func saveReading() {
        guard let reading = lastReading else { return }
        
        // Save to HealthKit if available
        saveToHealthKit(reading)
        
        // Generate alert if abnormal
        if reading.classification != ECGReading.ECGClassification.normal {
            let alert = HealthAlert(
                title: "ECG Alert",
                message: "Abnormal ECG detected: \(reading.classification.rawValue)",
                type: .warning,
                severity: reading.classification == .afib ? .high : .medium,
                source: "ECG Monitor"
            )
            alerts.append(alert)
        }
    }
    
    public func clearData() {
        waveformData.removeAll()
        heartRate = 0
        classification = ECGReading.ECGClassification.normal
        currentAmplitude = 0.0
        lastReading = nil
    }
    
    // MARK: - Private Methods
    private func setupHealthKit() {
        // Request HealthKit permissions if needed
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let healthStore = HKHealthStore()
        let ecgType = HKObjectType.electrocardiogramType()
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        let typesToRead: Set<HKObjectType> = [ecgType, heartRateType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("HealthKit authorization successful")
            }
        }
    }
    
    private func updateWaveform() {
        // Add new data point from mock pattern
        let newValue = mockECGPattern[mockDataIndex % mockECGPattern.count]
        
        // Add some noise for realism
        let noise = CGFloat.random(in: -0.02...0.02)
        let dataPoint = newValue + noise
        
        waveformData.append(dataPoint)
        currentAmplitude = dataPoint
        
        // Limit data points
        if waveformData.count > maxDataPoints {
            waveformData.removeFirst()
        }
        
        // Update heart rate periodically
        if mockDataIndex % 30 == 0 {
            heartRate = Int.random(in: 60...80)
        }
        
        mockDataIndex += 1
    }
    
    private func processRecording(duration: TimeInterval) {
        // Simulate ECG analysis
        let randomClassification = Int.random(in: 0...100)
        
        if randomClassification < 80 {
            classification = ECGReading.ECGClassification.normal
        } else if randomClassification < 90 {
            classification = .bradycardia
        } else if randomClassification < 95 {
            classification = .tachycardia
        } else {
            classification = .afib
        }
        
        // Create reading
        lastReading = ECGReading(
            timestamp: Date(),
            samples: waveformData.map { Double($0) },
            sampleRate: sampleRate,
            classification: classification
        )
    }
    
    private func saveToHealthKit(_ reading: ECGReading) {
        // Implementation for saving to HealthKit
        // This would require proper HealthKit integration
        print("Saving ECG reading to HealthKit")
    }
    
    private func generateMockData() {
        // Generate initial mock data for display
        for _ in 0..<maxDataPoints {
            updateWaveform()
        }
        heartRate = 72
        currentHeartRate = 72
        ecgData = waveformData
    }
    
    // MARK: - Control Methods
    public func togglePlayPause() {
        isLive.toggle()
        if isLive {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    public func setSpeed(_ speed: ECGSpeed) {
        currentSpeed = speed
    }
    
    public func toggleGrid() {
        showGrid.toggle()
    }
    
    public func exportData() {
        // Export ECG data functionality
        print("Exporting ECG data...")
    }
}

// MARK: - HeartRateStatus Enum
public enum HeartRateStatus {
    case low, normal, elevated, high
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .normal: return .green
        case .elevated: return .yellow
        case .high: return .red
        }
    }
}

// MARK: - ECGSpeed Enum
public enum ECGSpeed: CaseIterable {
    case slow, normal, fast
    
    var label: String {
        switch self {
        case .slow: return "0.5x"
        case .normal: return "1x"
        case .fast: return "2x"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .slow: return 0.5
        case .normal: return 1.0
        case .fast: return 2.0
        }
    }
}

// MARK: - ECG Waveform Drawing
public struct ECGWaveformPath: Shape {
    let data: [CGFloat]
    let gridSize: CGFloat
    
    public init(data: [CGFloat], gridSize: CGFloat = 20) {
        self.data = data
        self.gridSize = gridSize
    }
    
    public func path(in rect: CGRect) -> Path {
        guard !data.isEmpty else { return Path() }
        
        var path = Path()
        let stepX = rect.width / CGFloat(data.count - 1)
        let midY = rect.height / 2
        let scale = rect.height / 4 // Scale factor for amplitude
        
        for (index, value) in data.enumerated() {
            let x = CGFloat(index) * stepX
            let y = midY - (value * scale)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}

// MARK: - ECG Grid View
public struct ECGGridView: View {
    let gridSize: CGFloat
    
    public init(gridSize: CGFloat = 20) {
        self.gridSize = gridSize
    }
    
    public var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                var x: CGFloat = 0
                while x <= width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                    x += gridSize
                }
                
                // Horizontal lines
                var y: CGFloat = 0
                while y <= height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                    y += gridSize
                }
            }
            .stroke(Color.red.opacity(0.2), lineWidth: 0.5)
        }
    }
}