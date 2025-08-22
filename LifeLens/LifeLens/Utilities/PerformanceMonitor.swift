// PerformanceMonitor.swift
import Foundation
import UIKit
import os.log
import QuartzCore

/**
 * Performance Monitor for LifeLens iOS
 * Ensures app meets production performance standards
 */
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    // Performance thresholds
    private let targetFPS: Double = 60.0
    private let frameTimeThreshold: TimeInterval = 1.0 / 60.0 // ~16.67ms
    private let appLaunchThreshold: TimeInterval = 3.0 // 3 seconds
    private let memoryWarningThreshold: Float = 0.8 // 80% of available memory
    
    // Monitoring state
    private var appLaunchStartTime: CFAbsoluteTime = 0
    private var displayLink: CADisplayLink?
    private var frameDropCount = 0
    private var totalFrameCount = 0
    private var lastFrameTimestamp: CFTimeInterval = 0
    private var frameTimeBuffer: [TimeInterval] = []
    
    // Logging
    private let logger = OSLog(subsystem: "com.lifelens.app", category: "Performance")
    
    private init() {
        setupMemoryWarningObserver()
        setupThermalStateObserver()
        startBatteryMonitoring()
    }
    
    // MARK: - App Launch Performance
    
    func recordAppLaunchStart() {
        appLaunchStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    func recordAppLaunchComplete() {
        guard appLaunchStartTime > 0 else { return }
        
        let launchDuration = CFAbsoluteTimeGetCurrent() - appLaunchStartTime
        os_log("App launch time: %.2f seconds", log: logger, type: .info, launchDuration)
        
        if launchDuration > appLaunchThreshold {
            os_log("App launch exceeded threshold: %.2f > %.2f seconds", 
                   log: logger, type: .error, launchDuration, appLaunchThreshold)
            reportPerformanceIssue(issue: "Slow app launch", value: launchDuration)
        }
        
        appLaunchStartTime = 0
    }
    
    // MARK: - Frame Rate Monitoring (60 FPS)
    
    func startFrameRateMonitoring() {
        stopFrameRateMonitoring()
        
        displayLink = CADisplayLink(target: self, selector: #selector(frameUpdate))
        displayLink?.add(to: .main, forMode: .common)
        
        frameDropCount = 0
        totalFrameCount = 0
        frameTimeBuffer.removeAll()
        lastFrameTimestamp = CACurrentMediaTime()
    }
    
    func stopFrameRateMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
        
        if totalFrameCount > 0 {
            let dropRate = Float(frameDropCount) / Float(totalFrameCount) * 100
            let avgFrameTime = frameTimeBuffer.reduce(0, +) / Double(frameTimeBuffer.count)
            
            os_log("Frame stats - Drops: %d/%d (%.2f%%), Avg: %.2fms", 
                   log: logger, type: .info,
                   frameDropCount, totalFrameCount, dropRate, avgFrameTime * 1000)
            
            if dropRate > 5 { // More than 5% frame drops
                reportPerformanceIssue(issue: "High frame drop rate", value: Double(dropRate))
            }
        }
    }
    
    @objc private func frameUpdate() {
        let currentTime = CACurrentMediaTime()
        let frameDuration = currentTime - lastFrameTimestamp
        
        if frameDuration > frameTimeThreshold {
            frameDropCount += 1
            os_log("Frame drop detected: %.2fms", log: logger, type: .debug, frameDuration * 1000)
        }
        
        totalFrameCount += 1
        frameTimeBuffer.append(frameDuration)
        
        // Keep buffer size manageable
        if frameTimeBuffer.count > 100 {
            frameTimeBuffer.removeFirst()
        }
        
        lastFrameTimestamp = currentTime
    }
    
    // MARK: - Memory Monitoring
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Start periodic memory monitoring
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.checkMemoryUsage()
        }
    }
    
    @objc private func handleMemoryWarning() {
        os_log("Memory warning received", log: logger, type: .error)
        reportPerformanceIssue(issue: "Memory warning", value: Double(getCurrentMemoryUsage()))
        
        // Clear caches
        URLCache.shared.removeAllCachedResponses()
        
        // Post notification for app to clear unnecessary data
        NotificationCenter.default.post(name: NSNotification.Name("ClearMemoryCache"), object: nil)
    }
    
    private func checkMemoryUsage() {
        let memoryUsage = getCurrentMemoryUsage()
        let memoryLimit = getMemoryLimit()
        let usagePercent = Float(memoryUsage) / Float(memoryLimit)
        
        os_log("Memory usage: %.2f%% (%.2fMB / %.2fMB)", 
               log: logger, type: .debug,
               usagePercent * 100, 
               Double(memoryUsage) / 1024 / 1024,
               Double(memoryLimit) / 1024 / 1024)
        
        if usagePercent > memoryWarningThreshold {
            os_log("High memory usage: %.2f%%", log: logger, type: .error, usagePercent * 100)
            reportPerformanceIssue(issue: "High memory usage", value: Double(usagePercent * 100))
        }
    }
    
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func getMemoryLimit() -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }
    
    // MARK: - Thermal State Monitoring
    
    private func setupThermalStateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateChanged),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func thermalStateChanged() {
        let thermalState = ProcessInfo.processInfo.thermalState
        
        switch thermalState {
        case .nominal:
            os_log("Thermal state: Nominal", log: logger, type: .info)
        case .fair:
            os_log("Thermal state: Fair - Consider reducing activity", log: logger, type: .info)
        case .serious:
            os_log("Thermal state: Serious - Reduce activity", log: logger, type: .error)
            reportPerformanceIssue(issue: "High thermal state", value: 2)
        case .critical:
            os_log("Thermal state: Critical - Minimize activity", log: logger, type: .fault)
            reportPerformanceIssue(issue: "Critical thermal state", value: 3)
        @unknown default:
            break
        }
    }
    
    // MARK: - Battery Monitoring
    
    private func startBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateChanged),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelChanged),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func batteryStateChanged() {
        let state = UIDevice.current.batteryState
        
        switch state {
        case .unplugged:
            // Optimize for battery life
            reducePowerConsumption()
        case .charging, .full:
            // Can use more resources
            break
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    @objc private func batteryLevelChanged() {
        let level = UIDevice.current.batteryLevel
        
        if level < 0.2 && level >= 0 { // Below 20%
            os_log("Low battery: %.0f%%", log: logger, type: .info, level * 100)
            reducePowerConsumption()
        }
    }
    
    private func reducePowerConsumption() {
        // Notify app to reduce background activities
        NotificationCenter.default.post(name: NSNotification.Name("ReducePowerConsumption"), object: nil)
    }
    
    // MARK: - Network Performance
    
    func measureNetworkCall<T>(name: String, block: () async throws -> T) async throws -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let result = try await block()
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            os_log("Network call '%@' completed in %.2fms", 
                   log: logger, type: .info, name, duration * 1000)
            return result
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            os_log("Network call '%@' failed after %.2fms: %@", 
                   log: logger, type: .error, name, duration * 1000, error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Performance Reporting
    
    private func reportPerformanceIssue(issue: String, value: Double) {
        os_log("Performance issue: %@ (value: %.2f)", log: logger, type: .error, issue, value)
        
        // In production, send to analytics/crashlytics
        // Analytics.logEvent("performance_issue", parameters: ["issue": issue, "value": value])
    }
    
    // MARK: - Performance Stats
    
    struct PerformanceStats {
        let avgFrameTime: TimeInterval
        let frameDropRate: Float
        let memoryUsageMB: Double
        let memoryUsagePercent: Float
        let batteryLevel: Float
        let thermalState: ProcessInfo.ThermalState
    }
    
    func getCurrentStats() -> PerformanceStats {
        let memoryUsage = getCurrentMemoryUsage()
        let memoryLimit = getMemoryLimit()
        let avgFrameTime = frameTimeBuffer.isEmpty ? 0 : frameTimeBuffer.reduce(0, +) / Double(frameTimeBuffer.count)
        
        return PerformanceStats(
            avgFrameTime: avgFrameTime,
            frameDropRate: totalFrameCount > 0 ? Float(frameDropCount) / Float(totalFrameCount) * 100 : 0,
            memoryUsageMB: Double(memoryUsage) / 1024 / 1024,
            memoryUsagePercent: Float(memoryUsage) / Float(memoryLimit) * 100,
            batteryLevel: UIDevice.current.batteryLevel,
            thermalState: ProcessInfo.processInfo.thermalState
        )
    }
}

// MARK: - View Controller Extension

extension UIViewController {
    func enablePerformanceOptimizations() {
        // Reduce animations in low power mode
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            UIView.setAnimationsEnabled(false)
        }
        
        // Optimize table/collection views
        if let tableView = view as? UITableView {
            tableView.estimatedRowHeight = 44
            tableView.rowHeight = UITableView.automaticDimension
        }
        
        if let collectionView = view as? UICollectionView {
            collectionView.isPrefetchingEnabled = true
        }
    }
}