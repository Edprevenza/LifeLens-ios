//
//  EnhancedProfileView.swift
//  LifeLens
//
//  Enhanced profile view with emergency contacts management
//

import SwiftUI

struct EnhancedProfileView: View {
typealias EmergencyContactInfo = EmergencyContact
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var showingAddEmergencyContact = false
    @State private var showingLogoutConfirmation = false
    @State private var showingMedicalHistory = false
    @State private var showingNotifications = false
    @State private var showingPrivacySecurity = false
    @State private var showingHelpSupport = false
    @State private var emergencyContacts: [EmergencyContactInfo] = [
        EmergencyContactInfo(name: "John Doe", relationship: "Father", phone: "+1 (555) 123-4567"),
        EmergencyContactInfo(name: "Jane Doe", relationship: "Mother", phone: "+1 (555) 987-6543")
    ]
    
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Logo at the top
                    LifeLensLogo(size: .medium, style: .withTitle)
                        .padding(.top, 20)
                    
                    // Profile Header
                    EnhancedProfileHeaderCard()
                        .padding(.horizontal)
                    
                    // Health Stats
                    HealthStatsGrid()
                        .padding(.horizontal)
                    
                    // Emergency Contacts Section
                    EmergencyContactsSection(
                        contacts: $emergencyContacts,
                        showingAddContact: $showingAddEmergencyContact
                    )
                    .padding(.horizontal)
                    
                    // Menu Items
                    VStack(spacing: 12) {
                        EnhancedProfileMenuItem(
                            icon: "person.fill",
                            title: "Personal Information",
                            color: .blue,
                            action: { showingEditProfile = true }
                        )
                        
                        EnhancedProfileMenuItem(
                            icon: "heart.text.square.fill",
                            title: "Medical History",
                            color: .red,
                            action: { showingMedicalHistory = true }
                        )
                        
                        EnhancedProfileMenuItem(
                            icon: "bell.fill",
                            title: "Notifications",
                            color: .orange,
                            action: { showingNotifications = true }
                        )
                        
                        EnhancedProfileMenuItem(
                            icon: "lock.fill",
                            title: "Privacy & Security",
                            color: .green,
                            action: { showingPrivacySecurity = true }
                        )
                        
                        EnhancedProfileMenuItem(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            color: .purple,
                            action: { showingHelpSupport = true }
                        )
                    }
                    .padding(.horizontal)
                    
                    // Sign Out Button
                    Button(action: {
                        showingLogoutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                            Text("Sign Out")
                        }
                        .font(.system(size: 16, weight: .medium))
                        
            .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingEditProfile) {
            PersonalInformationView()
        }
        .sheet(isPresented: $showingMedicalHistory) {
            MedicalHistoryView()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingPrivacySecurity) {
            PrivacySecurityView()
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
        .sheet(isPresented: $showingAddEmergencyContact) {
            EmergencyContactForm(contacts: $emergencyContacts)
        }
        .alert("Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authService.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Emergency Contacts Section
// Duplicate removed - use SharedTypes
// Missing components for EnhancedProfileView

struct EnhancedProfileHeaderCard: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                
            .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(authService.currentUser?.firstName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(authService.currentUser?.email ?? "")
                    .font(.caption)
                    
            .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmergencyContactsSection: View {
    @Binding var contacts: [EmergencyContact]
    @Binding var showingAddContact: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Emergency Contacts")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddContact = true }) {
                    Image(systemName: "plus.circle.fill")
                        
            .foregroundColor(.blue)
                }
            }
            
            ForEach(contacts, id: \.phone) { contact in
                HStack {
                    VStack(alignment: .leading) {
                        Text(contact.name)
                            .font(.subheadline)
                        Text(contact.relationship)
                            .font(.caption)
                            
            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(contact.phone)
                        .font(.caption)
                        
            .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EnhancedProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    
            .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    
            .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    
            .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
// MARK: - Emergency Contact Form
struct EmergencyContactForm: View {
    @Environment(\.dismiss) var dismiss
    @Binding var contacts: [EmergencyContact]
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Relationship", text: $relationship)
                }
            }
            .navigationTitle("Add Emergency Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let contact = EmergencyContact(
                            name: name,
                            relationship: relationship,
                            phone: phone
                        )
                        contacts.append(contact)
                        dismiss()
                    }
                    .disabled(name.isEmpty || phone.isEmpty)
                }
            }
        }
    }
}
