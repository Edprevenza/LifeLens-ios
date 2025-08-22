// Models/UserProfile.swift
import Foundation
import SwiftUI

struct UserProfile: Codable {
    let dateOfBirth: Date
    let gender: String
    let height: Double
    let weight: Double
    let activityLevel: String
    let healthGoals: [String]
    let medicalConditions: [String]
    let medications: String
    let emergencyContactName: String
    let emergencyContactPhone: String
    
    init(dateOfBirth: Date = Date(),
         gender: String = "",
         height: Double = 0,
         weight: Double = 0,
         activityLevel: String = "",
         healthGoals: [String] = [],
         medicalConditions: [String] = [],
         medications: String = "",
         emergencyContactName: String = "",
         emergencyContactPhone: String = "") {
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.height = height
        self.weight = weight
        self.activityLevel = activityLevel
        self.healthGoals = healthGoals
        self.medicalConditions = medicalConditions
        self.medications = medications
        self.emergencyContactName = emergencyContactName
        self.emergencyContactPhone = emergencyContactPhone
    }
}

struct ProfileDisplayView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack {
            Text("Profile Display")
        }
    }
}

struct EmptyProfileView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            Text("No profile information")
                .font(.headline)
                .padding(.top)
            Text("Tap Edit to add your profile")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
