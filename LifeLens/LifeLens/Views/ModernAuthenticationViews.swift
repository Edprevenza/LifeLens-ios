//
//  ModernAuthenticationViews.swift
//  LifeLens
//
//  Modern authentication views with social media integration
//

import SwiftUI

// MARK: - Modern Login View
struct ModernLoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Binding var showingLogin: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingPasswordReset = false
    @State private var rememberMe = false
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Animated Background
            AnimatedBackgroundView()
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Top Section with Logo
                    VStack(spacing: 24) {
                        // Logo with glow effect
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.3),
                                            Color.blue.opacity(0.1),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .blur(radius: 20)
                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 3)
                                        .repeatForever(autoreverses: true),
                                    value: isAnimating
                                )
                            
                            LifeLensLogo(size: .extraLarge, style: .standalone)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Welcome to LifeLens")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Your AI-powered health companion")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Main Login Card
                    VStack(spacing: 32) {
                        // Social Login Section
                        VStack(spacing: 16) {
                            Text("Sign in with")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 16) {
                                SocialLoginButton(
                                    provider: .apple,
                                    action: { authService.signInWithApple() }
                                )
                                
                                SocialLoginButton(
                                    provider: .google,
                                    action: { authService.signInWithGoogle() }
                                )
                                
                                SocialLoginButton(
                                    provider: .facebook,
                                    action: { authService.signInWithFacebook() }
                                )
                            }
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                        }
                        
                        // Email/Password Form
                        VStack(spacing: 20) {
                            // Email Field
                            ModernTextField(
                                title: "Email",
                                text: $email,
                                placeholder: "Enter your email",
                                icon: "envelope.fill",
                                isEmail: true
                            )
                            
                            // Password Field
                            ModernSecureField(
                                title: "Password",
                                text: $password,
                                placeholder: "Enter your password",
                                icon: "lock.fill"
                            )
                            
                            // Remember Me & Forgot Password
                            HStack {
                                Button(action: { rememberMe.toggle() }) {
                                    HStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                .frame(width: 20, height: 20)
                                            
                                            if rememberMe {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        
                                        Text("Remember me")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                                
                                Button("Forgot Password?") {
                                    showingPasswordReset = true
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            }
                        }
                        
                        // Login Button
                        GradientButton(
                            title: "Sign In",
                            icon: "arrow.right",
                            isLoading: authService.isLoading,
                            action: {
                                authService.login(email: email, password: password)
                            }
                        )
                        .disabled(email.isEmpty || password.isEmpty)
                        
                        // Biometric Login
                        if BiometricAuthenticationManager.shared.isBiometricAvailable() {
                            BiometricLoginButton(action: {
                                authService.authenticateWithBiometrics()
                            })
                        }
                        
                        // Error Message
                        if let error = authService.authError {
                            ErrorMessageView(message: error.localizedDescription)
                        }
                        
                        // Sign Up Link
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Button("Create Account") {
                                withAnimation {
                                    showingLogin = false
                                }
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black.opacity(0.3))
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.2),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            isAnimating = true
        }
        .sheet(isPresented: $showingPasswordReset) {
            ModernPasswordResetView()
        }
    }
}

// MARK: - Modern Registration View
struct ModernRegistrationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Binding var showingLogin: Bool
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var acceptTerms = false
    @State private var currentStep = 1
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Animated Background
            AnimatedBackgroundView()
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 24) {
                        // Logo
                        LifeLensLogo(size: .large, style: .withSubtitle, subtitle: "Join the future of health monitoring")
                            .padding(.bottom, 10)
                        
                        // Progress Indicator
                        RegistrationProgressView(currentStep: currentStep, totalSteps: 3)
                            .padding(.horizontal, 60)
                        
                        VStack(spacing: 8) {
                            Text("Create Your Account")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(stepDescription)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 32)
                    
                    // Registration Card
                    VStack(spacing: 32) {
                        if currentStep == 1 {
                            // Step 1: Social Sign Up
                            VStack(spacing: 24) {
                                Text("Quick Sign Up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 16) {
                                    SocialSignUpButton(
                                        provider: .apple,
                                        action: {
                                            authService.signInWithApple()
                                        }
                                    )
                                    
                                    SocialSignUpButton(
                                        provider: .google,
                                        action: {
                                            authService.signInWithGoogle()
                                        }
                                    )
                                    
                                    SocialSignUpButton(
                                        provider: .facebook,
                                        action: {
                                            authService.signInWithFacebook()
                                        }
                                    )
                                }
                                
                                // Divider
                                HStack {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 1)
                                    
                                    Text("OR")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                    
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 1)
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        currentStep = 2
                                    }
                                }) {
                                    Text("Sign up with email")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                        } else if currentStep == 2 {
                            // Step 2: Personal Information
                            VStack(spacing: 20) {
                                HStack(spacing: 16) {
                                    ModernTextField(
                                        title: "First Name",
                                        text: $firstName,
                                        placeholder: "John",
                                        icon: "person.fill"
                                    )
                                    
                                    ModernTextField(
                                        title: "Last Name",
                                        text: $lastName,
                                        placeholder: "Doe",
                                        icon: "person.fill"
                                    )
                                }
                                
                                ModernTextField(
                                    title: "Email Address",
                                    text: $email,
                                    placeholder: "john.doe@example.com",
                                    icon: "envelope.fill",
                                    isEmail: true
                                )
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation {
                                            currentStep = 1
                                        }
                                    }) {
                                        Text("Back")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                    
                                    GradientButton(
                                        title: "Continue",
                                        icon: "arrow.right",
                                        action: {
                                            withAnimation {
                                                currentStep = 3
                                            }
                                        }
                                    )
                                    .disabled(firstName.isEmpty || lastName.isEmpty || email.isEmpty)
                                }
                            }
                        } else {
                            // Step 3: Password & Terms
                            VStack(spacing: 20) {
                                ModernSecureField(
                                    title: "Password",
                                    text: $password,
                                    placeholder: "Create a strong password",
                                    icon: "lock.fill"
                                )
                                
                                ModernSecureField(
                                    title: "Confirm Password",
                                    text: $confirmPassword,
                                    placeholder: "Re-enter your password",
                                    icon: "lock.fill"
                                )
                                
                                PasswordStrengthIndicator(password: password)
                                
                                // Terms Checkbox - Simple clickable implementation
                                HStack(alignment: .center, spacing: 0) {
                                    // Clickable checkbox area
                                    Button(action: {
                                        acceptTerms.toggle()
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: acceptTerms ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 20))
                                                .foregroundColor(acceptTerms ? .blue : .gray)
                                            
                                            Text("I agree to the ")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray) +
                                            Text("Terms of Service")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.blue) +
                                            Text(" and ")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray) +
                                            Text("Privacy Policy")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer()
                                }
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation {
                                            currentStep = 2
                                        }
                                    }) {
                                        Text("Back")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                    
                                    GradientButton(
                                        title: "Create Account",
                                        icon: "checkmark",
                                        isLoading: authService.isLoading,
                                        action: {
                                            authService.register(
                                                firstName: firstName,
                                                lastName: lastName,
                                                email: email,
                                                password: password,
                                                confirmPassword: confirmPassword
                                            )
                                        }
                                    )
                                    .disabled(!isFormValid)
                                }
                            }
                        }
                        
                        // Error Message
                        if let error = authService.authError {
                            ErrorMessageView(message: error.localizedDescription)
                        }
                        
                        // Sign In Link
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Button("Sign In") {
                                withAnimation {
                                    showingLogin = true
                                }
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black.opacity(0.3))
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.2),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            isAnimating = true
        }
    }
    
    private var stepDescription: String {
        switch currentStep {
        case 1: return "Choose your sign up method"
        case 2: return "Tell us about yourself"
        case 3: return "Secure your account"
        default: return ""
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        acceptTerms
    }
}

// MARK: - Supporting Views
struct AnimatedBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated circles
            ForEach(0..<3) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.3),
                                Color.purple.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(
                        x: animate ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50),
                        y: animate ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50)
                    )
                    .blur(radius: 30)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 15...25))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 2),
                        value: animate
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isEmail: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? .blue : .gray)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .focused($isFocused)
                    #if os(iOS)
                    .keyboardType(isEmail ? .emailAddress : .default)
                    .textInputAutocapitalization(.never)
                    #endif
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color.blue : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}

struct ModernSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    @State private var isSecure = true
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? .blue : .gray)
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .focused($isFocused)
                }
                
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color.blue : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}

struct GradientButton: View {
    let title: String
    let icon: String?
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SocialProvider {
    case apple, google, facebook
    
    var icon: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "globe"
        case .facebook: return "f.circle.fill"
        }
    }
    
    var title: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .facebook: return "Facebook"
        }
    }
    
    var color: Color {
        switch self {
        case .apple: return .white
        case .google: return .white
        case .facebook: return Color(red: 0.26, green: 0.40, blue: 0.70)
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .apple: return .black
        case .google: return .white
        case .facebook: return Color(red: 0.26, green: 0.40, blue: 0.70)
        }
    }
}

struct SocialLoginButton: View {
    let provider: SocialProvider
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: provider.icon)
                    .font(.system(size: 20))
                    .foregroundColor(provider.color)
            }
            .frame(width: 60, height: 60)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SocialSignUpButton: View {
    let provider: SocialProvider
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: provider.icon)
                    .font(.system(size: 20))
                
                Text("Continue with \(provider.title)")
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
            }
            .foregroundColor(provider == .google ? .black : provider.color)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(provider == .google ? Color.white : provider.backgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BiometricLoginButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: BiometricAuthenticationManager.shared.biometricType() == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 24))
                
                Text("Sign in with \(BiometricAuthenticationManager.shared.biometricType() == .faceID ? "Face ID" : "Touch ID")")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RegistrationProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step < currentStep {
                    // Completed step
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                } else if step == currentStep {
                    // Current step
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(step)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                } else {
                    // Future step
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(step)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        )
                }
                
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? Color.blue : Color.white.opacity(0.1))
                        .frame(height: 2)
                }
            }
        }
    }
}

struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.isEmpty { return .none }
        if password.count < 6 { return .weak }
        
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }
        
        switch score {
        case 0...2: return .weak
        case 3: return .medium
        case 4...5: return .strong
        default: return .weak
        }
    }
    
    enum PasswordStrength {
        case none, weak, medium, strong
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }
        
        var text: String {
            switch self {
            case .none: return ""
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
    }
    
    var body: some View {
        if !password.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < strengthLevel ? strength.color : Color.white.opacity(0.1))
                            .frame(height: 4)
                    }
                }
                
                HStack {
                    Text("Password strength: ")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(strength.text)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(strength.color)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var strengthLevel: Int {
        switch strength {
        case .none: return 0
        case .weak: return 1
        case .medium: return 2
        case .strong: return 4
        }
    }
}

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(.red)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}


// MARK: - Modern Password Reset View
struct ModernPasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text("Reset Password")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Enter your email to receive reset instructions")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Email Field
                    ModernTextField(
                        title: "Email Address",
                        text: $email,
                        placeholder: "Enter your email",
                        icon: "envelope.fill",
                        isEmail: true
                    )
                    
                    // Send Button
                    GradientButton(
                        title: "Send Reset Link",
                        icon: "paperplane.fill",
                        isLoading: isLoading,
                        action: {
                            isLoading = true
                            authService.resetPassword(email: email)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isLoading = false
                                showingSuccessAlert = true
                            }
                        }
                    )
                    .disabled(email.isEmpty)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .alert("Check Your Email", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("We've sent password reset instructions to \(email)")
        }
    }
}