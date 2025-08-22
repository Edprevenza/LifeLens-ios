// Utilities/APIConfiguration.swift
import Foundation

/**
 * API Configuration Helper
 * 
 * To set your API Gateway ID, you have two options:
 * 
 * 1. Set an environment variable in Xcode:
 *    - Edit Scheme > Run > Arguments > Environment Variables
 *    - Add: LIFELENS_API_ID = your-api-id-here
 * 
 * 2. Update the default value in Configuration.swift:
 *    - Replace "your-api-id-here" with your actual API Gateway ID
 * 
 * The API endpoints are:
 * - POST /v1/health/blood-pressure
 * - POST /v1/health/glucose
 * - POST /v1/health/spo2
 * - POST /v1/health/ecg
 * - POST /v1/health/troponin
 * - GET  /v1/alerts
 * 
 * All requests require:
 * - Content-Type: application/json
 * - userid: {user_id} (automatically added by APIService)
 */

class APIConfiguration {
    
    static func printCurrentConfiguration() {
        let config = Configuration.shared
        
        print("==================================")
        print("LIFELENS API CONFIGURATION")
        print("==================================")
        print("API Endpoint: \(config.apiBaseURL)")
        print("Full URL: \(config.fullAPIURL)")
        print("")
        print("Authentication Endpoints:")
        print("- POST \(config.fullAPIURL)/auth/register")
        print("- POST \(config.fullAPIURL)/auth/login")
        print("- POST \(config.fullAPIURL)/auth/verify")
        print("- POST \(config.fullAPIURL)/auth/refresh")
        print("")
        print("Health Endpoints:")
        print("- POST \(config.fullAPIURL)/health/blood-pressure")
        print("- POST \(config.fullAPIURL)/health/glucose")
        print("- GET  \(config.fullAPIURL)/alerts")
        print("")
        print("Headers Required:")
        print("- Content-Type: application/json")
        print("- Authorization: Bearer {token}")
        print("==================================")
    }
    
    static func validateAPIConnection(completion: @escaping (Bool, String) -> Void) {
        // Test connection to API by fetching alerts
        let apiService = APIService.shared
        
        _ = apiService.fetchAlerts()
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished:
                        completion(true, "API connection successful")
                    case .failure(let error):
                        completion(false, "API connection failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { alerts in
                    print("Fetched \(alerts.count) alerts from API")
                }
            )
    }
    
    static func setAPIID(_ apiID: String) {
        // Store in UserDefaults for persistence
        UserDefaults.standard.set(apiID, forKey: "LIFELENS_API_ID")
        UserDefaults.standard.synchronize()
        
        print("API ID updated to: \(apiID)")
        print("Restart the app for changes to take effect")
    }
    
    static func getStoredAPIID() -> String? {
        return UserDefaults.standard.string(forKey: "LIFELENS_API_ID")
    }
}