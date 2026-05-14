import Foundation
import Combine

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case forbidden(details: String?)
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
        case .forbidden(let details):
            return details ?? "You don't have permission to access this."
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
    private let maxResponseCacheEntries = 100 // LRU-style bound to prevent unbounded growth
    
    @Published var authToken: String?
    private var refreshToken: String?
    private var refreshTask: Task<RefreshOutcome, Never>?
    
    // Helper to safely read token from any thread
    private var currentToken: String? {
        get async {
            await MainActor.run { authToken }
        }
    }
    
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
            self.baseURL = "https://api.thecoffeelinks.vn"
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
    
    @MainActor
    func setAuthSession(accessToken: String, refreshToken: String?) {
        self.authToken = accessToken
        self.keychainManager.saveAccessToken(accessToken)
        
        if let refresh = refreshToken {
            self.refreshToken = refresh
            self.keychainManager.saveRefreshToken(refresh)
        }

        // App Attest registration is handled in AuthRepository after successful OTP verification
    }
    
    /// Synchronous version of setAuthSession for initialization before UI renders.
    /// Called from DependencyContainer.initializeSync() which runs before any async work.
    /// Must directly assign tokens — wrapping in Task { @MainActor } is NOT synchronous
    /// and the token won't be available for subsequent requests in the same run-loop tick.
    @MainActor
    func setAuthSessionSync(accessToken: String, refreshToken: String?) {
        self.authToken = accessToken
        self.refreshToken = refreshToken
    }
    
    @MainActor
    func clearAuthToken() {
        self.authToken = nil
        self.refreshToken = nil
        self.keychainManager.deleteAccessToken()
        self.keychainManager.deleteRefreshToken()
    }
    
    private enum RefreshOutcome {
        case success
        case failedAuth
        case failedOther(Error)
    }

    // Thread-safe token refresh with task deduplication
    @MainActor
    private func refreshAuthToken() async -> RefreshOutcome {
        await performTokenRefresh(clearAuthOnFailure: true)
    }

    /// Proactive refresh used on app open to extend session lifetime.
    /// Unlike refreshAuthToken(), this avoids clearing tokens on transient network errors.
    @MainActor
    func refreshSessionOnAppOpen() async -> Bool {
        let outcome = await performTokenRefresh(clearAuthOnFailure: false)
        if case .success = outcome { return true }
        return false
    }

    @MainActor
    private func performTokenRefresh(clearAuthOnFailure: Bool) async -> RefreshOutcome {
        if let existingTask = refreshTask {
            return await existingTask.value
        }
        
        let task = Task<RefreshOutcome, Never> { @MainActor in
            guard let currentRefreshToken = self.refreshToken else { return .failedAuth }
            
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
                // Note: _performRequest is async, so we await it. It doesn't need MainActor but we are calling it from MainActor.
                let response: RefreshResponse = try await _performRequest("/api/auth/refresh", method: "POST", body: RefreshRequest(refresh_token: currentRefreshToken), isRetry: true)
                
                self.setAuthSession(accessToken: response.session.access_token, refreshToken: response.session.refresh_token)
                return .success
            } catch let error as NetworkError {
                debugLog("❌ Token Refresh Failed: \(error)")
                switch error {
                case .unauthorized, .forbidden:
                    if clearAuthOnFailure {
                        self.clearAuthToken()
                    }
                    return .failedAuth
                default:
                    return .failedOther(error)
                }
            } catch {
                debugLog("❌ Token Refresh Failed: \(error)")
                return .failedOther(error)
            }
        }
        
        self.refreshTask = task
        let result = await task.value
        self.refreshTask = nil
        return result
    }
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, encoder: JSONEncoder? = nil) async throws -> T {
        do {
            return try await _performRequest(endpoint, method: method, body: body, queryItems: queryItems, encoder: encoder, includeAppAttest: true)
        } catch NetworkError.unauthorized {
            switch await refreshAuthToken() {
            case .success:
                return try await _performRequest(endpoint, method: method, body: body, queryItems: queryItems, encoder: encoder, includeAppAttest: true)
            case .failedAuth:
                throw NetworkError.unauthorized
            case .failedOther(let error):
                throw error
            }
        } catch {
            throw error
        }
    }

    private func _performRequest<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil, queryItems: [URLQueryItem]? = nil, isRetry: Bool = false, encoder: JSONEncoder? = nil, includeAppAttest: Bool = false) async throws -> T {
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
        
        if let token = await currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add App Attest headers for protected endpoints
        if includeAppAttest {
            let bodyData: Data?
            if let body = body {
                let actualEncoder = encoder ?? self.encoder
                bodyData = try? actualEncoder.encode(body)
            } else {
                bodyData = nil
            }
            
            do {
                if let attestHeaders = try await AppAttestNetworkInterceptor.shared.prepareRequest(
                    endpoint: endpoint,
                    body: bodyData
                ) {
                    request.setValue(attestHeaders.keyId, forHTTPHeaderField: "X-App-Attest-Key-Id")
                    request.setValue(attestHeaders.assertion, forHTTPHeaderField: "X-App-Attest-Assertion")
                    request.setValue(attestHeaders.challenge, forHTTPHeaderField: "X-App-Attest-Challenge")
                }
            } catch {
                debugLog("⚠️ [NetworkService] App Attest assertion failed for \(endpoint): \(error.localizedDescription)")
                // Continue without attestation headers — server will reject if attestation is required
            }
        }
        
        if let body = body {
            do {
                let actualEncoder = encoder ?? self.encoder
                let bodyData = try actualEncoder.encode(body)
                request.httpBody = bodyData
                
                if let bodyString = String(data: bodyData, encoding: .utf8) {
                    debugLog("🌐 Request →", method, url.absoluteString)
                    debugLog("🌐 Request Body:", bodyString)
                }
            } catch {
                debugLog("🌐 Request →", method, url.absoluteString)
                debugLog("❌ Failed to encode request body:", error)
                throw NetworkError.networkFailure(error)
            }
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
             throw NetworkError.networkFailure(error)
        }
        
        debugLog("🌐 Request →", method, url.absoluteString)
        guard let httpResponse = response as? HTTPURLResponse else {
            debugLog("❌ Invalid Response (not HTTP)")
             throw NetworkError.unknown
        }
        debugLog("📡 Response Status: \(httpResponse.statusCode)")
        debugLog("📊 Response Size: \(data.count) bytes")
        
        // Handle ETag caching with 24hr TTL
        if method == "GET", let newETag = httpResponse.value(forHTTPHeaderField: "ETag") {
            cacheQueue.sync {
                let cached = CachedETag(etag: newETag, timestamp: Date(), ttl: 86400) // 24hr
                etagCache[endpoint] = cached
                if httpResponse.statusCode != 304 {
                    responseCache[endpoint] = data
                }
                // Evict oldest entries if cache exceeds max size
                if responseCache.count > maxResponseCacheEntries {
                    let sortedKeys = etagCache
                        .sorted { $0.value.timestamp < $1.value.timestamp }
                        .prefix(responseCache.count - maxResponseCacheEntries)
                        .map { $0.key }
                    for key in sortedKeys {
                        responseCache.removeValue(forKey: key)
                        etagCache.removeValue(forKey: key)
                    }
                }
            }
            saveETagCache() // Persist to disk
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            debugLog("📡 Response Body: \(responseString.prefix(300))")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 304:
            // Not Modified - return cached data
            debugLog("✅ 304 Not Modified - Using cached response")
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
            // Try to decode error details from server for 403
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                let details = errorResponse.details ?? errorResponse.error ?? errorResponse.message
                debugLog("[NetworkService] 403 decoded - details: \(details ?? "nil"), error: \(errorResponse.error ?? "nil"), message: \(errorResponse.message ?? "nil")")
                throw NetworkError.forbidden(details: details)
            }
            debugLog("[NetworkService] 403 failed to decode - raw: \(String(data: data, encoding: .utf8) ?? "<invalid>")")
            throw NetworkError.forbidden(details: nil)
        case 404:
             throw NetworkError.notFound
        default:
            // Try to decode error message from server
             if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                 throw NetworkError.serverError(errorResponse.message ?? errorResponse.error ?? "Server error")
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
            switch await refreshAuthToken() {
            case .success:
                try await _performRequestEmpty(endpoint, method: method, body: body, queryItems: queryItems)
            case .failedAuth:
                throw NetworkError.unauthorized
            case .failedOther(let error):
                throw error
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
        debugLog("🌐 Request →", method, url.absoluteString)
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = await currentToken {
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
        
        debugLog("🌐 Request →", method, url.absoluteString)
        guard let httpResponse = response as? HTTPURLResponse else {
            debugLog("❌ Invalid Response (not HTTP)")
            throw NetworkError.unknown
        }
        debugLog("📡 Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            debugLog("📡 Response Body: \(responseString.prefix(300))")
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
        if let token = await currentToken {
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
        
        debugLog("🌐 Request →", method, url.absoluteString)
        guard let httpResponse = response as? HTTPURLResponse else {
            debugLog("❌ Invalid Response (not HTTP)")
            throw NetworkError.unknown
        }
        debugLog("📡 Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            debugLog("📡 Response Body: \(responseString.prefix(300))")
        }
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            await MainActor.run { self.clearAuthToken() }
            throw NetworkError.unauthorized
        case 403:
            // Try to decode error details from server for 403
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                let details = errorResponse.details ?? errorResponse.error ?? errorResponse.message
                debugLog("[NetworkService] 403 decoded - details: \(details ?? "nil"), error: \(errorResponse.error ?? "nil"), message: \(errorResponse.message ?? "nil")")
                throw NetworkError.forbidden(details: details)
            }
            debugLog("[NetworkService] 403 failed to decode - raw: \(String(data: data, encoding: .utf8) ?? "<invalid>")")
            throw NetworkError.forbidden(details: nil)
        case 404:
            throw NetworkError.notFound
        default:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.message ?? errorResponse.error ?? "Server error")
            }
            throw NetworkError.serverError("Server returned code \(httpResponse.statusCode)")
        }
    }
}

struct ErrorResponse: Decodable {
    let message: String?
    let error: String?
    let details: String?
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
