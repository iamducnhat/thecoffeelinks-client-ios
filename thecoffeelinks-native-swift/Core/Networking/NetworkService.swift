import Foundation
import Combine

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case forbidden
    case notFound
    case unknown
    case networkFailure(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please check your connection."
        case .noData:
            return "No data received from server."
        case .decodingError:
            return "Unable to process server response."
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Please sign in again."
        case .forbidden:
            return "You don't have permission to access this."
        case .notFound:
            return "The requested resource was not found."
        case .networkFailure(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}

class NetworkService: ObservableObject {
    private let session: URLSession
    private let baseURL: String
    private var decoder: JSONDecoder
    private var encoder: JSONEncoder
    private let keychainManager: KeychainManager
    
    @Published var authToken: String?
    
    init(keychainManager: KeychainManager) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.keychainManager = keychainManager
        
        // Load base URL from Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let urlString = config["API_BASE_URL"] as? String {
            self.baseURL = urlString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        } else {
            self.baseURL = "https://api.thecoffeelinksvn.com"
        }
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
        
        self.authToken = keychainManager.getAccessToken()
    }
    
    func setAuthToken(_ token: String) async {
        await MainActor.run {
            self.authToken = token
            self.keychainManager.saveAccessToken(token)
        }
    }
    
    func clearAuthToken() async {
        await MainActor.run {
            self.authToken = nil
            self.keychainManager.deleteAccessToken()
        }
    }
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil, queryItems: [URLQueryItem]? = nil) async throws -> T {
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        print("🌐 Request →", method, url.absoluteString)
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("TheCoffeeLinks-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                let bodyData = try encoder.encode(body)
                request.httpBody = bodyData
                
                if let bodyString = String(data: bodyData, encoding: .utf8) {
                    print("🌐 Request Body:", bodyString)
                }
            } catch {
                print("❌ Failed to encode request body:", error)
                throw NetworkError.networkFailure(error)
            }
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.networkFailure(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid Response (not HTTP)")
            throw NetworkError.unknown
        }
        
        print("📡 Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response Body: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            await clearAuthToken()
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        default:
            // Try to decode error message from server
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.message)
            }
            throw NetworkError.serverError("Server returned code \(httpResponse.statusCode)")
        }
    }
    
    // Helper specifically for empty response bodies (e.g. 204 No Content or simple 200 OK)
    func requestEmpty(_ endpoint: String, method: String = "POST", body: Encodable? = nil, queryItems: [URLQueryItem]? = nil) async throws {
         var urlComponents = URLComponents(string: baseURL + endpoint)
         urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        print("🌐 Request →", method, url.absoluteString)
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.networkFailure(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid Response (not HTTP)")
            throw NetworkError.unknown
        }
        
        print("📡 Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response Body: \(responseString)")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
             switch httpResponse.statusCode {
            case 401:
                await clearAuthToken()
                throw NetworkError.unauthorized
            default:
                throw NetworkError.serverError("Server returned code \(httpResponse.statusCode)")
            }
        }
    }

    // Raw data request helper to inspect responses that may not match expected models
    func requestData(_ endpoint: String, method: String = "GET", body: Encodable? = nil, queryItems: [URLQueryItem]? = nil) async throws -> Data {
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else { throw NetworkError.invalidURL }
        print("🌐 Request →", method, url.absoluteString)
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.networkFailure(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid Response (not HTTP)")
            throw NetworkError.unknown
        }
        print("📡 Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response Body: \(responseString)")
        }
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            await clearAuthToken()
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        default:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.message)
            }
            throw NetworkError.serverError("Server returned code \(httpResponse.statusCode)")
        }
    }
}

struct ErrorResponse: Decodable {
    let message: String
}

// MARK: - NetworkServiceProtocol

extension NetworkService: NetworkServiceProtocol {
    func get<T: Decodable>(_ endpoint: String, queryItems: [URLQueryItem]?) async throws -> T {
        try await request(endpoint, method: "GET", body: nil as String?, queryItems: queryItems)
    }
    
    func post<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        try await request(endpoint, method: "POST", body: body)
    }
    
    func put<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        try await request(endpoint, method: "PUT", body: body)
    }
    
    func patch<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        try await request(endpoint, method: "PATCH", body: body)
    }
    
    func delete(_ endpoint: String, queryItems: [URLQueryItem]?) async throws {
        try await requestEmpty(endpoint, method: "DELETE", queryItems: queryItems)
    }
}
