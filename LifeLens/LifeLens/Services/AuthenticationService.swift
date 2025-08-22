// Services/AuthenticationService.swift
import Foundation
import Combine
import LocalAuthentication
#if canImport(UIKit)
import UIKit
#endif

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var currentUser: UserInfo?
    @Published var authError: AuthError?
    
    private let keychainService = KeychainService()
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Enable mock mode for testing without backend
    private let useMockMode = Configuration.shared.isMockModeEnabled
    
    enum AuthError: LocalizedError {
        case invalidCredentials
        case emailNotVerified
        case networkError
        case biometricNotAvailable
        case biometricFailed
        case tokenExpired
        case registrationFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid email or password"
            case .emailNotVerified:
                return "Please verify your email address"
            case .networkError:
                return "Network connection error"
            case .biometricNotAvailable:
                return "Biometric authentication not available"
            case .biometricFailed:
                return "Biometric authentication failed"
            case .tokenExpired:
                return "Session expired. Please login again"
            case .registrationFailed(let message):
                return "Registration failed: \(message)"
            }
        }
    }
    
    init() {
        checkStoredAuthentication()
    }
    
    // MARK: - Logout
    
    func logout() {
        // Clear authentication state
        isAuthenticated = false
        currentUser = nil
        authError = nil
        
        // Clear stored credentials
        keychainService.delete(key: "accessToken")
        keychainService.delete(key: "refreshToken")
        keychainService.delete(key: "userEmail")
        
        // Clear any other stored data
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "lastLoginDate")
        
        // Post notification for any listeners
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
    }
    
    // MARK: - Social Media Authentication
    
    func signInWithApple() {
        isLoading = true
        authError = nil
        
        // Mock implementation for testing
        if useMockMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.isLoading = false
                let mockUser = UserInfo(
                    id: UUID().uuidString,
                    email: "apple.user@icloud.com",
                    firstName: "Apple",
                    lastName: "User",
                    isEmailVerified: true,
                    profileComplete: true
                )
                self?.currentUser = mockUser
                self?.isAuthenticated = true
                
                // Store mock credentials
                if let tokenData = "apple_mock_token".data(using: .utf8) {
                    self?.keychainService.store(key: "accessToken", data: tokenData)
                }
            }
            return
        }
        
        // TODO: Implement actual Apple Sign In
        // This would use AuthenticationServices framework
    }
    
    func signInWithGoogle() {
        isLoading = true
        authError = nil
        
        // Mock implementation for testing
        if useMockMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.isLoading = false
                let mockUser = UserInfo(
                    id: UUID().uuidString,
                    email: "google.user@gmail.com",
                    firstName: "Google",
                    lastName: "User",
                    isEmailVerified: true,
                    profileComplete: true
                )
                self?.currentUser = mockUser
                self?.isAuthenticated = true
                
                // Store mock credentials
                if let tokenData = "google_mock_token".data(using: .utf8) {
                    self?.keychainService.store(key: "accessToken", data: tokenData)
                }
            }
            return
        }
        
        // TODO: Implement actual Google Sign In
        // This would use Google Sign-In SDK
    }
    
    func signInWithFacebook() {
        isLoading = true
        authError = nil
        
        // Mock implementation for testing
        if useMockMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.isLoading = false
                let mockUser = UserInfo(
                    id: UUID().uuidString,
                    email: "facebook.user@fb.com",
                    firstName: "Facebook",
                    lastName: "User",
                    isEmailVerified: true,
                    profileComplete: true
                )
                self?.currentUser = mockUser
                self?.isAuthenticated = true
                
                // Store mock credentials
                if let tokenData = "facebook_mock_token".data(using: .utf8) {
                    self?.keychainService.store(key: "accessToken", data: tokenData)
                }
            }
            return
        }
        
        // TODO: Implement actual Facebook Sign In
        // This would use Facebook SDK
    }
    
    // MARK: - Registration
    
    func register(
        firstName: String,
        lastName: String,
        email: String,
        password: String,
        confirmPassword: String
    ) {
        guard password == confirmPassword else {
            authError = .registrationFailed("Passwords do not match")
            return
        }
        
        guard isValidPassword(password) else {
            authError = .registrationFailed("Password must be at least 8 characters with uppercase, lowercase, and number")
            return
        }
        
        isLoading = true
        
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        let request = RegisterRequest(
            email: email,
            password: password,
            full_name: fullName
        )
        
        apiService.register(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.authError = .registrationFailed(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] (response: AuthResponse) in
                    self?.handleAuthResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Login
    
    func login(email: String, password: String) {
        isLoading = true
        authError = nil
        
        let request = LoginRequest(
            email: email,
            password: password,
            device_id: getDeviceID()
        )
        
        apiService.login(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        if error.localizedDescription.contains("401") {
                            self?.authError = .invalidCredentials
                        } else if error.localizedDescription.contains("email_not_verified") {
                            self?.authError = .emailNotVerified
                        } else {
                            self?.authError = .networkError
                        }
                    }
                },
                receiveValue: { [weak self] (response: AuthResponse) in
                    self?.handleAuthResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Biometric Authentication
    
    func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authError = .biometricNotAvailable
            return
        }
        
        let reason = "Use biometric authentication to access LifeLens"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.loginWithStoredCredentials()
                } else {
                    self?.authError = .biometricFailed
                }
            }
        }
    }
    
    // MARK: - Token Management
    
    private func handleAuthResponse(_ response: AuthResponse) {
        guard response.success, let authData = response.data else {
            authError = .networkError
            return
        }
        
        // Store tokens securely
        keychainService.store(key: "accessToken", data: authData.access_token.data(using: .utf8)!)
        keychainService.store(key: "refreshToken", data: authData.refresh_token.data(using: .utf8)!)
        
        // Convert AuthData to UserInfo for compatibility
        let userInfo = UserInfo(from: authData)
        
        // Store user info
        if let userData = try? JSONEncoder().encode(userInfo) {
            keychainService.store(key: "user_info", data: userData)
        }
        
        currentUser = userInfo
        isAuthenticated = true
        authError = nil
    }
    
    private func checkStoredAuthentication() {
        guard let tokenData = keychainService.retrieve(key: "access_token"),
              let token = String(data: tokenData, encoding: .utf8),
              let userData = keychainService.retrieve(key: "user_info"),
              let user = try? JSONDecoder().decode(UserInfo.self, from: userData) else {
            return
        }
        
        // Verify token is still valid
        apiService.verifyToken(token)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    if case .failure = completion {
                        self?.logout()
                    }
                },
                receiveValue: { [weak self] (isValid: Bool) in
                    if isValid {
                        self?.currentUser = user
                        self?.isAuthenticated = true
                    } else {
                        self?.refreshToken()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func refreshToken() {
        guard let refreshTokenData = keychainService.retrieve(key: "refreshToken"),
              let refreshToken = String(data: refreshTokenData, encoding: .utf8) else {
            logout()
            return
        }
        
        let request = TokenRefreshRequest(refresh_token: refreshToken)
        
        apiService.refreshToken(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    if case .failure = completion {
                        self?.logout()
                    }
                },
                receiveValue: { [weak self] (response: AuthResponse) in
                    self?.handleAuthResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) {
        apiService.resetPassword(email: email)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { (completion: Subscribers.Completion<Error>) in
                    // Handle completion
                },
                receiveValue: { (success: Bool) in
                    // Show success message
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    private func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d@$!%*?&]{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    private func loginWithStoredCredentials() {
        // This would typically use stored biometric-protected credentials
        checkStoredAuthentication()
    }
    
    private func scheduleTokenRefresh(expiresIn: Int) {
        // Schedule token refresh before expiration
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(expiresIn - 300)) { [weak self] in
            self?.refreshToken()
        }
    }
    
    private func getDeviceID() -> String {
        #if canImport(UIKit)
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        return UUID().uuidString
        #endif
    }
}