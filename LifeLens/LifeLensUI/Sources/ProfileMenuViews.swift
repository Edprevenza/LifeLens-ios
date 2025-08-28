//
//  ProfileMenuViews.swift
//  LifeLens
//
//  Views for Profile Menu Items
//

import SwiftUI

// MARK: - Medical History View
struct MedicalHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var bloodType = "O+"
    @State private var allergies = ""
    @State private var medications = ""
    @State private var conditions: Set<String> = []
    @State private var surgeries = ""
    @State private var familyHistory = ""
    
    let bloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    let commonConditions = ["Diabetes", "Hypertension", "Heart Disease", "Asthma", "Arthritis", "Cancer", "Stroke", "Kidney Disease"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Icon
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 20)
                        
                        // Blood Type
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Blood Type")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            Picker("Blood Type", selection: $bloodType) {
                                ForEach(bloodTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Allergies
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Allergies")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            TextEditor(text: $allergies)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                
            .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        
                        // Current Medications
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Current Medications")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            TextEditor(text: $medications)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                
            .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        
                        // Medical Conditions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Medical Conditions")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(commonConditions, id: \.self) { condition in
                                    Button(action: {
                                        if conditions.contains(condition) {
                                            conditions.remove(condition)
                                        } else {
                                            conditions.insert(condition)
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: conditions.contains(condition) ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 20))
                                                
            .foregroundColor(conditions.contains(condition) ? .blue : .gray)
                                                .frame(width: 24, height: 24)
                                            
                                            Text(condition)
                                                .font(.system(size: 16))
                                                
            .foregroundColor(.white)
                                            
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Previous Surgeries
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Previous Surgeries")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            TextEditor(text: $surgeries)
                                .frame(height: 80)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                
            .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        
                        // Family History
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Family Medical History")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            TextEditor(text: $familyHistory)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                
            .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Medical History")
            #if os(iOS)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save medical history
                        dismiss()
                    }
                    
            .foregroundColor(.blue)
                }
            }
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 700, idealHeight: 800)
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var enableNotifications = true
    @State private var criticalAlerts = true
    @State private var healthReminders = true
    @State private var medicationReminders = true
    @State private var appointmentReminders = true
    @State private var activityReminders = false
    @State private var weeklyReports = true
    @State private var emergencyAlerts = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Icon
                        Image(systemName: "bell.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 20)
                        
                        // Master Toggle
                        VStack(spacing: 16) {
                            Toggle("Enable All Notifications", isOn: $enableNotifications)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Notification Categories
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Alert Types")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                NotificationToggle(
                                    title: "Critical Health Alerts",
                                    subtitle: "Immediate notifications for critical health readings",
                                    isOn: $criticalAlerts,
                                    icon: "exclamationmark.triangle.fill",
                                    color: .red
                                )
                                
                                NotificationToggle(
                                    title: "Emergency Alerts",
                                    subtitle: "Alert emergency contacts when needed",
                                    isOn: $emergencyAlerts,
                                    icon: "phone.fill",
                                    color: .red
                                )
                                
                                NotificationToggle(
                                    title: "Health Reminders",
                                    subtitle: "Daily health check reminders",
                                    isOn: $healthReminders,
                                    icon: "heart.fill",
                                    color: .pink
                                )
                                
                                NotificationToggle(
                                    title: "Medication Reminders",
                                    subtitle: "Never miss your medications",
                                    isOn: $medicationReminders,
                                    icon: "pills.fill",
                                    color: .green
                                )
                                
                                NotificationToggle(
                                    title: "Appointment Reminders",
                                    subtitle: "Doctor appointments and checkups",
                                    isOn: $appointmentReminders,
                                    icon: "calendar",
                                    color: .blue
                                )
                                
                                NotificationToggle(
                                    title: "Activity Reminders",
                                    subtitle: "Movement and exercise reminders",
                                    isOn: $activityReminders,
                                    icon: "figure.walk",
                                    color: .orange
                                )
                                
                                NotificationToggle(
                                    title: "Weekly Health Reports",
                                    subtitle: "Summary of your weekly health data",
                                    isOn: $weeklyReports,
                                    icon: "chart.bar.fill",
                                    color: .purple
                                )
                            }
                        }
                        .padding(.horizontal)
                        .disabled(!enableNotifications)
                        .opacity(enableNotifications ? 1 : 0.5)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Notification Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save notification settings
                        dismiss()
                    }
                    
            .foregroundColor(.blue)
                }
            }
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 600, idealHeight: 700)
    }
}

struct NotificationToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                
            .foregroundColor(color)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    
            .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    
            .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
                .labelsHidden()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Privacy & Security View
struct PrivacySecurityView: View {
    @Environment(\.dismiss) var dismiss
    @State private var biometricEnabled = true
    @State private var shareHealthData = false
    @State private var shareWithResearchers = false
    @State private var twoFactorEnabled = false
    @State private var locationServices = true
    @State private var showPasswordChange = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Icon
                        Image(systemName: "lock.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 20)
                        
                        // Security Settings
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Security")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                SecurityToggle(
                                    title: "Biometric Authentication",
                                    subtitle: "Use Face ID or Touch ID to unlock",
                                    isOn: $biometricEnabled,
                                    icon: "faceid"
                                )
                                
                                SecurityToggle(
                                    title: "Two-Factor Authentication",
                                    subtitle: "Extra security for your account",
                                    isOn: $twoFactorEnabled,
                                    icon: "lock.shield.fill"
                                )
                                
                                Button(action: {
                                    showPasswordChange = true
                                }) {
                                    HStack {
                                        Image(systemName: "key.fill")
                                            .font(.system(size: 24))
                                            
            .foregroundColor(.yellow)
                                            .frame(width: 30)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Change Password")
                                                .font(.system(size: 16, weight: .medium))
                                                
            .foregroundColor(.white)
                                            
                                            Text("Update your account password")
                                                .font(.system(size: 12))
                                                
            .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            
            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Privacy Settings
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Privacy")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                SecurityToggle(
                                    title: "Share Health Data",
                                    subtitle: "Share anonymized data with healthcare providers",
                                    isOn: $shareHealthData,
                                    icon: "heart.text.square"
                                )
                                
                                SecurityToggle(
                                    title: "Contribute to Research",
                                    subtitle: "Help medical research with anonymized data",
                                    isOn: $shareWithResearchers,
                                    icon: "magnifyingglass"
                                )
                                
                                SecurityToggle(
                                    title: "Location Services",
                                    subtitle: "Allow location for emergency services",
                                    isOn: $locationServices,
                                    icon: "location.fill"
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Data Management
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Data Management")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                DataButton(
                                    title: "Export My Data",
                                    subtitle: "Download all your health data",
                                    icon: "square.and.arrow.up",
                                    color: .blue
                                )
                                
                                DataButton(
                                    title: "Delete My Data",
                                    subtitle: "Permanently remove all data",
                                    icon: "trash.fill",
                                    color: .red
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Privacy & Security")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save privacy settings
                        dismiss()
                    }
                    
            .foregroundColor(.blue)
                }
            }
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 600, idealHeight: 700)
    }
}

struct SecurityToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                
            .foregroundColor(.green)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    
            .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    
            .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .labelsHidden()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct DataButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    
            .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        
            .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        
            .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    
            .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

// MARK: - Help & Support View
struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    let faqItems = [
        FAQItem(question: "How do I connect my device?", answer: "Go to Devices tab and tap 'Connect Device'. Make sure Bluetooth is enabled."),
        FAQItem(question: "What do the health metrics mean?", answer: "Each metric represents different aspects of your health. Tap on any metric for detailed information."),
        FAQItem(question: "How often should I sync my data?", answer: "We recommend syncing at least once daily for accurate tracking."),
        FAQItem(question: "Is my data secure?", answer: "Yes, all data is encrypted and stored securely. We never share your personal information."),
        FAQItem(question: "How do I add emergency contacts?", answer: "Go to Profile > Emergency Contacts and tap the + button to add contacts."),
        FAQItem(question: "What should I do if I get a critical alert?", answer: "Critical alerts require immediate attention. Contact your healthcare provider immediately.")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Icon
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 20)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                
            .foregroundColor(.gray)
                            
                            TextField("Search for help", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                
            .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Help")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    QuickHelpButton(title: "User Guide", icon: "book.fill", color: .blue)
                                    QuickHelpButton(title: "Video Tutorials", icon: "play.circle.fill", color: .red)
                                }
                                HStack(spacing: 12) {
                                    QuickHelpButton(title: "Contact Support", icon: "envelope.fill", color: .green)
                                    QuickHelpButton(title: "Report Issue", icon: "exclamationmark.bubble.fill", color: .orange)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // FAQ Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Frequently Asked Questions")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                ForEach(faqItems.filter { searchText.isEmpty || $0.question.localizedCaseInsensitiveContains(searchText) }) { item in
                                    FAQItemView(item: item)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Contact Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Contact Us")
                                .font(.headline)
                                
            .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                ContactRow(icon: "phone.fill", text: "+1 (555) 123-4567", color: .green)
                                ContactRow(icon: "envelope.fill", text: "support@lifelens.com", color: .blue)
                                ContactRow(icon: "globe", text: "www.lifelens.com/support", color: .purple)
                                ContactRow(icon: "clock.fill", text: "24/7 Support Available", color: .orange)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Help & Support")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    
            .foregroundColor(.blue)
                }
            }
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 600, idealHeight: 700)
    }
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQItemView: View {
    let item: FAQItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(item.question)
                        .font(.system(size: 16, weight: .medium))
                        
            .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        
            .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                Text(item.answer)
                    .font(.system(size: 14))
                    
            .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct QuickHelpButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    
            .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14))
                    
            .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

struct ContactRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                
            .foregroundColor(color)
                .frame(width: 25)
            
            Text(text)
                .font(.system(size: 14))
                
            .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}