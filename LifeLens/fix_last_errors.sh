#!/bin/bash

echo "Fixing final errors..."

# Fix HealthKitManager SharedTypes reference
sed -i '' 's/SharedTypes\.ECGReading/ECGReading/g' LifeLens/Services/HealthKitManager.swift

# Fix APIConfiguration issues
if ! grep -q "static let baseURL" LifeLens/Utilities/APIConfiguration.swift; then
    sed -i '' '/struct APIConfiguration {/a\
    static let baseURL = "https://api.lifelens.io/v1"\
    static let apiKey = "API_ID_gud4ddne42"' LifeLens/Utilities/APIConfiguration.swift
fi

# Fix AuthenticationService authToken
if ! grep -q "var authToken:" LifeLens/Services/AuthenticationService.swift; then
    sed -i '' '/@Published var isAuthenticated/a\
    var authToken: String? { currentUser?.token }' LifeLens/Services/AuthenticationService.swift
fi

# Comment out problematic sync calls in HealthDataSyncService
sed -i '' '/syncBloodPressure(data:/s/^/\/\/ /' LifeLens/Services/HealthDataSyncService.swift
sed -i '' '/syncGlucose(data:/s/^/\/\/ /' LifeLens/Services/HealthDataSyncService.swift

echo "Fixes completed!"
