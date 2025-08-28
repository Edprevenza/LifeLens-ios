// AuthenticationComponents.swift
// Modular authentication components

import SwiftUI

// MARK: - Logo Component

struct AuthLogoView: View {
    var body: some View {
        VStack(spacing: 16) {
            LifeLensLogo(size: .large, style: .withTitle)
            
            Text("Your Health, Continuously Monitored")
                .font(.caption)
                
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 32)
    }
}

// MARK: - Input Field Component

struct AuthInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var icon: String? = nil
    
    @State private var isShowingPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                
            .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        
            .foregroundColor(.secondary)
                        .frame(width: 20)
                }
                
                Group {
                    if isSecure && !isShowingPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .autocapitalization(autocapitalization)
                    }
                }
                
                if isSecure {
                    Button(action: { isShowingPassword.toggle() }) {
                        Image(systemName: isShowingPassword ? "eye.slash.fill" : "eye.fill")
                            
            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Primary Button Component

struct AuthPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue,
                                Color.blue.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isDisabled ? 0.5 : 1)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        
            .foregroundColor(.white)
                }
            }
            .frame(height: 52)
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .disabled(isLoading || isDisabled)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                           pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Secondary Button Component

struct AuthSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                
            .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }
}

// MARK: - Social Login Button

struct SocialLoginButton: View {
    let provider: SocialProvider
    let action: () -> Void
    
    enum SocialProvider {
        case apple, google
        
        var title: String {
            switch self {
            case .apple: return "Continue with Apple"
            case .google: return "Continue with Google"
            }
        }
        
        var icon: String {
            switch self {
            case .apple: return "apple.logo"
            case .google: return "globe"
            }
        }
        
        var color: Color {
            switch self {
            case .apple: return .black
            case .google: return .red
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: provider.icon)
                    .font(.system(size: 18))
                
                Text(provider.title)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
            }
            
            .foregroundColor(provider == .apple ? .white : .primary)
            .padding(.horizontal, 20)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(provider == .apple ? Color.black : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: provider == .apple ? 0 : 1)
            )
        }
    }
}

// MARK: - Terms and Privacy Component

struct TermsAndPrivacyView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("By continuing, you agree to our")
                .font(.caption)
                
            .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Button("Terms of Service") {
                    // Open terms
                }
                .font(.caption)
                
            .foregroundColor(.blue)
                
                Text("and")
                    .font(.caption)
                    
            .foregroundColor(.secondary)
                
                Button("Privacy Policy") {
                    // Open privacy
                }
                .font(.caption)
                
            .foregroundColor(.blue)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 16)
    }
}

// MARK: - Error Alert Component

struct AuthErrorAlert: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            VStack {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        
            .foregroundColor(.red)
                    
                    Text(message)
                        .font(.caption)
                        
            .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { isShowing = false }) {
                        Image(systemName: "xmark.circle.fill")
                            
            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(), value: isShowing)
        }
    }
}

// MARK: - Feature Highlight Component

struct FeatureHighlightView: View {
    struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let color: Color
    }
    
    let features = [
        Feature(icon: "heart.fill", title: "Real-time Monitoring", color: .red),
        Feature(icon: "shield.fill", title: "Secure & Private", color: .green),
        Feature(icon: "chart.line.uptrend.xyaxis", title: "AI Insights", color: .purple),
        Feature(icon: "bell.fill", title: "Smart Alerts", color: .orange)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Why LifeLens?")
                .font(.headline)
                
            .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(features) { feature in
                    FeatureCard(feature: feature)
                }
            }
        }
        .padding(.vertical, 24)
    }
}

struct FeatureCard: View {
    let feature: FeatureHighlightView.Feature
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: feature.icon)
                .font(.system(size: 24))
                
            .foregroundColor(feature.color)
            
            Text(feature.title)
                .font(.caption)
                
            .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
    }
}

// MARK: - Password Strength View Wrapper
// Uses the PasswordStrengthIndicator from PasswordValidator.swift

struct PasswordStrengthView: View {
    let password: String
    
    var strength: PasswordValidator.PasswordStrength? {
        password.isEmpty ? nil : PasswordValidator.getPasswordStrength(password)
    }
    
    var body: some View {
        // Use the PasswordStrengthIndicator from PasswordValidator.swift
        PasswordStrengthIndicator(strength: strength)
    }
}

// Password validation is handled by PasswordValidator.swift