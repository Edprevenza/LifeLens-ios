// EmergencyResponseSystem.swift

import UIKit

// Worldwide emergency response system with automatic crisis detection

import Foundation
import CoreLocation
import CoreTelephony
import CallKit
import UserNotifications
import AVFoundation
import Combine
import Network
import Contacts

/**
 * Emergency Response System
 * Detects medical crises and automatically contacts emergency services
 * Works worldwide with region-specific emergency numbers
 */
class EmergencyResponseSystem: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = EmergencyResponseSystem()
    
    // MARK: - Properties
    
    @Published var isEmergencyActive = false
    @Published var emergencyStatus: EmergencyStatus = .idle
    @Published var countdownSeconds: Int = 10
    @Published var currentLocation: CLLocation?
    @Published var vitalsStreamingActive = false
    
    private let locationManager = CLLocationManager()
    private let callController = CXCallController()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var emergencyTimer: Timer?
    private var vitalsStreamTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Network monitoring
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "com.lifelens.emergency.network")
    
    // Emergency contacts
    private var emergencyContacts: [EmergencyContact] = []
    private let contactStore = CNContactStore()
    
    // Vital signs streaming
    private var vitalsWebSocket: URLSessionWebSocketTask?
    private let vitalsSession = URLSession(configuration: .default)
    
    // MARK: - Models
    
    enum EmergencyStatus {
        case idle
        case analyzing
        case countdown(seconds: Int)
        case contacting
        case connected
        case failed(reason: String)
    }
    
    struct EmergencyContact: Codable {
        let id: String
        let name: String
        let phoneNumber: String
        let relationship: String
        let priority: Int
    }
    
    struct EmergencyData {
        let riskScore: Float
        let condition: String
        let vitals: VitalSigns
        let medications: [String]
        let allergies: [String]
        let bloodType: String?
        let medicalConditions: [String]
    }
    
    struct VitalSigns {
        let heartRate: Int
        let bloodPressure: (systolic: Int, diastolic: Int)
        let spo2: Int
        let temperature: Float
        let respiratoryRate: Int
        let ecgData: [Float]?
    }
    
    struct EmergencyLocation {
        let latitude: Double
        let longitude: Double
        let altitude: Double?
        let accuracy: Double
        let address: String?
        let landmark: String?
        let floor: Int?
        let room: String?
    }
    
    // MARK: - Emergency Numbers Database
    
    private let emergencyNumbers: [String: EmergencyService] = [
        // North America
        "US": EmergencyService(primary: "911", medical: "911", fire: "911", police: "911"),
        "CA": EmergencyService(primary: "911", medical: "911", fire: "911", police: "911"),
        "MX": EmergencyService(primary: "911", medical: "065", fire: "068", police: "060"),
        
        // Europe
        "GB": EmergencyService(primary: "999", medical: "999", fire: "999", police: "999", eu: "112"),
        "FR": EmergencyService(primary: "112", medical: "15", fire: "18", police: "17"),
        "DE": EmergencyService(primary: "112", medical: "112", fire: "112", police: "110"),
        "IT": EmergencyService(primary: "112", medical: "118", fire: "115", police: "113"),
        "ES": EmergencyService(primary: "112", medical: "061", fire: "080", police: "091"),
        "NL": EmergencyService(primary: "112", medical: "112", fire: "112", police: "112"),
        "BE": EmergencyService(primary: "112", medical: "100", fire: "100", police: "101"),
        "CH": EmergencyService(primary: "112", medical: "144", fire: "118", police: "117"),
        "AT": EmergencyService(primary: "112", medical: "144", fire: "122", police: "133"),
        "PL": EmergencyService(primary: "112", medical: "999", fire: "998", police: "997"),
        "SE": EmergencyService(primary: "112", medical: "112", fire: "112", police: "112"),
        "NO": EmergencyService(primary: "112", medical: "113", fire: "110", police: "112"),
        "DK": EmergencyService(primary: "112", medical: "112", fire: "112", police: "112"),
        "FI": EmergencyService(primary: "112", medical: "112", fire: "112", police: "112"),
        "PT": EmergencyService(primary: "112", medical: "112", fire: "112", police: "112"),
        "GR": EmergencyService(primary: "112", medical: "166", fire: "199", police: "100"),
        "IE": EmergencyService(primary: "999", medical: "999", fire: "999", police: "999", eu: "112"),
        
        // Asia
        "JP": EmergencyService(primary: "110", medical: "119", fire: "119", police: "110"),
        "CN": EmergencyService(primary: "110", medical: "120", fire: "119", police: "110"),
        "IN": EmergencyService(primary: "112", medical: "108", fire: "101", police: "100"),
        "KR": EmergencyService(primary: "112", medical: "119", fire: "119", police: "112"),
        "SG": EmergencyService(primary: "999", medical: "995", fire: "995", police: "999"),
        "MY": EmergencyService(primary: "999", medical: "999", fire: "994", police: "999"),
        "TH": EmergencyService(primary: "191", medical: "1669", fire: "199", police: "191"),
        "ID": EmergencyService(primary: "112", medical: "118", fire: "113", police: "110"),
        "PH": EmergencyService(primary: "911", medical: "911", fire: "911", police: "911"),
        "VN": EmergencyService(primary: "113", medical: "115", fire: "114", police: "113"),
        "AE": EmergencyService(primary: "999", medical: "998", fire: "997", police: "999"),
        "SA": EmergencyService(primary: "911", medical: "997", fire: "998", police: "999"),
        "IL": EmergencyService(primary: "100", medical: "101", fire: "102", police: "100"),
        "TR": EmergencyService(primary: "112", medical: "112", fire: "110", police: "155"),
        
        // Oceania
        "AU": EmergencyService(primary: "000", medical: "000", fire: "000", police: "000"),
        "NZ": EmergencyService(primary: "111", medical: "111", fire: "111", police: "111"),
        
        // South America
        "BR": EmergencyService(primary: "190", medical: "192", fire: "193", police: "190"),
        "AR": EmergencyService(primary: "911", medical: "107", fire: "100", police: "911"),
        "CL": EmergencyService(primary: "133", medical: "131", fire: "132", police: "133"),
        "CO": EmergencyService(primary: "123", medical: "125", fire: "119", police: "112"),
        "PE": EmergencyService(primary: "105", medical: "106", fire: "116", police: "105"),
        
        // Africa
        "ZA": EmergencyService(primary: "10111", medical: "10177", fire: "10111", police: "10111"),
        "EG": EmergencyService(primary: "122", medical: "123", fire: "180", police: "122"),
        "NG": EmergencyService(primary: "112", medical: "112", fire: "112", police: "112"),
        "KE": EmergencyService(primary: "999", medical: "999", fire: "999", police: "999"),
        
        // Default/Universal
        "DEFAULT": EmergencyService(primary: "112", medical: "112", fire: "112", police: "112")
    ]
    
    struct EmergencyService {
        let primary: String
        let medical: String
        let fire: String
        let police: String
        let eu: String?
        
        init(primary: String, medical: String, fire: String, police: String, eu: String? = nil) {
            self.primary = primary
            self.medical = medical
            self.fire = fire
            self.police = police
            self.eu = eu
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationServices()
        setupNetworkMonitoring()
        loadEmergencyContacts()
        requestPermissions()
    }
    
    // MARK: - Setup
    
    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            if path.status != .satisfied {
                print("⚠️ Network unavailable - emergency calls may still work")
                self?.attemptOfflineEmergencyProtocol()
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func requestPermissions() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { _, _ in }
        
        // Request contacts permission
        contactStore.requestAccess(for: .contacts) { _, _ in }
        
        // Configure audio session for emergency
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    // MARK: - Crisis Detection
    
    /**
     * Main entry point for crisis detection
     * Automatically triggers emergency response if risk score > 0.9
     */
    func detectCrisis(riskScore: Float, condition: String = "Medical Emergency", vitals: VitalSigns? = nil) {
        print("🚨 Crisis detection - Risk score: \(riskScore)")
        
        guard riskScore > 0.9 else {
            print("Risk score below emergency threshold")
            return
        }
        
        emergencyStatus = .analyzing
        
        // Create emergency data
        let emergencyData = EmergencyData(
            riskScore: riskScore,
            condition: condition,
            vitals: vitals ?? getCurrentVitals(),
            medications: loadMedications(),
            allergies: loadAllergies(),
            bloodType: loadBloodType(),
            medicalConditions: loadMedicalConditions()
        )
        
        // Start emergency sequence
        initiateEmergencySequence(with: emergencyData)
    }
    
    private func initiateEmergencySequence(with data: EmergencyData) {
        isEmergencyActive = true
        countdownSeconds = 10
        emergencyStatus = .countdown(seconds: countdownSeconds)
        
        // Announce emergency
        announceEmergency(data: data)
        
        // Show critical alert
        showEmergencyAlert(data: data)
        
        // Start countdown
        emergencyTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.countdownSeconds -= 1
            self.emergencyStatus = .countdown(seconds: self.countdownSeconds)
            
            if self.countdownSeconds <= 0 {
                timer.invalidate()
                self.executeEmergencyProtocol(data: data)
            }
        }
    }
    
    /**
     * Cancel emergency countdown
     */
    func cancelEmergency() {
        emergencyTimer?.invalidate()
        emergencyTimer = nil
        isEmergencyActive = false
        emergencyStatus = .idle
        stopVitalsStreaming()
        
        // Cancel any pending calls
        callController.requestTransaction(with: []) { error in
            if let error = error {
                print("Failed to cancel calls: \(error)")
            }
        }
    }
    
    // MARK: - Emergency Protocol Execution
    
    private func executeEmergencyProtocol(data: EmergencyData) {
        emergencyStatus = .contacting
        
        Task {
            do {
                // 1. Get current location
                let location = await getCurrentLocation()
                
                // 2. Call emergency services
                let emergencyNumber = getEmergencyNumber(for: location)
                await callEmergencyServices(number: emergencyNumber, location: location, data: data)
                
                // 3. Share GPS location
                await shareLocationWithEMS(location: location)
                
                // 4. Start streaming vitals
                await startVitalsStreaming(to: emergencyNumber, data: data)
                
                // 5. Notify emergency contacts
                await notifyEmergencyContacts(data: data, location: location)
                
                emergencyStatus = .connected
                
            } catch {
                emergencyStatus = .failed(reason: error.localizedDescription)
                print("Emergency protocol failed: \(error)")
                
                // Fallback: Try basic emergency call
                fallbackEmergencyCall()
            }
        }
    }
    
    // MARK: - Emergency Services Call
    
    private func callEmergencyServices(number: String, location: EmergencyLocation?, data: EmergencyData) async {
        print("📞 Calling emergency services: \(number)")
        
        // Create call action
        let handle = CXHandle(type: .phoneNumber, value: number)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        startCallAction.isVideo = false
        startCallAction.contactIdentifier = "Emergency Services"
        
        let transaction = CXTransaction(action: startCallAction)
        
        await withCheckedContinuation { continuation in
            callController.request(transaction) { error in
                if let error = error {
                    print("Error making emergency call: \(error)")
                    // Try alternative method
                    self.makeDirectEmergencyCall(number: number)
                } else {
                    print("Emergency call initiated successfully")
                }
                continuation.resume()
            }
        }
    }
    
    private func makeDirectEmergencyCall(number: String) {
        if let url = URL(string: "tel://\(number)") {
            #if canImport(UIKit)
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            #endif
        }
    }
    
    // MARK: - Location Services
    
    private func getCurrentLocation() async -> EmergencyLocation {
        guard let location = currentLocation else {
            return EmergencyLocation(
                latitude: 0,
                longitude: 0,
                altitude: nil,
                accuracy: 0,
                address: nil,
                landmark: nil,
                floor: nil,
                room: nil
            )
        }
        
        // Geocode for address
        let address = await reverseGeocode(location: location)
        
        return EmergencyLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            accuracy: location.horizontalAccuracy,
            address: address,
            landmark: detectNearbyLandmark(location: location),
            floor: location.floor?.level,
            room: nil
        )
    }
    
    private func reverseGeocode(location: CLLocation) async -> String? {
        return await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                guard let placemark = placemarks?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let address = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                
                continuation.resume(returning: address)
            }
        }
    }
    
    private func detectNearbyLandmark(location: CLLocation) -> String? {
        // In production, use POI database or Maps API
        return nil
    }
    
    // MARK: - Emergency Number Detection
    
    private func getEmergencyNumber(for location: EmergencyLocation?) -> String {
        // Try to get country code from various sources
        
        // 1. From cellular carrier
        if let countryCode = getCountryFromCarrier() {
            return emergencyNumbers[countryCode]?.medical ?? emergencyNumbers["DEFAULT"]!.medical
        }
        
        // 2. From device locale
        if let countryCode = Locale.current.regionCode {
            return emergencyNumbers[countryCode]?.medical ?? emergencyNumbers["DEFAULT"]!.medical
        }
        
        // 3. From GPS location (would need reverse geocoding)
        // This would require additional API calls
        
        // 4. Default to universal emergency number
        return "112" // Works in most countries
    }
    
    private func getCountryFromCarrier() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrier = networkInfo.serviceSubscriberCellularProviders?.values.first {
            return carrier.isoCountryCode?.uppercased()
        }
        return nil
    }
    
    // MARK: - Location Sharing
    
    private func shareLocationWithEMS(location: EmergencyLocation) async {
        // Create location message
        let locationMessage = """
        📍 EMERGENCY LOCATION:
        Coordinates: \(location.latitude), \(location.longitude)
        Accuracy: \(location.accuracy)m
        \(location.address ?? "Address not available")
        \(location.landmark != nil ? "Near: \(location.landmark!)" : "")
        \(location.floor != nil ? "Floor: \(location.floor!)" : "")
        
        Google Maps: https://maps.google.com/?q=\(location.latitude),\(location.longitude)
        Apple Maps: https://maps.apple.com/?ll=\(location.latitude),\(location.longitude)
        """
        
        // Send SMS to emergency services (if supported)
        // Note: Most emergency services now support SMS
        await sendEmergencySMS(message: locationMessage)
        
        // Also share via emergency API if available
        await shareViaEmergencyAPI(location: location)
    }
    
    private func sendEmergencySMS(message: String) async {
        // Implementation depends on carrier and region
        print("Emergency SMS: \(message)")
    }
    
    private func shareViaEmergencyAPI(location: EmergencyLocation) async {
        // Many regions have APIs for emergency location sharing
        // Example: RapidSOS in the US
        guard let url = URL(string: "https://api-sandbox.rapidsos.com/v1/location") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "latitude": location.latitude,
            "longitude": location.longitude,
            "accuracy": location.accuracy,
            "altitude": location.altitude ?? 0
        ] as [String: Any]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("Location shared via API: \(httpResponse.statusCode)")
            }
        } catch {
            print("Failed to share location via API: \(error)")
        }
    }
    
    // MARK: - Vitals Streaming
    
    private func startVitalsStreaming(to emergencyService: String, data: EmergencyData) async {
        print("📊 Starting vitals streaming to EMS")
        vitalsStreamingActive = true
        
        // Create WebSocket connection to emergency services
        guard let url = URL(string: "wss://emergency-stream.lifelens.health/vitals") else { return }
        
        vitalsWebSocket = vitalsSession.webSocketTask(with: url)
        vitalsWebSocket?.resume()
        
        // Send initial vitals
        await sendVitalsUpdate(data.vitals)
        
        // Start periodic updates
        vitalsStreamTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.sendVitalsUpdate(self.getCurrentVitals())
            }
        }
    }
    
    private func sendVitalsUpdate(_ vitals: VitalSigns) async {
        guard let webSocket = vitalsWebSocket else { return }
        
        let vitalsData = [
            "timestamp": Date().timeIntervalSince1970,
            "heartRate": vitals.heartRate,
            "bloodPressure": [
                "systolic": vitals.bloodPressure.systolic,
                "diastolic": vitals.bloodPressure.diastolic
            ],
            "spo2": vitals.spo2,
            "temperature": vitals.temperature,
            "respiratoryRate": vitals.respiratoryRate
        ] as [String: Any]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: vitalsData) {
            let message = URLSessionWebSocketTask.Message.data(jsonData)
            do {
                try await webSocket.send(message)
            } catch {
                print("Failed to send vitals: \(error)")
            }
        }
    }
    
    private func stopVitalsStreaming() {
        vitalsStreamingActive = false
        vitalsStreamTimer?.invalidate()
        vitalsStreamTimer = nil
        vitalsWebSocket?.cancel(with: .goingAway, reason: nil)
        vitalsWebSocket = nil
    }
    
    // MARK: - Emergency Contacts
    
    private func loadEmergencyContacts() {
        // Load from UserDefaults or KeyChain
        if let data = UserDefaults.standard.data(forKey: "emergency_contacts"),
           let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            emergencyContacts = contacts
        }
    }
    
    private func notifyEmergencyContacts(data: EmergencyData, location: EmergencyLocation) async {
        print("📱 Notifying emergency contacts")
        
        for contact in emergencyContacts.sorted(by: { $0.priority < $1.priority }) {
            await notifyContact(contact, data: data, location: location)
        }
    }
    
    private func notifyContact(_ contact: EmergencyContact, data: EmergencyData, location: EmergencyLocation) async {
        let message = """
        🚨 MEDICAL EMERGENCY ALERT
        
        \(contact.name), this is an automated emergency alert.
        
        Condition: \(data.condition)
        Risk Level: Critical (\(Int(data.riskScore * 100))%)
        
        Vitals:
        • Heart Rate: \(data.vitals.heartRate) bpm
        • BP: \(data.vitals.bloodPressure.systolic)/\(data.vitals.bloodPressure.diastolic)
        • SpO2: \(data.vitals.spo2)%
        
        Location: \(location.address ?? "Unknown")
        GPS: \(location.latitude), \(location.longitude)
        Maps: https://maps.apple.com/?ll=\(location.latitude),\(location.longitude)
        
        Emergency services have been contacted.
        """
        
        // Send SMS
        // In production, use Twilio or similar service
        print("SMS to \(contact.phoneNumber): \(message)")
        
        // Also try to call
        await callContact(contact)
    }
    
    private func callContact(_ contact: EmergencyContact) async {
        // Similar to emergency services call
        let handle = CXHandle(type: .phoneNumber, value: contact.phoneNumber)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        startCallAction.contactIdentifier = contact.name
        
        let transaction = CXTransaction(action: startCallAction)
        callController.request(transaction) { error in
            if let error = error {
                print("Failed to call \(contact.name): \(error)")
            }
        }
    }
    
    // MARK: - UI Helpers
    
    private func showEmergencyAlert(data: EmergencyData) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 EMERGENCY PROTOCOL ACTIVATED"
        content.body = "Medical emergency detected. Calling emergency services in \(countdownSeconds) seconds. Tap to cancel."
        content.sound = .defaultCritical
        content.interruptionLevel = .critical
        content.relevanceScore = 1.0
        
        let request = UNNotificationRequest(
            identifier: "emergency_alert",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func announceEmergency(data: EmergencyData) {
        let announcement = "Emergency detected. Risk level critical. Calling emergency services in \(countdownSeconds) seconds. Say cancel to stop."
        
        let utterance = AVSpeechUtterance(string: announcement)
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Fallback Methods
    
    private func attemptOfflineEmergencyProtocol() {
        // Even without internet, emergency calls should work
        makeDirectEmergencyCall(number: "911") // Or appropriate local number
    }
    
    private func fallbackEmergencyCall() {
        // Try multiple emergency numbers
        let numbers = ["112", "911", "999", "000"]
        
        for number in numbers {
            if let url = URL(string: "tel://\(number)") {
                #if canImport(UIKit)
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    break
                }
                #endif
            }
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func getCurrentVitals() -> VitalSigns {
        // Get from health monitoring system
        return VitalSigns(
            heartRate: 75,
            bloodPressure: (120, 80),
            spo2: 98,
            temperature: 98.6,
            respiratoryRate: 16,
            ecgData: nil
        )
    }
    
    private func loadMedications() -> [String] {
        // Load from health records
        return UserDefaults.standard.stringArray(forKey: "medications") ?? []
    }
    
    private func loadAllergies() -> [String] {
        // Load from health records
        return UserDefaults.standard.stringArray(forKey: "allergies") ?? []
    }
    
    private func loadBloodType() -> String? {
        // Load from health records
        return UserDefaults.standard.string(forKey: "blood_type")
    }
    
    private func loadMedicalConditions() -> [String] {
        // Load from health records
        return UserDefaults.standard.stringArray(forKey: "medical_conditions") ?? []
    }
}

// MARK: - CLLocationManagerDelegate

extension EmergencyResponseSystem: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}