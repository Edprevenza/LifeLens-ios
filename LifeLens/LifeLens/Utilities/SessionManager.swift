// SessionManager.swift
import Foundation
import SwiftUI

/**
 * Session Manager for LifeLens
 * Handles secure session management with auto-logout
 */
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    // Session timeout in minutes
    private let sessionTimeoutMinutes: TimeInterval = 15
    private let extendedSessionTimeoutMinutes: TimeInterval = 60 * 24 * 7 // 7 days for remember me
    
    // Keys for secure storage
    private let lastActivityKey = "last_activity_time"
    private let loginTimeKey = "login_time"
    private let rememberMeKey = "remember_me"
    private let sessionExpiryWarningKey = "session_expiry_warning_shown"
    
    @Published var isSessionValid = true
    @Published var timeUntilExpiry: TimeInterval = 0
    @Published var showSessionExpiryWarning = false
    
    private var sessionTimer: Timer?
    private let keychainService = KeychainService()
    
    private init() {
        startSessionMonitoring()
    }
    
    // MARK: - Session Management
    
    func startSession(rememberMe: Bool = false) {
        let now = Date()
        UserDefaults.standard.set(now, forKey: loginTimeKey)
        UserDefaults.standard.set(now, forKey: lastActivityKey)
        UserDefaults.standard.set(rememberMe, forKey: rememberMeKey)
        UserDefaults.standard.set(false, forKey: sessionExpiryWarningKey)
        
        isSessionValid = true
        startSessionMonitoring()
    }
    
    func updateActivity() {
        UserDefaults.standard.set(Date(), forKey: lastActivityKey)
        UserDefaults.standard.set(false, forKey: sessionExpiryWarningKey)
    }
    
    func endSession() {
        // Clear session data
        UserDefaults.standard.removeObject(forKey: loginTimeKey)
        UserDefaults.standard.removeObject(forKey: lastActivityKey)
        UserDefaults.standard.removeObject(forKey: rememberMeKey)
        UserDefaults.standard.removeObject(forKey: sessionExpiryWarningKey)
        
        // Clear keychain tokens
        keychainService.delete(key: "accessToken")
        keychainService.delete(key: "refreshToken")
        
        // Update state
        isSessionValid = false
        showSessionExpiryWarning = false
        
        // Stop monitoring
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        // Notify authentication service
        NotificationCenter.default.post(name: NSNotification.Name("SessionExpired"), object: nil)
    }
    
    // MARK: - Session Validation
    
    func checkSessionValidity() -> Bool {
        guard let lastActivity = UserDefaults.standard.object(forKey: lastActivityKey) as? Date else {
            return false
        }
        
        let rememberMe = UserDefaults.standard.bool(forKey: rememberMeKey)
        let timeoutMinutes = rememberMe ? extendedSessionTimeoutMinutes : sessionTimeoutMinutes
        
        let timeSinceLastActivity = Date().timeIntervalSince(lastActivity)
        let minutesPassed = timeSinceLastActivity / 60
        
        if minutesPassed >= timeoutMinutes {
            endSession()
            return false
        }
        
        // Show warning 2 minutes before expiry
        let minutesUntilExpiry = timeoutMinutes - minutesPassed
        if minutesUntilExpiry <= 2 && !UserDefaults.standard.bool(forKey: sessionExpiryWarningKey) {
            showSessionExpiryWarning = true
            UserDefaults.standard.set(true, forKey: sessionExpiryWarningKey)
        }
        
        timeUntilExpiry = minutesUntilExpiry * 60
        return true
    }
    
    // MARK: - Session Monitoring
    
    private func startSessionMonitoring() {
        sessionTimer?.invalidate()
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isSessionValid = self?.checkSessionValidity() ?? false
            }
        }
    }
    
    func extendSession() {
        updateActivity()
        showSessionExpiryWarning = false
        checkSessionValidity()
    }
    
    // MARK: - Session Info
    
    func getSessionInfo() -> SessionInfo? {
        guard isSessionValid,
              let loginTime = UserDefaults.standard.object(forKey: loginTimeKey) as? Date,
              let lastActivity = UserDefaults.standard.object(forKey: lastActivityKey) as? Date else {
            return nil
        }
        
        return SessionInfo(
            loginTime: loginTime,
            lastActivity: lastActivity,
            rememberMe: UserDefaults.standard.bool(forKey: rememberMeKey),
            timeUntilExpiry: timeUntilExpiry
        )
    }
    
    struct SessionInfo {
        let loginTime: Date
        let lastActivity: Date
        let rememberMe: Bool
        let timeUntilExpiry: TimeInterval
        
        var formattedTimeUntilExpiry: String {
            let minutes = Int(timeUntilExpiry / 60)
            let seconds = Int(timeUntilExpiry.truncatingRemainder(dividingBy: 60))
            
            if minutes > 60 {
                let hours = minutes / 60
                let remainingMinutes = minutes % 60
                return "\(hours)h \(remainingMinutes)m"
            } else if minutes > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(seconds)s"
            }
        }
    }
}

// MARK: - Session Expiry Warning View

struct SessionExpiryWarningView: View {
    @ObservedObject var sessionManager = SessionManager.shared
    @State private var isPresented = false
    
    var body: some View {
        EmptyView()
            .alert("Session Expiring Soon", isPresented: $sessionManager.showSessionExpiryWarning) {
                Button("Extend Session") {
                    sessionManager.extendSession()
                }
                Button("Logout", role: .cancel) {
                    sessionManager.endSession()
                }
            } message: {
                Text("Your session will expire in \(Int(sessionManager.timeUntilExpiry / 60)) minutes. Would you like to extend your session?")
            }
    }
}

// MARK: - Activity Tracking Modifier

struct ActivityTrackingModifier: ViewModifier {
    let sessionManager = SessionManager.shared
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                sessionManager.updateActivity()
            }
            .onAppear {
                sessionManager.updateActivity()
            }
    }
}

extension View {
    func trackActivity() -> some View {
        self.modifier(ActivityTrackingModifier())
    }
}