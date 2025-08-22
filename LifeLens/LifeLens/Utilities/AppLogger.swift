// AppLogger.swift
import Foundation
import OSLog

class AppLogger {
    static let shared = AppLogger()
    
    private let logger: Logger
    private let subsystem: String
    private let category: String
    
    private init() {
        self.subsystem = Configuration.shared.bundleIdentifier
        self.category = "LifeLens"
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    // MARK: - Logging Methods
    
    func log(_ message: String, level: OSLogType = .default, file: String = #file, function: String = #function, line: Int = #line) {
        guard Configuration.shared.isLoggingEnabled else { return }
        
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(filename):\(line)] \(function) - \(message)"
        
        logger.log(level: level, "\(logMessage)")
        
        #if DEBUG
        print("\(Date()) [\(levelString(for: level))] \(logMessage)")
        #endif
    }
    
    func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard Configuration.shared.logLevel.rawValue <= LogLevel.verbose.rawValue else { return }
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard Configuration.shared.logLevel.rawValue <= LogLevel.debug.rawValue else { return }
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard Configuration.shared.logLevel.rawValue <= LogLevel.info.rawValue else { return }
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard Configuration.shared.logLevel.rawValue <= LogLevel.warning.rawValue else { return }
        log(message, level: .default, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard Configuration.shared.logLevel.rawValue <= LogLevel.error.rawValue else { return }
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fault, file: file, function: function, line: line)
    }
    
    // MARK: - Network Logging
    
    func logNetworkRequest(url: String, method: String, headers: [String: String]? = nil) {
        #if DEBUG
        var logMessage = "Network Request:\n"
        logMessage += "  URL: \(url)\n"
        logMessage += "  Method: \(method)"
        
        if let headers = headers {
            logMessage += "\n  Headers: \(headers)"
        }
        
        debug(logMessage)
        #endif
    }
    
    func logNetworkResponse(url: String, statusCode: Int, responseTime: TimeInterval, error: Error? = nil) {
        #if DEBUG
        var logMessage = "Network Response:\n"
        logMessage += "  URL: \(url)\n"
        logMessage += "  Status Code: \(statusCode)\n"
        logMessage += "  Response Time: \(String(format: "%.3f", responseTime))s"
        
        if let error = error {
            logMessage += "\n  Error: \(error.localizedDescription)"
        }
        
        if statusCode >= 400 {
            self.error(logMessage)
        } else {
            self.debug(logMessage)
        }
        #endif
    }
    
    // MARK: - Analytics Events
    
    func logEvent(_ event: String, parameters: [String: Any]? = nil) {
        #if DEBUG
        var logMessage = "Analytics Event: \(event)"
        
        if let parameters = parameters {
            logMessage += "\n  Parameters: \(parameters)"
        }
        
        info(logMessage)
        #endif
    }
    
    func logScreenView(_ screenName: String) {
        logEvent("screen_view", parameters: ["screen_name": screenName])
    }
    
    func logUserAction(_ action: String, target: String? = nil) {
        var parameters: [String: Any] = ["action": action]
        if let target = target {
            parameters["target"] = target
        }
        logEvent("user_action", parameters: parameters)
    }
    
    // MARK: - Performance Logging
    
    func startPerformanceTracking(for operation: String) -> Date {
        debug("Performance tracking started: \(operation)")
        return Date()
    }
    
    func endPerformanceTracking(for operation: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        info("Performance: \(operation) completed in \(String(format: "%.3f", duration))s")
    }
    
    // MARK: - Helper Methods
    
    private func levelString(for level: OSLogType) -> String {
        switch level {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .default:
            return "DEFAULT"
        case .error:
            return "ERROR"
        case .fault:
            return "FAULT"
        default:
            return "UNKNOWN"
        }
    }
    
    // MARK: - Crash Reporting
    
    func logCrash(exception: NSException) {
        let crashInfo = """
        CRASH DETECTED:
        Name: \(exception.name.rawValue)
        Reason: \(exception.reason ?? "Unknown")
        User Info: \(exception.userInfo ?? [:])
        Call Stack: \(exception.callStackSymbols.joined(separator: "\n"))
        """
        fault(crashInfo)
    }
}

// MARK: - Log File Management

extension AppLogger {
    
    func exportLogs() -> URL? {
        #if DEBUG
        // This would export logs to a file for debugging purposes
        // Implementation would depend on your logging strategy
        return nil
        #else
        return nil
        #endif
    }
    
    func clearLogs() {
        #if DEBUG
        debug("Logs cleared")
        #endif
    }
}