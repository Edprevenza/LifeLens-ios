// Models/AuthenticationModels.swift
import Foundation

// MARK: - Request Models

struct LoginRequest: Codable {
    let email: String
    let password: String
    let device_id: String?
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let full_name: String
}

struct TokenRefreshRequest: Codable {
    let refresh_token: String
}

struct ResetPasswordRequest: Codable {
    let email: String
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let data: AuthData?
}

struct AuthData: Codable {
    let user_id: String?
    let email: String?
    let full_name: String?
    let access_token: String
    let refresh_token: String
    let token_type: String
}

struct VerifyResponse: Codable {
    let success: Bool
    let message: String
    let data: VerifyData?
}

struct VerifyData: Codable {
    let user_id: String
    let email: String
    let expires_at: Int
}

// MARK: - Legacy Support

struct UserInfo: Codable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let isEmailVerified: Bool
    var profileComplete: Bool
    
    init(from authData: AuthData) {
        self.id = authData.user_id ?? UUID().uuidString
        self.email = authData.email ?? ""
        
        // Split full name into first and last
        let nameParts = (authData.full_name ?? "").split(separator: " ")
        self.firstName = String(nameParts.first ?? "")
        self.lastName = nameParts.count > 1 ? String(nameParts.dropFirst().joined(separator: " ")) : ""
        
        self.isEmailVerified = true
        self.profileComplete = false
    }
    
    init(id: String, email: String, firstName: String, lastName: String, isEmailVerified: Bool, profileComplete: Bool) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.isEmailVerified = isEmailVerified
        self.profileComplete = profileComplete
    }
}