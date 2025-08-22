//
//  ProfileView.swift
//  LifeLens
//
//  User profile and settings view
//

import SwiftUI

struct HealthProfileView: View {
    @AppStorage("userName") private var userName = "John Doe"
    @AppStorage("userEmail") private var userEmail = "john.doe@example.com"
    @AppStorage("emergencyContact") private var emergencyContact = ""
    @AppStorage("medicalConditions") private var medicalConditions = ""
    
    @State private var showingSettings = false
    @State private var showingAPIConfig = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(userEmail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Health Information
                Section("Health Information") {
                    HStack {
                        Label("Blood Type", systemImage: "drop.fill")
                        Spacer()
                        Text("O+")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Age", systemImage: "calendar")
                        Spacer()
                        Text("45 years")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Weight", systemImage: "scalemass")
                        Spacer()
                        Text("75 kg")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Height", systemImage: "ruler")
                        Spacer()
                        Text("175 cm")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Emergency Contact
                Section("Emergency Information") {
                    HStack {
                        Label("Emergency Contact", systemImage: "phone.fill")
                        Spacer()
                        Text(emergencyContact.isEmpty ? "Not Set" : emergencyContact)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Medical Conditions", systemImage: "heart.text.square")
                        Spacer()
                        Text(medicalConditions.isEmpty ? "None" : medicalConditions)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Connected Services
                Section("Connected Services") {
                    HStack {
                        Label("AWS API", systemImage: "cloud.fill")
                        Spacer()
                        Text("Connected")
                            .foregroundColor(.green)
                    }
                    .onTapGesture {
                        showingAPIConfig = true
                    }
                    
                    HStack {
                        Label("HealthKit", systemImage: "heart.fill")
                        Spacer()
                        Text("Not Connected")
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Label("Wallet SDK", systemImage: "creditcard.fill")
                        Spacer()
                        Text("Not Connected")
                            .foregroundColor(.orange)
                    }
                }
                
                // Settings
                Section {
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    Button(action: { exportHealthData() }) {
                        Label("Export Health Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { /* Sign out */ }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .sheet(isPresented: $showingAPIConfig) {
                APIConfigurationView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private func exportHealthData() {
        // TODO: Implement health data export
        print("Exporting health data...")
    }
}

// MARK: - API Configuration View

struct APIConfigurationView: View {
    @State private var apiURL = Configuration.shared.apiBaseURL
    @State private var isValidating = false
    @State private var validationMessage = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("AWS API Gateway Configuration") {
                    TextField("API URL", text: $apiURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        #if os(iOS)
                        .autocapitalization(.none)
                        #endif
                        .disableAutocorrection(true)
                    
                    Text("Current: Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Endpoint: \(apiURL)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: validateConnection) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            }
                            Text(isValidating ? "Validating..." : "Test Connection")
                        }
                    }
                    .disabled(isValidating || apiURL.isEmpty)
                    
                    if !validationMessage.isEmpty {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundColor(validationMessage.contains("success") ? .green : .red)
                    }
                }
                
                Section {
                    Button("Save Configuration") {
                        // API URL is now fixed in configuration
                        dismiss()
                    }
                    .disabled(apiURL.isEmpty)
                }
            }
            .navigationTitle("API Configuration")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func validateConnection() {
        isValidating = true
        validationMessage = ""
        
        APIConfiguration.validateAPIConnection { success, message in
            DispatchQueue.main.async {
                isValidating = false
                validationMessage = message
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("enableEmergencyAlerts") private var enableEmergencyAlerts = true
    @AppStorage("dataRefreshInterval") private var dataRefreshInterval = 5.0
    @AppStorage("enableMockMode") private var enableMockMode = true
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                    Toggle("Emergency Alerts", isOn: $enableEmergencyAlerts)
                }
                
                Section("Data & Sync") {
                    HStack {
                        Text("Refresh Interval")
                        Spacer()
                        Picker("", selection: $dataRefreshInterval) {
                            Text("5 sec").tag(5.0)
                            Text("10 sec").tag(10.0)
                            Text("30 sec").tag(30.0)
                            Text("1 min").tag(60.0)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section("Developer") {
                    Toggle("Mock Mode", isOn: $enableMockMode)
                    
                    Button("Print API Configuration") {
                        APIConfiguration.printCurrentConfiguration()
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(Configuration.shared.appVersion) (\(Configuration.shared.buildNumber))")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Bundle ID")
                        Spacer()
                        Text(Configuration.shared.bundleIdentifier)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        HealthProfileView()
    }
}