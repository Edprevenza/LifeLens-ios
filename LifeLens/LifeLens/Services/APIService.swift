// APIService.swift
import Foundation
import Combine

class APIService {
    static let shared = APIService()
    
    private let baseURL = Configuration.shared.fullAPIURL
    private var session = URLSession.shared
    private let logger = AppLogger.shared
    
    private init() {}
    
    // MARK: - Configuration
    
    func updateConfiguration(_ config: URLSessionConfiguration) {
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication Methods
    
    func login(_ request: LoginRequest) -> AnyPublisher<AuthResponse, Error> {
        return makeRequest(endpoint: "/auth/login", method: "POST", body: request)
    }
    
    func register(_ request: RegisterRequest) -> AnyPublisher<AuthResponse, Error> {
        return makeRequest(endpoint: "/auth/register", method: "POST", body: request)
    }
    
    func refreshToken(_ request: TokenRefreshRequest) -> AnyPublisher<AuthResponse, Error> {
        return makeRequest(endpoint: "/auth/refresh", method: "POST", body: request)
    }
    
    func verifyToken(_ token: String) -> AnyPublisher<Bool, Error> {
        return makeRequest(endpoint: "/auth/verify", method: "POST", body: ["token": token])
    }
    
    func resetPassword(email: String) -> AnyPublisher<Bool, Error> {
        return makeRequest(endpoint: "/auth/reset-password", method: "POST", body: ["email": email])
    }
    
    // MARK: - Health Data Methods
    
    func sendVitals(_ data: [String: Any]) -> AnyPublisher<Bool, Error> {
        return makeRequest(endpoint: "/health/vitals", method: "POST", body: data)
    }
    
    func sendProcessedMLData(_ data: [String: Any]) -> AnyPublisher<Bool, Error> {
        return makeRequest(endpoint: "/health/ml-data", method: "POST", body: data)
    }
    
    func sendCriticalAlert(_ data: [String: Any]) -> AnyPublisher<Bool, Error> {
        return makeRequest(endpoint: "/health/alerts", method: "POST", body: data)
    }
    
    func fetchAlerts() -> AnyPublisher<[HealthAlert], Error> {
        guard let url = URL(string: baseURL + "/health/alerts") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        if let tokenData = KeychainService().retrieve(key: "accessToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add common headers
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        request.setValue("1.0.1", forHTTPHeaderField: "X-App-Version")
        request.setValue("fwynbeqn5k", forHTTPHeaderField: "X-API-ID")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode >= 400 {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: [HealthAlert].self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.decodingError
                }
            }
            .eraseToAnyPublisher()
    }
    
    func fetchHealthMetrics(page: Int, limit: Int) async throws -> HealthMetricsResponse {
        guard let url = URL(string: "\(baseURL)/health/metrics?page=\(page)&limit=\(limit)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        if let tokenData = KeychainService().retrieve(key: "accessToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add common headers
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        request.setValue("1.0.1", forHTTPHeaderField: "X-App-Version")
        request.setValue("fwynbeqn5k", forHTTPHeaderField: "X-API-ID")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(HealthMetricsResponse.self, from: data)
    }
    
    func uploadHealthMetric(_ metric: HealthMetric) async throws {
        guard let url = URL(string: "\(baseURL)/health/metrics") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        if let tokenData = KeychainService().retrieve(key: "accessToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add common headers
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        request.setValue("1.0.1", forHTTPHeaderField: "X-App-Version")
        request.setValue("fwynbeqn5k", forHTTPHeaderField: "X-API-ID")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(metric)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Generic Request Method
    
    private func makeRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: String,
        body: T
    ) -> AnyPublisher<U, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        if let tokenData = KeychainService().retrieve(key: "accessToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add common headers
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        request.setValue("1.0.1", forHTTPHeaderField: "X-App-Version")
        request.setValue("fwynbeqn5k", forHTTPHeaderField: "X-API-ID")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return Fail(error: APIError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode >= 400 {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: U.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.decodingError
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: String,
        body: [String: Any]
    ) -> AnyPublisher<T, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        if let tokenData = KeychainService().retrieve(key: "accessToken"),
           let token = String(data: tokenData, encoding: .utf8) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add common headers
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        request.setValue("1.0.1", forHTTPHeaderField: "X-App-Version")
        request.setValue("fwynbeqn5k", forHTTPHeaderField: "X-API-ID")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: APIError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode >= 400 {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.decodingError
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - API Models
// Authentication models are defined in models/AuthenticationModels.swift

// MARK: - Health Models


struct HealthMetricsResponse: Codable {
    let metrics: [HealthMetric]
    let totalCount: Int
    let page: Int
    let hasMore: Bool
}


// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case encodingError
    case decodingError
    case invalidResponse
    case serverError(Int)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError:
            return "Failed to decode response"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError:
            return "Network connection error"
        }
    }
}