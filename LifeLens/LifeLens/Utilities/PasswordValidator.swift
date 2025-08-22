// PasswordValidator.swift
import Foundation
import SwiftUI

/**
 * Password Validator for LifeLens
 * Ensures password meets security requirements:
 * - At least 8 characters
 * - Contains uppercase letter (A-Z)
 * - Contains lowercase letter (a-z)
 * - Contains number (0-9)
 * - Contains special symbol (~!@#$%^&*_+-)
 */
struct PasswordValidator {
    
    static let minPasswordLength = 8
    static let uppercasePattern = ".*[A-Z]+.*"
    static let lowercasePattern = ".*[a-z]+.*"
    static let digitPattern = ".*[0-9]+.*"
    static let specialCharPattern = ".*[~!@#$%^&*_+\\-=]+.*"
    
    struct ValidationResult {
        let isValid: Bool
        let errors: [String]
        
        init(isValid: Bool, errors: [String] = []) {
            self.isValid = isValid
            self.errors = errors
        }
    }
    
    static func validate(_ password: String) -> ValidationResult {
        var errors: [String] = []
        
        // Check minimum length
        if password.count < minPasswordLength {
            errors.append("Password must be at least \(minPasswordLength) characters long")
        }
        
        // Check for uppercase letter
        if !password.matches(uppercasePattern) {
            errors.append("Password must contain at least one uppercase letter (A-Z)")
        }
        
        // Check for lowercase letter
        if !password.matches(lowercasePattern) {
            errors.append("Password must contain at least one lowercase letter (a-z)")
        }
        
        // Check for digit
        if !password.matches(digitPattern) {
            errors.append("Password must contain at least one number (0-9)")
        }
        
        // Check for special character
        if !password.matches(specialCharPattern) {
            errors.append("Password must contain at least one special character (~!@#$%^&*_+-=)")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    static func getPasswordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        // Length score
        if password.count >= 16 {
            score += 3
        } else if password.count >= 12 {
            score += 2
        } else if password.count >= 8 {
            score += 1
        }
        
        // Character variety score
        if password.matches(uppercasePattern) { score += 1 }
        if password.matches(lowercasePattern) { score += 1 }
        if password.matches(digitPattern) { score += 1 }
        if password.matches(specialCharPattern) { score += 1 }
        
        // Additional patterns
        if password.matches(".*[A-Z].*[A-Z].*") { score += 1 } // Multiple uppercase
        if password.matches(".*[0-9].*[0-9].*") { score += 1 } // Multiple digits
        if password.matches(".*[~!@#$%^&*_+\\-=].*[~!@#$%^&*_+\\-=].*") { score += 1 } // Multiple special
        
        switch score {
        case 0...3:
            return .weak
        case 4...6:
            return .medium
        case 7...8:
            return .strong
        default:
            return .veryStrong
        }
    }
    
    enum PasswordStrength {
        case weak
        case medium
        case strong
        case veryStrong
        
        var label: String {
            switch self {
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            case .veryStrong: return "Very Strong"
            }
        }
        
        var color: Color {
            switch self {
            case .weak: return .red
            case .medium: return .orange
            case .strong: return Color.green.opacity(0.8)
            case .veryStrong: return .green
            }
        }
        
        var progress: Double {
            switch self {
            case .weak: return 0.25
            case .medium: return 0.5
            case .strong: return 0.75
            case .veryStrong: return 1.0
            }
        }
    }
    
    static var requirementsText: String {
        """
        Password Requirements:
        • At least 8 characters
        • One uppercase letter (A-Z)
        • One lowercase letter (a-z)
        • One number (0-9)
        • One special character (~!@#$%^&*_+-=)
        """
    }
}

// MARK: - String Extension for Pattern Matching

extension String {
    func matches(_ pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return false
        }
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

// MARK: - SwiftUI View Components

struct PasswordStrengthIndicator: View {
    let strength: PasswordValidator.PasswordStrength?
    
    var body: some View {
        if let strength = strength {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Password Strength:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(strength.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(strength.color)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(strength.color)
                            .frame(width: geometry.size.width * strength.progress, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: strength.progress)
                    }
                }
                .frame(height: 4)
            }
            .padding(.top, 4)
        }
    }
}

struct PasswordRequirementsView: View {
    let password: String
    @State private var showRequirements = false
    
    private var validation: PasswordValidator.ValidationResult {
        PasswordValidator.validate(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !password.isEmpty && !validation.isValid {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(validation.errors.prefix(2), id: \.self) { error in
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    if validation.errors.count > 2 {
                        Button(action: { showRequirements.toggle() }) {
                            Text("Show all requirements")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            if showRequirements {
                Text(PasswordValidator.requirementsText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}