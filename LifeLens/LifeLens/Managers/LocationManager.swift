// Managers/LocationManager.swift
import CoreLocation
import Foundation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        #else
        guard authorizationStatus == .authorizedAlways else {
            return
        }
        #endif
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        #if os(iOS)
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startLocationUpdates()
        }
        #else
        if status == .authorizedAlways {
            startLocationUpdates()
        }
        #endif
    }
}

// Models/EmergencyContact.swift
import Foundation

struct EmergencyContact: Codable {
    var name: String
    var relationship: String
    var phoneNumber: String
    var email: String
    var isPrimary: Bool
}

// Views/EmergencyView.swift
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(MessageUI)
import MessageUI
#endif

struct EmergencyView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var healthManager: HealthDataManager
    @State private var emergencyContacts: [EmergencyContact] = []
    @State private var showingContactsSheet = false
    @State private var showingEmergencyAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Emergency Button
                Button(action: initiateEmergencyCall) {
                    VStack {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text("EMERGENCY")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Call Emergency Services")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 200, height: 200)
                    .background(Color.red)
                    .clipShape(Circle())
                }
                .shadow(radius: 10)
                
                // Current Health Status
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Status")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(healthManager.riskLevel.color)
                            .frame(width: 12, height: 12)
                        Text(healthManager.riskLevel.rawValue)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    if let location = locationManager.currentLocation {
                        Text("Location: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Emergency Contacts
                VStack(alignment: .leading) {
                    HStack {
                        Text("Emergency Contacts")
                            .font(.headline)
                        Spacer()
                        Button("Manage") {
                            showingContactsSheet = true
                        }
                    }
                    
                    ForEach(emergencyContacts.prefix(3), id: \.phoneNumber) { contact in
                        EmergencyContactRow(contact: contact)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Emergency")
            .sheet(isPresented: $showingContactsSheet) {
                EmergencyContactsSheet(contacts: $emergencyContacts)
            }
            .alert("Emergency Alert", isPresented: $showingEmergencyAlert) {
                Button("Call Emergency Services") {
                    initiateEmergencyCall()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your health readings indicate a critical condition. Would you like to contact emergency services?")
            }
            .onReceive(NotificationCenter.default.publisher(for: .emergencyAlert)) { _ in
                showingEmergencyAlert = true
            }
        }
    }
    
    private func initiateEmergencyCall() {
        // Create emergency message with health data
        let healthData = """
        MEDICAL EMERGENCY ALERT
        
        Patient Information:
        - Current Risk Level: \(healthManager.riskLevel.rawValue)
        - Heart Rate: \(healthManager.currentVitals.heartRate) bpm
        - Blood Pressure: \(healthManager.currentVitals.systolicBP)/\(healthManager.currentVitals.diastolicBP) mmHg
        - Troponin I: \(String(format: "%.3f", healthManager.currentVitals.troponinI)) ng/mL
        
        Location: \(String(format: "%.6f", locationManager.currentLocation?.coordinate.latitude ?? 0)), \(String(format: "%.6f", locationManager.currentLocation?.coordinate.longitude ?? 0))
        
        Time: \(Date().formatted())
        """
        
        // Call emergency services
        #if canImport(UIKit)
        if let url = URL(string: "tel://911") {
            UIApplication.shared.open(url)
        }
        #endif
        
        // Send SMS to emergency contacts
        sendEmergencySMS(message: healthData)
    }
    
    private func sendEmergencySMS(message: String) {
        #if canImport(MessageUI) && canImport(UIKit)
        guard MessageUI.MFMessageComposeViewController.canSendText() else { return }
        
        let messageVC = MessageUI.MFMessageComposeViewController()
        messageVC.body = message
        messageVC.recipients = emergencyContacts.map { $0.phoneNumber }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(messageVC, animated: true)
        }
        #endif
    }
}

struct EmergencyContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(contact.name)
                    .fontWeight(.medium)
                Text(contact.relationship)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                #if canImport(UIKit)
                if let url = URL(string: "tel://\(contact.phoneNumber)") {
                    UIApplication.shared.open(url)
                }
                #endif
            }) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmergencyContactsSheet: View {
    @Binding var contacts: [EmergencyContact]
    @State private var newContact = EmergencyContact(
        name: "",
        relationship: "",
        phoneNumber: "",
        email: "",
        isPrimary: false
    )
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Add New Contact") {
                    TextField("Name", text: $newContact.name)
                    TextField("Relationship", text: $newContact.relationship)
                    TextField("Phone Number", text: $newContact.phoneNumber)
                        #if os(iOS)
                        .keyboardType(.phonePad)
                        #endif
                    TextField("Email", text: $newContact.email)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        #endif
                    Toggle("Primary Contact", isOn: $newContact.isPrimary)
                    
                    Button("Add Contact") {
                        if !newContact.name.isEmpty && !newContact.phoneNumber.isEmpty {
                            contacts.append(newContact)
                            newContact = EmergencyContact(
                                name: "",
                                relationship: "",
                                phoneNumber: "",
                                email: "",
                                isPrimary: false
                            )
                        }
                    }
                    .disabled(newContact.name.isEmpty || newContact.phoneNumber.isEmpty)
                }
                
                Section("Existing Contacts") {
                    ForEach(contacts, id: \.phoneNumber) { contact in
                        EmergencyContactRow(contact: contact)
                    }
                    .onDelete { indexSet in
                        contacts.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Emergency Contacts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

//
//  LocationManager.swift
//  LifeLens
//
//  Created by Basorge on 15/08/2025.
//

