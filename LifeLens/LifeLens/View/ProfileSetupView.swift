import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var currentStep = 1
    @State private var dateOfBirth = Date()
    @State private var gender = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var activityLevel = ""
    @State private var healthGoals: Set<String> = []
    @State private var medicalConditions: Set<String> = []
    @State private var medications = ""
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""
    
    let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]
    let activityLevels = ["Sedentary", "Lightly Active", "Moderately Active", "Very Active", "Extremely Active"]
    let healthGoalOptions = ["Lose Weight", "Gain Muscle", "Improve Sleep", "Reduce Stress", "Better Nutrition", "Increase Activity", "Monitor Health"]
    let medicalConditionOptions = ["Diabetes", "Hypertension", "Heart Disease", "Asthma", "Arthritis", "None"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ProgressBar(currentStep: currentStep, totalSteps: 4)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                
                TabView(selection: $currentStep) {
                    BasicInfoStep(
                        dateOfBirth: $dateOfBirth,
                        gender: $gender,
                        genderOptions: genderOptions
                    )
                    .tag(1)
                    
                    PhysicalInfoStep(
                        height: $height,
                        weight: $weight,
                        activityLevel: $activityLevel,
                        activityLevels: activityLevels
                    )
                    .tag(2)
                    
                    HealthGoalsStep(
                        healthGoals: $healthGoals,
                        medicalConditions: $medicalConditions,
                        medications: $medications,
                        healthGoalOptions: healthGoalOptions,
                        medicalConditionOptions: medicalConditionOptions
                    )
                    .tag(3)
                    
                    EmergencyContactStep(
                        emergencyContactName: $emergencyContactName,
                        emergencyContactPhone: $emergencyContactPhone
                    )
                    .tag(4)
                }
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                #endif
                
                HStack(spacing: 16) {
                    if currentStep > 1 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Previous")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.gray.opacity(0.2))
                                
            .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                    }
                    
                    Button(action: {
                        if currentStep < 4 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            completeProfileSetup()
                        }
                    }) {
                        Text(currentStep < 4 ? "Next" : "Complete Setup")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blue)
                            
            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Complete Your Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        skipProfileSetup()
                    }
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Skip") {
                        skipProfileSetup()
                    }
                }
                #endif
            }
        }
    }
    
    func completeProfileSetup() {
        let profile = UserProfile(
            dateOfBirth: dateOfBirth,
            gender: gender,
            height: Double(height) ?? 0,
            weight: Double(weight) ?? 0,
            activityLevel: activityLevel,
            healthGoals: Array(healthGoals),
            medicalConditions: Array(medicalConditions),
            medications: medications,
            emergencyContactName: emergencyContactName,
            emergencyContactPhone: emergencyContactPhone
        )
        
        saveProfile(profile)
    }
    
    func skipProfileSetup() {
        if var user = authService.currentUser {
            user.profileComplete = true
            authService.currentUser = user
        }
    }
    
    func saveProfile(_ profile: UserProfile) {
        if var user = authService.currentUser {
            user.profileComplete = true
            authService.currentUser = user
        }
    }
}

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 4)
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 6)
            }
        }
    }
}

struct BasicInfoStep: View {
    @Binding var dateOfBirth: Date
    @Binding var gender: String
    let genderOptions: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Basic Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Help us personalize your health monitoring experience")
                    .font(.body)
                    
            .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Date of Birth")
                        .font(.headline)
                    
                    DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                        #if os(iOS)
                        .datePickerStyle(CompactDatePickerStyle())
                        #else
                        .datePickerStyle(DefaultDatePickerStyle())
                        #endif
                        .labelsHidden()
                        .frame(maxHeight: 50)
                        .padding(.vertical, 8)
                }
                .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gender")
                        .font(.headline)
                    
                    ForEach(genderOptions, id: \.self) { option in
                        Button(action: {
                            gender = option
                        }) {
                            HStack {
                                Image(systemName: gender == option ? "checkmark.circle.fill" : "circle")
                                    
            .foregroundColor(gender == option ? .blue : .gray)
                                Text(option)
                                    
            .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct PhysicalInfoStep: View {
    @Binding var height: String
    @Binding var weight: String
    @Binding var activityLevel: String
    let activityLevels: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Physical Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This helps us calculate accurate health metrics")
                    .font(.body)
                    
            .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height (cm)")
                        .font(.headline)
                    TextField("Enter your height", text: $height)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)")
                        .font(.headline)
                    TextField("Enter your weight", text: $weight)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Level")
                        .font(.headline)
                    
                    ForEach(activityLevels, id: \.self) { level in
                        Button(action: {
                            activityLevel = level
                        }) {
                            HStack {
                                Image(systemName: activityLevel == level ? "checkmark.circle.fill" : "circle")
                                    
            .foregroundColor(activityLevel == level ? .blue : .gray)
                                Text(level)
                                    
            .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct HealthGoalsStep: View {
    @Binding var healthGoals: Set<String>
    @Binding var medicalConditions: Set<String>
    @Binding var medications: String
    let healthGoalOptions: [String]
    let medicalConditionOptions: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Health Goals & Medical Info")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Health Goals")
                        .font(.headline)
                    Text("Select all that apply")
                        .font(.caption)
                        
            .foregroundColor(.secondary)
                    
                    ForEach(healthGoalOptions, id: \.self) { goal in
                        Button(action: {
                            if healthGoals.contains(goal) {
                                healthGoals.remove(goal)
                            } else {
                                healthGoals.insert(goal)
                            }
                        }) {
                            HStack {
                                Image(systemName: healthGoals.contains(goal) ? "checkmark.square.fill" : "square")
                                    
            .foregroundColor(healthGoals.contains(goal) ? .blue : .gray)
                                Text(goal)
                                    
            .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medical Conditions")
                        .font(.headline)
                    Text("Select all that apply")
                        .font(.caption)
                        
            .foregroundColor(.secondary)
                    
                    ForEach(medicalConditionOptions, id: \.self) { condition in
                        Button(action: {
                            if medicalConditions.contains(condition) {
                                medicalConditions.remove(condition)
                            } else {
                                medicalConditions.insert(condition)
                            }
                        }) {
                            HStack {
                                Image(systemName: medicalConditions.contains(condition) ? "checkmark.square.fill" : "square")
                                    
            .foregroundColor(medicalConditions.contains(condition) ? .blue : .gray)
                                Text(condition)
                                    
            .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Medications (Optional)")
                        .font(.headline)
                    TextField("List your current medications", text: $medications)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Emergency Contact Step
struct EmergencyContactStep: View {
    @Binding var emergencyContactName: String
    @Binding var emergencyContactPhone: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Emergency Contact")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Who should we contact in case of emergency?")
                .font(.subheadline)
                
            .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Contact Name")
                    .font(.caption)
                    
            .foregroundColor(.secondary)
                TextField("Full Name", text: $emergencyContactName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.caption)
                    
            .foregroundColor(.secondary)
                TextField("Phone Number", text: $emergencyContactPhone)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
            }
            
            Spacer()
        }
        .padding()
    }
}
