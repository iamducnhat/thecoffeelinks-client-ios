import Foundation

/// Central HTTP API Client for communicating with the backend server
actor APIClient {
    static let shared = APIClient()
    
    private let baseURL = URL(string: "https://server-nu-three-90.vercel.app")!
    private let session: URLSession
    private var authToken: String?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Token Management
    
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    func getAuthToken() -> String? {
        return authToken
    }
    
    // MARK: - HTTP Methods
    
    func get<T: Decodable>(_ endpoint: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = queryItems
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
    
    func post<T: Decodable, E: Encodable>(_ endpoint: String, body: E) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
    
    func patch<T: Decodable, E: Encodable>(_ endpoint: String, body: E) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Response Validation
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(Int)
    case httpError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Authentication required"
        case .notFound:
            return "Resource not found"
        case .serverError(let code):
            return "Server error (\(code))"
        case .httpError(let code):
            return "HTTP error (\(code))"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        }
    }
}
