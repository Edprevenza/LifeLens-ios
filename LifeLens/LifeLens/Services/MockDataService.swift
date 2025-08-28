// MockDataService.swift
import Foundation
import CoreData

class MockDataService {
    static let shared = MockDataService()
    
    private init() {}
    
    // MARK: - Mock User Creation
    
    func createSampleUser() -> UserInfo {
        return UserInfo(
            id: UUID().uuidString,
            email: "demo@lifelens.com",
            firstName: "Demo",
            lastName: "User",
            isEmailVerified: true,
            profileComplete: true
        )
    }
    
    // MARK: - Mock Health Data
    
    func generateMockHealthData() -> MockHealthData {
        return MockHealthData(
            heartRate: Double.random(in: 60...100),
            bloodPressureSystolic: Int.random(in: 110...130),
            bloodPressureDiastolic: Int.random(in: 70...85),
            oxygenSaturation: Double.random(in: 95...100),
            temperature: Double.random(in: 36.5...37.5),
            respiratoryRate: Int.random(in: 12...20),
            glucose: Double.random(in: 70...140),
            weight: Double.random(in: 60...90),
            height: 175.0,
            steps: Int.random(in: 0...15000),
            caloriesBurned: Double.random(in: 1500...3000),
            sleepHours: Double.random(in: 6...9),
            timestamp: Date()
        )
    }
    
    // MARK: - Mock Emergency Contacts
    
    func createSampleEmergencyContacts() -> [EmergencyContact] {
        return [
            EmergencyContact(
                name: "John Doe",
                relationship: "Spouse",
                phone: "+1-555-0100",
                email: "john.doe@example.com"
            ),
            EmergencyContact(
                name: "Jane Smith",
                relationship: "Doctor",
                phone: "+1-555-0101",
                email: "dr.smith@hospital.com"
            ),
            EmergencyContact(
                name: "Emergency Services",
                relationship: "911",
                phone: "911",
                email: ""
            )
        ]
    }
    
    // MARK: - Mock Device Data
    
    func createMockDevice() -> MockDevice {
        return MockDevice(
            id: UUID().uuidString,
            name: "LifeLens Band",
            type: "Wearable",
            manufacturer: "LifeLens Inc.",
            model: "LB-2024",
            firmwareVersion: "2.1.0",
            batteryLevel: Int.random(in: 20...100),
            isConnected: Bool.random(),
            lastSyncDate: Date().addingTimeInterval(-Double.random(in: 0...3600))
        )
    }
    
    // MARK: - Mock Insights
    
    func generateMockInsights() -> [HealthInsight] {
        return [
            HealthInsight(
                title: "Heart Rate Trend",
                description: "Your average heart rate has decreased by 5 BPM this week, indicating improved cardiovascular fitness.",
                category: "Cardiovascular",
                importance: .high
            ),
            HealthInsight(
                title: "Sleep Quality",
                description: "You've been getting consistent 7-8 hours of sleep. Keep up the good routine!",
                category: "Sleep",
                importance: .medium
            ),
            HealthInsight(
                title: "Activity Goal",
                description: "You're 2,000 steps away from your daily goal. A short walk would help you reach it.",
                category: "Activity",
                importance: .medium
            ),
            HealthInsight(
                title: "Hydration Reminder",
                description: "Remember to stay hydrated. You haven't logged water intake in the last 3 hours.",
                category: "Nutrition",
                importance: .low
            )
        ]
    }
    
    // MARK: - Mock Activity Data
    
    func generateMockActivities() -> [Activity] {
        let activities = ["Morning Run", "Yoga Session", "Cycling", "Swimming", "Walking", "Gym Workout"]
        let durations = [30, 45, 60, 90, 120]
        
        return (0..<10).map { index in
            Activity(
                id: UUID().uuidString,
                name: activities.randomElement()!,
                duration: durations.randomElement()!,
                caloriesBurned: Double.random(in: 100...500),
                distance: Double.random(in: 1...10),
                date: Date().addingTimeInterval(-Double(index * 86400)),
                type: ActivityType.allCases.randomElement()!
            )
        }
    }
}

// MARK: - Supporting Models

struct MockHealthData {
    let heartRate: Double
    let bloodPressureSystolic: Int
    let bloodPressureDiastolic: Int
    let oxygenSaturation: Double
    let temperature: Double
    let respiratoryRate: Int
    let glucose: Double
    let weight: Double
    let height: Double
    let steps: Int
    let caloriesBurned: Double
    let sleepHours: Double
    let timestamp: Date
}

struct MockDevice {
    let id: String
    let name: String
    let type: String
    let manufacturer: String
    let model: String
    let firmwareVersion: String
    let batteryLevel: Int
    let isConnected: Bool
    let lastSyncDate: Date
}


struct Activity {
    let id: String
    let name: String
    let duration: Int // in minutes
    let caloriesBurned: Double
    let distance: Double // in km
    let date: Date
    let type: ActivityType
}

enum ActivityType: String, CaseIterable {
    case running = "Running"
    case walking = "Walking"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case yoga = "Yoga"
    case gym = "Gym"
    case other = "Other"
}