// ModernAuthenticationViews.swift
// Refactored authentication views using modular components

import SwiftUI
import AuthenticationServices

// MARK: - Modern Login View

struct ModernLoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var onNavigateToRegister: () -> Void
    var onNavigateToHome: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo
                AuthLogoView()
                
                // Input fields
                VStack(spacing: 16) {
                    AuthInputField(
                        title: "Email",
                        placeholder: "Enter your email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .none,
                        icon: "envelope"
                    )
                    
                    AuthInputField(
                        title: "Password",
                        placeholder: "Enter your password",
                        text: $password,
                        isSecure: true,
                        icon: "lock"
                    )
                }
                
                // Forgot password
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .font(.caption)
                    
            .foregroundColor(.blue)
                }
                
                // Login button
                AuthPrimaryButton(
                    title: "Sign In",
                    action: performLogin,
                    isLoading: isLoading,
                    isDisabled: !isFormValid
                )
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.caption)
                        
            .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.vertical, 8)
                
                // Social login
                VStack(spacing: 12) {
                    SocialLoginButton(provider: .apple) {
                        performAppleLogin()
                    }
                    
                    SocialLoginButton(provider: .google) {
                        performGoogleLogin()
                    }
                }
                
                // Register prompt
                HStack {
                    Text("Don't have an account?")
                        .font(.caption)
                        
            .foregroundColor(.secondary)
                    
                    Button("Sign Up") {
                        onNavigateToRegister()
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    
            .foregroundColor(.blue)
                }
                
                // Terms
                TermsAndPrivacyView()
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .overlay(
            AuthErrorAlert(message: errorMessage, isShowing: $showError)
                .padding()
                .animation(.spring(), value: showError),
            alignment: .top
        )
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func performLogin() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                authService.login(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    onNavigateToHome()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func performAppleLogin() {
        // Implement Apple Sign In
        authService.signInWithApple()
    }
    
    private func performGoogleLogin() {
        // Implement Google Sign In
        // This would typically use Google Sign-In SDK
    }
}

// MARK: - Modern Registration View

struct ModernRegistrationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var acceptedTerms = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentStep = 1
    
    var onNavigateBack: () -> Void
    var onNavigateToHome: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            registrationHeader
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Progress indicator
                    ProgressIndicator(currentStep: currentStep, totalSteps: 3)
                        .padding(.horizontal)
                    
                    // Step content
                    Group {
                        switch currentStep {
                        case 1:
                            personalInfoStep
                        case 2:
                            accountInfoStep
                        case 3:
                            confirmationStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            
            // Navigation buttons
            navigationButtons
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .overlay(
            AuthErrorAlert(message: errorMessage, isShowing: $showError)
                .padding()
                .animation(.spring(), value: showError),
            alignment: .top
        )
    }
    
    private var registrationHeader: some View {
        HStack {
            Button(action: handleBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    
            .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Create Account")
                .font(.headline)
            
            Spacer()
            
            // Placeholder for alignment
            Image(systemName: "chevron.left")
                .font(.system(size: 20))
                .opacity(0)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var personalInfoStep: some View {
        VStack(spacing: 16) {
            Text("Personal Information")
                .font(.title2)
                .fontWeight(.bold)
            
            AuthInputField(
                title: "First Name",
                placeholder: "Enter your first name",
                text: $firstName,
                icon: "person"
            )
            
            AuthInputField(
                title: "Last Name",
                placeholder: "Enter your last name",
                text: $lastName,
                icon: "person"
            )
            
            AuthInputField(
                title: "Phone Number",
                placeholder: "Enter your phone number",
                text: $phoneNumber,
                keyboardType: .phonePad,
                icon: "phone"
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Date of Birth")
                    .font(.caption)
                    
            .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var accountInfoStep: some View {
        VStack(spacing: 16) {
            Text("Account Details")
                .font(.title2)
                .fontWeight(.bold)
            
            AuthInputField(
                title: "Email",
                placeholder: "Enter your email",
                text: $email,
                keyboardType: .emailAddress,
                autocapitalization: .none,
                icon: "envelope"
            )
            
            AuthInputField(
                title: "Password",
                placeholder: "Create a password",
                text: $password,
                isSecure: true,
                icon: "lock"
            )
            
            PasswordStrengthView(password: password)
            
            AuthInputField(
                title: "Confirm Password",
                placeholder: "Confirm your password",
                text: $confirmPassword,
                isSecure: true,
                icon: "lock"
            )
            
            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                Text("Passwords do not match")
                    .font(.caption)
                    
            .foregroundColor(.red)
            }
        }
    }
    
    private var confirmationStep: some View {
        VStack(spacing: 24) {
            Text("Almost Done!")
                .font(.title2)
                .fontWeight(.bold)
            
            FeatureHighlightView()
            
            HStack {
                Button(action: { acceptedTerms.toggle() }) {
                    Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                        
            .foregroundColor(acceptedTerms ? .blue : .gray)
                }
                
                Text("I accept the ")
                    .font(.caption)
                    
            .foregroundColor(.primary)
                +
                Text("Terms of Service")
                    .font(.caption)
                    
            .foregroundColor(.blue)
                +
                Text(" and ")
                    .font(.caption)
                    
            .foregroundColor(.primary)
                +
                Text("Privacy Policy")
                    .font(.caption)
                    
            .foregroundColor(.blue)
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 1 {
                AuthSecondaryButton(title: "Back") {
                    withAnimation(.spring()) {
                        currentStep -= 1
                    }
                }
            }
            
            AuthPrimaryButton(
                title: currentStep == 3 ? "Create Account" : "Next",
                action: handleNext,
                isLoading: isLoading,
                isDisabled: !isStepValid
            )
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var isStepValid: Bool {
        switch currentStep {
        case 1:
            return !firstName.isEmpty && !lastName.isEmpty
        case 2:
            return !email.isEmpty && email.contains("@") &&
                   !password.isEmpty && password == confirmPassword &&
                   password.count >= 8
        case 3:
            return acceptedTerms
        default:
            return false
        }
    }
    
    private func handleBack() {
        if currentStep > 1 {
            withAnimation(.spring()) {
                currentStep -= 1
            }
        } else {
            onNavigateBack()
        }
    }
    
    private func handleNext() {
        if currentStep < 3 {
            withAnimation(.spring()) {
                currentStep += 1
            }
        } else {
            performRegistration()
        }
    }
    
    private func performRegistration() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.register(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    password: password,
                    confirmPassword: confirmPassword
                )
                
                await MainActor.run {
                    isLoading = false
                    onNavigateToHome()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}