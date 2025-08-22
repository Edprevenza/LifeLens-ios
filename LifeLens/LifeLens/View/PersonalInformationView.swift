import SwiftUI

struct PersonalInformationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var gender = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var isEditing = false
    @State private var showingSaveAlert = false
    
    let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]
    
    var body: some View {
        Form {
            Section("Basic Information") {
                if isEditing {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                    TextField("Phone Number", text: $phoneNumber)
                        #if os(iOS)
                        .keyboardType(.phonePad)
                        #endif
                } else {
                    HStack {
                        Text("Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(firstName) \(lastName)")
                    }
                    
                    HStack {
                        Text("Email")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(email)
                    }
                    
                    HStack {
                        Text("Phone")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(phoneNumber.isEmpty ? "Not provided" : phoneNumber)
                            .foregroundColor(phoneNumber.isEmpty ? .secondary : .primary)
                    }
                }
            }
            
            Section("Personal Details") {
                if isEditing {
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("cm", text: $height)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("kg", text: $weight)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Text("Date of Birth")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(dateOfBirth, style: .date)
                    }
                    
                    HStack {
                        Text("Gender")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(gender.isEmpty ? "Not specified" : gender)
                            .foregroundColor(gender.isEmpty ? .secondary : .primary)
                    }
                    
                    HStack {
                        Text("Height")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(height.isEmpty ? "Not provided" : "\(height) cm")
                            .foregroundColor(height.isEmpty ? .secondary : .primary)
                    }
                    
                    HStack {
                        Text("Weight")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(weight.isEmpty ? "Not provided" : "\(weight) kg")
                            .foregroundColor(weight.isEmpty ? .secondary : .primary)
                    }
                }
            }
            
            if !height.isEmpty && !weight.isEmpty {
                Section("Health Metrics") {
                    HStack {
                        Text("BMI")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f", calculateBMI()))
                        Text(bmiCategory())
                            .font(.caption)
                            .foregroundColor(bmiColor())
                    }
                }
            }
            
            Section("Account Information") {
                HStack {
                    Text("Member Since")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("January 2025")
                }
                
                HStack {
                    Text("Account Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .foregroundColor(.green)
                    }
                }
                
                HStack {
                    Text("Email Verified")
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: authService.currentUser?.isEmailVerified == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(authService.currentUser?.isEmailVerified == true ? .green : .red)
                }
            }
        }
        .navigationTitle("Personal Information")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        isEditing = true
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        loadUserData()
                        isEditing = false
                    }
                }
            }
            #else
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        isEditing = true
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        loadUserData()
                        isEditing = false
                    }
                }
            }
            #endif
        }
        .onAppear {
            loadUserData()
        }
        .alert("Changes Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your personal information has been updated successfully.")
        }
    }
    
    private func loadUserData() {
        if let user = authService.currentUser {
            firstName = user.firstName
            lastName = user.lastName
            email = user.email
        }
        
        // Load additional data from UserDefaults or persistent storage
        if let savedData = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: savedData) {
            dateOfBirth = profile.dateOfBirth
            gender = profile.gender
            height = profile.height > 0 ? String(Int(profile.height)) : ""
            weight = profile.weight > 0 ? String(format: "%.1f", profile.weight) : ""
        }
    }
    
    private func saveChanges() {
        // Update auth service user - create new UserInfo since properties are immutable
        if let currentUser = authService.currentUser {
            let updatedUser = UserInfo(
                id: currentUser.id,
                email: email,
                firstName: firstName,
                lastName: lastName,
                isEmailVerified: currentUser.isEmailVerified,
                profileComplete: currentUser.profileComplete
            )
            authService.currentUser = updatedUser
        }
        
        // Save additional profile data
        let profile = UserProfile(
            dateOfBirth: dateOfBirth,
            gender: gender,
            height: Double(height) ?? 0,
            weight: Double(weight) ?? 0,
            activityLevel: "",
            healthGoals: [],
            medicalConditions: [],
            medications: "",
            emergencyContactName: "",
            emergencyContactPhone: ""
        )
        
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
        
        isEditing = false
        showingSaveAlert = true
    }
    
    private func calculateBMI() -> Double {
        guard let heightValue = Double(height),
              let weightValue = Double(weight),
              heightValue > 0 else {
            return 0
        }
        
        let heightInMeters = heightValue / 100
        return weightValue / (heightInMeters * heightInMeters)
    }
    
    private func bmiCategory() -> String {
        let bmi = calculateBMI()
        switch bmi {
        case 0..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal"
        case 25..<30:
            return "Overweight"
        default:
            return "Obese"
        }
    }
    
    private func bmiColor() -> Color {
        let bmi = calculateBMI()
        switch bmi {
        case 0..<18.5:
            return .blue
        case 18.5..<25:
            return .green
        case 25..<30:
            return .orange
        default:
            return .red
        }
    }
}