//
//  ModernProfileViewFixed.swift
//  LifeLens
//
//  Responsive and Progressive Profile View
//

import SwiftUI

struct ModernProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingSettings = false
    @State private var showingLogoutConfirmation = false
    @State private var showingPersonalInfo = false
    @State private var showingMedicalHistory = false
    @State private var showingNotifications = false
    @State private var showingPrivacySecurity = false
    @State private var showingHelpSupport = false
    @State private var isLoading = true
    @State private var loadedSections = Set<String>()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
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
            .ignoresSafeArea(.all)
            
            if isLoading {
                ProgressView("Loading Profile...")
                    .foregroundColor(.white)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isLoading = false
                            }
                        }
                    }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isCompact ? 20 : 24) {
                        // Logo at the top - centered
                        HStack {
                            Spacer()
                            LifeLensLogo(size: isCompact ? .small : .medium, style: .withTitle)
                            Spacer()
                        }
                        .padding(.top, isCompact ? 16 : 20)
                        .opacity(loadedSections.contains("logo") ? 1 : 0)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                _ = loadedSections.insert("logo")
                            }
                        }
                        
                        // Profile Header
                        ProfileHeaderCard(isCompact: isCompact)
                            .padding(.horizontal, isCompact ? 16 : 20)
                            .opacity(loadedSections.contains("header") ? 1 : 0)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                                    _ = loadedSections.insert("header")
                                }
                            }
                        
                        // Health Stats
                        HealthStatsGrid(isCompact: isCompact)
                            .padding(.horizontal, isCompact ? 16 : 20)
                            .opacity(loadedSections.contains("stats") ? 1 : 0)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
                                    _ = loadedSections.insert("stats")
                                }
                            }
                        
                        // Menu Items
                        VStack(spacing: isCompact ? 10 : 12) {
                            ProfileMenuItem(
                                icon: "person.fill",
                                title: "Personal Information",
                                color: .blue,
                                isCompact: isCompact,
                                action: { showingPersonalInfo = true }
                            )
                            
                            ProfileMenuItem(
                                icon: "heart.text.square.fill",
                                title: "Medical History",
                                color: .red,
                                isCompact: isCompact,
                                action: { showingMedicalHistory = true }
                            )
                            
                            ProfileMenuItem(
                                icon: "bell.fill",
                                title: "Notifications",
                                color: .orange,
                                isCompact: isCompact,
                                action: { showingNotifications = true }
                            )
                            
                            ProfileMenuItem(
                                icon: "lock.fill",
                                title: "Privacy & Security",
                                color: .green,
                                isCompact: isCompact,
                                action: { showingPrivacySecurity = true }
                            )
                            
                            ProfileMenuItem(
                                icon: "questionmark.circle.fill",
                                title: "Help & Support",
                                color: .purple,
                                isCompact: isCompact,
                                action: { showingHelpSupport = true }
                            )
                        }
                        .padding(.horizontal, isCompact ? 16 : 20)
                        .opacity(loadedSections.contains("menu") ? 1 : 0)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                                _ = loadedSections.insert("menu")
                            }
                        }
                        
                        // Sign Out Button
                        Button(action: {
                            showingLogoutConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                    .font(.system(size: isCompact ? 18 : 20))
                                Text("Sign Out")
                                    .font(.system(size: isCompact ? 15 : 16, weight: .medium))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isCompact ? 14 : 16)
                            .background(
                                RoundedRectangle(cornerRadius: isCompact ? 14 : 16)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, isCompact ? 16 : 20)
                        .padding(.bottom, isCompact ? 30 : 40)
                        .opacity(loadedSections.contains("signout") ? 1 : 0)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.3).delay(0.4)) {
                                _ = loadedSections.insert("signout")
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authService.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showingPersonalInfo) {
            NavigationView {
                PersonalInformationView()
            }
        }
        .sheet(isPresented: $showingMedicalHistory) {
            NavigationView {
                MedicalHistoryView()
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NavigationView {
                NotificationSettingsView()
            }
        }
        .sheet(isPresented: $showingPrivacySecurity) {
            NavigationView {
                PrivacySecurityView()
            }
        }
        .sheet(isPresented: $showingHelpSupport) {
            NavigationView {
                HelpSupportView()
            }
        }
    }
}

struct ProfileHeaderCard: View {
    let isCompact: Bool
    @State private var animateAvatar = false
    
    var body: some View {
        VStack(spacing: isCompact ? 12 : 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isCompact ? 70 : 80, height: isCompact ? 70 : 80)
                    .scaleEffect(animateAvatar ? 1.0 : 0.9)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateAvatar)
                
                Text("JD")
                    .font(.system(size: isCompact ? 24 : 28, weight: .bold))
                    .foregroundColor(.white)
            }
            .onAppear {
                animateAvatar = true
            }
            
            VStack(spacing: 4) {
                Text("John Doe")
                    .font(.system(size: isCompact ? 20 : 24, weight: .bold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("john.doe@example.com")
                    .font(.system(size: isCompact ? 13 : 14))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(isCompact ? 20 : 24)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 16 : 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 16 : 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

struct HealthStatsGrid: View {
    let isCompact: Bool
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: isCompact ? 10 : 12),
            GridItem(.flexible(), spacing: isCompact ? 10 : 12)
        ], spacing: isCompact ? 10 : 12) {
            StatCard(value: "45", label: "Age", icon: "calendar", color: .blue, isCompact: isCompact)
            StatCard(value: "O+", label: "Blood Type", icon: "drop.fill", color: .red, isCompact: isCompact)
            StatCard(value: "175", label: "Height (cm)", icon: "ruler", color: .green, isCompact: isCompact)
            StatCard(value: "75", label: "Weight (kg)", icon: "scalemass", color: .purple, isCompact: isCompact)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let isCompact: Bool
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: isCompact ? 6 : 8) {
            Image(systemName: icon)
                .font(.system(size: isCompact ? 18 : 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: isCompact ? 18 : 20, weight: .bold))
                .foregroundColor(.white)
                .fixedSize()
            
            Text(label)
                .font(.system(size: isCompact ? 11 : 12))
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isCompact ? 14 : 16)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 14 : 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 14 : 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let isCompact: Bool
    var action: (() -> Void)? = nil
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            if let action = action {
                action()
            }
        }) {
            HStack(spacing: isCompact ? 14 : 16) {
                Image(systemName: icon)
                    .font(.system(size: isCompact ? 18 : 20))
                    .foregroundColor(color)
                    .frame(width: isCompact ? 36 : 40, height: isCompact ? 36 : 40)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: isCompact ? 15 : 16, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: isCompact ? 12 : 14))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(isCompact ? 14 : 16)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 14 : 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: isCompact ? 14 : 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
    }
}

// Device Pairing View
struct DevicePairingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isScanning = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Animation
                    ZStack {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                .frame(width: CGFloat(80 + i * 40), height: CGFloat(80 + i * 40))
                                .scaleEffect(isScanning ? 1.2 : 1.0)
                                .opacity(isScanning ? 0.0 : 1.0)
                                .animation(
                                    Animation.easeOut(duration: 2.0)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(i) * 0.4),
                                    value: isScanning
                                )
                        }
                        
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 40))
                            
            .foregroundColor(.blue)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Scanning for Devices")
                            .font(.system(size: 24, weight: .bold))
                            
            .foregroundColor(.white)
                        
                        Text("Make sure your device is powered on and nearby")
                            .font(.system(size: 14))
                            
            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Device")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    
            .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            isScanning = true
        }
    }
}

// StatusPill is defined in MainAppView.swift
