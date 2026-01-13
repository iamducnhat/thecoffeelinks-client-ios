import Foundation

/// Defines the requirement for the APIClient to delegate auth refresh logic
protocol AuthDelegate: AnyObject {
    func refreshToken() async throws -> String
}

/// Central HTTP API Client for communicating with the backend server
actor APIClient {
    static let shared = APIClient()
    
    // Using a weak delegate to avoid retain cycles
    private weak var authDelegate: AuthDelegate?
    
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
    
    func setAuthDelegate(_ delegate: AuthDelegate) {
        self.authDelegate = delegate
    }
    
    // MARK: - URL Construction
    
    private func buildURL(for endpoint: String) throws -> URL {
        var url = baseURL
        // Split path by / to avoid percent encoding the slashes
        let components = endpoint.components(separatedBy: "/").filter { !$0.isEmpty }
        for component in components {
            url.appendPathComponent(component)
        }
        return url
    }
    
    // MARK: - HTTP Methods
    
    func get<T: Decodable>(_ endpoint: String, queryItems: [URLQueryItem]? = nil, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase, retryCount: Int = 1) async throws -> T {
        let url = try buildURL(for: endpoint)
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw APIError.invalidResponse
        }
        urlComponents.queryItems = queryItems
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        do {
            try validateResponse(response, data: data, for: request)
        } catch APIError.unauthorized(_) where retryCount > 0 {
            // Attempt refresh
            if let delegate = authDelegate {
                let newToken = try await delegate.refreshToken()
                self.authToken = newToken
                // Recursively retry
                return try await get(endpoint, queryItems: queryItems, keyDecodingStrategy: keyDecodingStrategy, retryCount: retryCount - 1)
            } else {
                throw APIError.unauthorized(nil)
            }
        } catch {
            throw error
        }
        
        return try decode(data: data, keyDecodingStrategy: keyDecodingStrategy)
    }
    
    func post<T: Decodable, E: Encodable>(_ endpoint: String, body: E, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase, retryCount: Int = 1) async throws -> T {
        let url = try buildURL(for: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        do {
            try validateResponse(response, data: data, for: request)
        } catch APIError.unauthorized(_) where retryCount > 0 {
            // Attempt refresh
            if let delegate = authDelegate {
                let newToken = try await delegate.refreshToken()
                self.authToken = newToken
                // Recursively retry
                return try await post(endpoint, body: body, keyDecodingStrategy: keyDecodingStrategy, keyEncodingStrategy: keyEncodingStrategy, retryCount: retryCount - 1)
            } else {
                throw APIError.unauthorized(nil)
            }
        } catch {
            throw error
        }
        
        return try decode(data: data, keyDecodingStrategy: keyDecodingStrategy)
    }
    
    func patch<T: Decodable, E: Encodable>(_ endpoint: String, body: E, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase, retryCount: Int = 1) async throws -> T {
        let url = try buildURL(for: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        do {
            try validateResponse(response, data: data, for: request)
        } catch APIError.unauthorized(_) where retryCount > 0 {
            // Attempt refresh
            if let delegate = authDelegate {
                let newToken = try await delegate.refreshToken()
                self.authToken = newToken
                // Recursively retry
                return try await patch(endpoint, body: body, keyDecodingStrategy: keyDecodingStrategy, keyEncodingStrategy: keyEncodingStrategy, retryCount: retryCount - 1)
            } else {
                throw APIError.unauthorized(nil)
            }
        } catch {
            throw error
        }
        
        return try decode(data: data, keyDecodingStrategy: keyDecodingStrategy)
    }
    
    /// Special method for performing token refresh to avoid circular dependency and interception recursion
    func performTokenRefresh(refreshToken: String) async throws -> LoginAPIResponse {
        let url = try buildURL(for: "api/auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // NOTE: Refresh token typically sent in body
        
        struct RefreshBody: Encodable {
            let refresh_token: String
        }
        
        let body = RefreshBody(refresh_token: refreshToken)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data, for: request)
        
        return try decode(data: data)
    }
    
    // MARK: - Helpers
    
    private func decode<T: Decodable>(data: Data, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try standard ISO8601
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - API Errors
    
    enum APIError: LocalizedError {
        case invalidResponse
        case unauthorized(String?)
        case notFound
        case serverError(Int)
        case httpError(Int, String?, url: String? = nil, method: String? = nil)
        case decodingError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid server response"
            case .unauthorized(let message):
                return message ?? "Invalid credentials"
            case .notFound:
                return "Resource not found"
            case .serverError(let code):
                return "Server error (\(code))"
            case .httpError(let code, let message, let url, let method):
                var desc = message ?? "HTTP error (\(code))"
                if let method = method, let url = url {
                    desc += " [\(method) \(url.description)]"
                }
                return desc
            case .decodingError(let error):
                return "Data parsing error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Response Validation
    
    private func validateResponse(_ response: URLResponse, data: Data, for request: URLRequest) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Try to decode error message from body if exists
        func extractErrorMessage() -> String? {
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            return (json["error"] as? String) ?? (json["message"] as? String)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized(extractErrorMessage())
        case 404:
            throw APIError.notFound
        case 500...599:
            if let message = extractErrorMessage() {
                throw APIError.httpError(httpResponse.statusCode, message, url: request.url?.absoluteString, method: request.httpMethod)
            }
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.httpError(httpResponse.statusCode, extractErrorMessage(), url: request.url?.absoluteString, method: request.httpMethod)
        }
    }
}
