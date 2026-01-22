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
    
    // ENHANCED: Persistent ETag cache with TTL
    private struct CachedETag: Codable {
        let etag: String
        let timestamp: Date
        let ttl: TimeInterval // 24 hours default
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }
    
    private let etagCacheKey = "com.thecoffeelinks.etag-cache"
    private let responseCacheKey = "com.thecoffeelinks.response-cache"
    private var etagCache: [String: CachedETag] = [:]
    private var responseCache: [String: Data] = [:]
    private let cacheQueue = DispatchQueue(label: "com.thecoffeelinks.etag-cache")
    
    @Published var authToken: String?
    private var refreshToken: String?
    private var refreshTask: Task<Bool, Never>?
    
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
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        self.authToken = keychainManager.getAccessToken()
        self.refreshToken = keychainManager.getRefreshToken()
        
        // Load persistent ETag cache
        loadETagCache()
    }
    
    // MARK: - Persistent ETag Cache
    
    private func loadETagCache() {
        cacheQueue.async { [weak self] in
            guard let self = self,
                  let data = UserDefaults.standard.data(forKey: self.etagCacheKey),
                  let loaded = try? JSONDecoder().decode([String: CachedETag].self, from: data) else { return }
            
            // Filter out expired entries
            let valid = loaded.filter { !$0.value.isExpired }
            self.etagCache = valid
        }
    }
    
    private func saveETagCache() {
        cacheQueue.async { [weak self] in
            guard let self = self,
                  let data = try? JSONEncoder().encode(self.etagCache) else { return }
            UserDefaults.standard.set(data, forKey: self.etagCacheKey)
        }
    }
    
    func clearCache() async {
        await MainActor.run {
            cacheQueue.sync {
                etagCache.removeAll()
                responseCache.removeAll()
                UserDefaults.standard.removeObject(forKey: etagCacheKey)
                UserDefaults.standard.removeObject(forKey: responseCacheKey)
            }
        }
    }
    
    func setAuthSession(accessToken: String, refreshToken: String?) async {
        await MainActor.run {
            self.authToken = accessToken
            self.keychainManager.saveAccessToken(accessToken)
            
            if let refresh = refreshToken {
                self.refreshToken = refresh
                self.keychainManager.saveRefreshToken(refresh)
            }
        }
    }
    
    func clearAuthToken() async {
        await MainActor.run {
            self.authToken = nil
            self.refreshToken = nil
            self.keychainManager.deleteAccessToken()
            self.keychainManager.deleteRefreshToken()
        }
    }
    
    // Thread-safe token refresh with task deduplication
    private func refreshAuthToken() async -> Bool {
        if let existingTask = refreshTask {
            return await existingTask.value
        }
        
        let task = Task<Bool, Never> {
            guard let currentRefreshToken = self.refreshToken else { return false }
            
            struct RefreshRequest: Encodable {
                let refresh_token: String
            }
            
            struct RefreshResponse: Decodable {
                let success: Bool?
                let session: SessionData
                
                struct SessionData: Decodable {
                    let access_token: String
                    let refresh_token: String
                }
            }
            
            do {
                // We use a raw request here to avoid infinite loops if this fails with 401
                let response: RefreshResponse = try await _performRequest("/api/auth/refresh", method: "POST", body: RefreshRequest(refresh_token: currentRefreshToken), isRetry: true)
                
                await setAuthSession(accessToken: response.session.access_token, refreshToken: response.session.refresh_token)
                return true
            } catch {
                print("❌ Token Refresh Failed: \(error)")
                await clearAuthToken()
                return false
            }
        }
        
        self.refreshTask = task
        let result = await task.value
        self.refreshTask = nil
        return result
    }
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, encoder: JSONEncoder? = nil) async throws -> T {
        do {
            return try await _performRequest(endpoint, method: method, body: body, queryItems: queryItems, encoder: encoder)
        } catch NetworkError.unauthorized {
            if await refreshAuthToken() {
                return try await _performRequest(endpoint, method: method, body: body, queryItems: queryItems, encoder: encoder)
            } else {
                throw NetworkError.unauthorized
            }
        } catch {
            throw error
        }
    }

    private func _performRequest<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, isRetry: Bool = false, encoder: JSONEncoder? = nil) async throws -> T {
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("TheCoffeeLinks-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add ETag support for GET requests (check if not expired)
        if method == "GET" {
            if let cached = cacheQueue.sync(execute: { etagCache[endpoint] }), !cached.isExpired {
                request.setValue(cached.etag, forHTTPHeaderField: "If-None-Match")
            }
        }
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                let actualEncoder = encoder ?? self.encoder
                let bodyData = try actualEncoder.encode(body)
                request.httpBody = bodyData
                
                if let bodyString = String(data: bodyData, encoding: .utf8) {
                    print("🌐 Request →", method, url.absoluteString)
                    print("🌐 Request Body:", bodyString)
                }
            } catch {
                print("🌐 Request →", method, url.absoluteString)
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
        
        print("🌐 Request →", method, url.absoluteString)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid Response (not HTTP)")
             throw NetworkError.unknown
        }
        print("📡 Response Status: \(httpResponse.statusCode)")
        print("📊 Response Size: \(data.count) bytes")
        
        // Handle ETag caching with 24hr TTL
        if method == "GET", let newETag = httpResponse.value(forHTTPHeaderField: "ETag") {
            cacheQueue.sync {
                let cached = CachedETag(etag: newETag, timestamp: Date(), ttl: 86400) // 24hr
                etagCache[endpoint] = cached
                if httpResponse.statusCode != 304 {
                    responseCache[endpoint] = data
                }
            }
            saveETagCache() // Persist to disk
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response Body: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 304:
            // Not Modified - return cached data
            print("✅ 304 Not Modified - Using cached response")
            if let cachedData = cacheQueue.sync(execute: { responseCache[endpoint] }) {
                return try decoder.decode(T.self, from: cachedData)
            } else {
                throw NetworkError.noData
            }
        case 401:
            // Do not clear token here, let the caller handle it (try refresh)
            // unless it's already a retry
            if isRetry {
                 await clearAuthToken()
             }
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
        do {
             // We can reuse _performRequest but we need it to return Data or Void.
             // Easier to just replicate the retry logic here or adapt _performRequest to Generic but T could be Void? Swift doesn't like that.
             // I'll make a _performRequestEmpty
             try await _performRequestEmpty(endpoint, method: method, body: body, queryItems: queryItems)
        } catch NetworkError.unauthorized {
            if await refreshAuthToken() {
                 try await _performRequestEmpty(endpoint, method: method, body: body, queryItems: queryItems)
            } else {
                throw NetworkError.unauthorized
            }
        } catch {
             throw error
        }
    }
    
    private func _performRequestEmpty(_ endpoint: String, method: String = "POST", body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, isRetry: Bool = false) async throws {
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
        
        print("🌐 Request →", method, url.absoluteString)
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
                 if isRetry { await clearAuthToken() }
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
        
        print("🌐 Request →", method, url.absoluteString)
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
    
    func post<T: Decodable, U: Encodable>(_ endpoint: String, body: U, encoder: JSONEncoder? = nil) async throws -> T {
        try await request(endpoint, method: "POST", body: body, encoder: encoder)
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
