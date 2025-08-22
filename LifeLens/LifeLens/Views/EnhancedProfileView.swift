//
//  EnhancedProfileView.swift
//  LifeLens
//
//  Enhanced profile view with emergency contacts management
//

import SwiftUI

struct EnhancedProfileView: View {
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
            AddEmergencyContactView(contacts: $emergencyContacts)
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
struct EmergencyContactsSection: View {
    @Binding var contacts: [EmergencyContactInfo]
    @Binding var showingAddContact: Bool
    @State private var contactToDelete: EmergencyContactInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Emergency Contacts")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(contacts.count) contact\(contacts.count == 1 ? "" : "s") added")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    showingAddContact = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            
            // Contacts List
            if contacts.isEmpty {
                EmptyContactsView()
            } else {
                ForEach(contacts) { contact in
                    EmergencyContactCard(
                        contact: contact,
                        onDelete: {
                            withAnimation {
                                contacts.removeAll { $0.id == contact.id }
                            }
                        }
                    )
                }
            }
        }
    }
}

struct EmergencyContactCard: View {
    let contact: EmergencyContactInfo
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Contact Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(contact.initials)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Contact Info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(contact.relationship)
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Text(contact.phone)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    // Call contact
                    #if os(iOS)
                    if let url = URL(string: "tel://\(contact.phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                    #endif
                }) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                        .frame(width: 36, height: 36)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .alert("Remove Contact", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to remove \(contact.name) from your emergency contacts?")
        }
    }
}

struct EmptyContactsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No emergency contacts added")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text("Add contacts who should be notified in case of emergency")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

// MARK: - Add Emergency Contact View
struct AddEmergencyContactView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var contacts: [EmergencyContactInfo]
    
    @State private var name = ""
    @State private var relationship = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var selectedRelationship = "Family"
    
    let relationships = ["Family", "Friend", "Doctor", "Spouse", "Parent", "Child", "Sibling", "Other"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - lighter for better contrast
                Color(red: 0.1, green: 0.1, blue: 0.12)
                    .ignoresSafeArea()
                
                ScrollView {
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
                            
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextField("Enter contact's name", text: $name)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.vertical, 4)
                            }
                            
                            // Relationship Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Relationship")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Picker("Relationship", selection: $selectedRelationship) {
                                    ForEach(relationships, id: \.self) { relationship in
                                        Text(relationship).tag(relationship)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accentColor(.blue)
                            }
                            
                            // Phone Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone Number")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextField("Enter phone number", text: $phone)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    #if os(iOS)
                                    .keyboardType(.phonePad)
                                    #endif
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.vertical, 4)
                            }
                            
                            // Email Field (Optional)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Email")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("(Optional)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                
                                TextField("Enter email address", text: $email)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    #if os(iOS)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    #endif
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Add Button
                        Button(action: {
                            let newContact = EmergencyContactInfo(
                                name: name,
                                relationship: selectedRelationship,
                                phone: phone,
                                email: email.isEmpty ? nil : email
                            )
                            contacts.append(newContact)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Add Contact")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .disabled(name.isEmpty || phone.isEmpty)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Add Emergency Contact")
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
    }
}

// MARK: - Enhanced Profile Header Card
struct EnhancedProfileHeaderCard: View {
    var body: some View {
        VStack(spacing: 16) {
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
                    .frame(width: 80, height: 80)
                
                Text("JD")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("John Doe")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("john.doe@example.com")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 8) {
                StatusPill(text: "Premium", color: .yellow)
                StatusPill(text: "Verified", color: .green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

// MARK: - Updated Profile Menu Item
struct EnhancedProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Emergency Contact Model
struct EmergencyContactInfo: Identifiable {
    let id = UUID()
    let name: String
    let relationship: String
    let phone: String
    var email: String? = nil
    
    var initials: String {
        let words = name.split(separator: " ")
        let initials = words.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}