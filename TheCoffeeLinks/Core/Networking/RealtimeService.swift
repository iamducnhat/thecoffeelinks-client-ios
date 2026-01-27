//
//  RealtimeService.swift
//  thecoffeelinks-client-ios
//
//  Lightweight Supabase Realtime Client (Phoenix Protocol)
//  No external dependencies required.
//

import Foundation
import Combine

// MARK: - Models

struct RealtimeMessage: Codable {
    let topic: String
    let event: String
    let payload: [String: AnyCodable]
    let ref: String?
    
    enum CodingKeys: String, CodingKey {
        case topic, event, payload, ref
    }
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try decoding in order of specificity
        // Wrap all attempts to catch any nested decode failures
        do {
            if let x = try container.decode(String.self) as String? { 
                value = x
                return
            }
        } catch { }
        
        do {
            if let x = try container.decode(Int.self) as Int? { 
                value = x
                return
            }
        } catch { }
        
        do {
            if let x = try container.decode(Double.self) as Double? { 
                value = x
                return
            }
        } catch { }
        
        do {
            if let x = try container.decode(Bool.self) as Bool? { 
                value = x
                return
            }
        } catch { }
        
        do {
            if let x = try container.decode([String: AnyCodable].self) as [String: AnyCodable]? {
                print(x)
                value = x.mapValues { $0.value }
                return
            }
        } catch { }
        
        do {
            if let x = try container.decode([AnyCodable].self) as [AnyCodable]? { 
                value = x.map { $0.value }
                return
            }
        } catch { }
        
        if container.decodeNil() { 
            value = NSNull()
        }
        else {
            // Fallback: store null for unknown types
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let x = value as? String { try container.encode(x) }
        else if let x = value as? Int { try container.encode(x) }
        else if let x = value as? Double { try container.encode(x) }
        else if let x = value as? Bool { try container.encode(x) }
        else if let x = value as? [String: Any] { 
            // Safely encode dictionary by filtering out non-encodable values
            let safeDict = x.compactMapValues { value -> AnyCodable? in
                if value is String || value is Int || value is Double || value is Bool {
                    return AnyCodable(value)
                } else if let dict = value as? [String: Any] {
                    return AnyCodable(dict)
                } else if let arr = value as? [Any] {
                    return AnyCodable(arr)
                } else if value is NSNull {
                    return AnyCodable(NSNull())
                }
                return nil // Skip non-encodable types
            }
            try container.encode(safeDict)
        }
        else if let x = value as? [Any] {
            // Safely encode array by filtering out non-encodable values
            let safeArray = x.compactMap { value -> AnyCodable? in
                if value is String || value is Int || value is Double || value is Bool {
                    return AnyCodable(value)
                } else if let dict = value as? [String: Any] {
                    return AnyCodable(dict)
                } else if let arr = value as? [Any] {
                    return AnyCodable(arr)
                } else if value is NSNull {
                    return AnyCodable(NSNull())
                }
                return nil // Skip non-encodable types
            }
            try container.encode(safeArray)
        }
        else if value is NSNull {
            try container.encodeNil()
        }
        else { 
            // For unknown types, encode nil
            try container.encodeNil()
        }
    }
}

enum RealtimeEvent {
    case connected
    case disconnected(Error?)
    case message(RealtimeMessage)
    case postgresChange(PostgresChange)
}

struct PostgresChange: Codable {
    let schema: String
    let table: String
    let commitTimestamp: String?
    let eventType: String // INSERT, UPDATE, DELETE
    let new: [String: AnyCodable]?
    let old: [String: AnyCodable]?
    let errors: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case schema, table
        case commitTimestamp = "commit_timestamp"
        case eventType = "type"
        case new = "record"
        case old = "old_record"
        case errors
    }
}

// MARK: - Service

final class RealtimeService: ObservableObject {
    private var socket: URLSessionWebSocketTask?
    private let urlSession: URLSession
    private let baseURL: String
    private let apiKey: String
    @Published private(set) var isConnected = false
    private var heartbeatTimer: Timer?
    private var reconnectTimer: Timer?
    
    // Auth
    private var accessToken: String?
    
    // Pub/Sub
    let eventSubject = PassthroughSubject<RealtimeEvent, Never>()
    
    // Subscriptions
    private var channels: Set<String> = []
    
    init(baseURL: String, apiKey: String) {
        // Convert https://... to wss://...
        let wsURL = baseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        
        self.baseURL = wsURL
        self.apiKey = apiKey
        
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForResource = 300 // Keep trying for 5 min
        self.urlSession = URLSession(configuration: configuration)
        
        log("Initialized with \(wsURL)")
    }
    
    private func log(_ message: String) {
        print("[Realtime] \(message)")
    }
    
    func setAuthToken(_ token: String) {
        self.accessToken = token
        if isConnected {
            // Reconnect to apply new token
            disconnect()
            connect()
        }
    }
    
    func connect() {
        guard !isConnected else { return }
        
        log("Connecting...")
        var components = URLComponents(string: "\(baseURL)/realtime/v1/websocket")!
        components.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "vsn", value: "1.0.0")
        ]
        
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 10
        
        socket = urlSession.webSocketTask(with: request)
        socket?.resume()
        
        receiveMessage()
        startHeartbeat()
        
        isConnected = true
        eventSubject.send(.connected)
        log("Socket Resumed (Connected)")
        
        // Re-subscribe to channels
        for channel in channels {
            joinChannel(channel)
        }
    }
    
    func disconnect() {
        log("Disconnecting...")
        socket?.cancel(with: .normalClosure, reason: nil)
        heartbeatTimer?.invalidate()
        isConnected = false
        eventSubject.send(.disconnected(nil))
    }
    
    func subscribe(to table: String, filter: String? = nil) {
        var topic = "realtime:public:\(table)"
        if let filter = filter {
            topic += ":\(filter)"
        }
        
        if !channels.contains(topic) {
            channels.insert(topic)
            if isConnected {
                joinChannel(topic)
            }
        }
    }
    
    private func joinChannel(_ topic: String) {
        log("Joining \(topic)...")
        let _: [String: Any] = [
            "config": [
                "postgres_changes": [
                    [
                        "event": "*",
                        "schema": "public",
                        "table": topic.split(separator: ":")[2] // extract table name
                    ]
                ]
            ]
        ]
        
        var joinPayload: [String: Any] = [:]
        if let token = accessToken {
            log("Config: WITH Token")
            joinPayload["access_token"] = token
        } else {
            log("Config: No Token (Anon)")
        }
        
        // ... (Parsing logic same as before)
        // Correct topic parsing:
        let parts = topic.split(separator: ":")
        let table = String(parts[2])
        let filter = parts.count > 3 ? String(parts[3]) : nil
        
        var postgresChanges: [String: Any] = [
            "event": "*",
            "schema": "public",
            "table": table
        ]
        if let filter = filter {
            postgresChanges["filter"] = filter
        }
        
        joinPayload["config"] = [
            "postgres_changes": [postgresChanges]
        ]
        
        let message: [String: Any] = [
            "topic": topic,
            "event": "phx_join",
            "payload": joinPayload,
            "ref": "1" // Simplified ref
        ]
        
        sendMessage(message)
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let string = String(data: data, encoding: .utf8) else { return }
        
        // log("Sending: \(message["event"] ?? "") to \(message["topic"] ?? "")")
        socket?.send(.string(string)) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.log("Send Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func receiveMessage() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.log("<< \(text.prefix(100))") // Log partial
                        self.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.log("<< Data: \(text.prefix(50))")
                            self.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    self.receiveMessage() // Continue listening
                    
                case .failure(let error):
                    self.log("Receive Error: \(error.localizedDescription)")
                    self.isConnected = false
                    self.eventSubject.send(.disconnected(error))
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.log("Reconnecting...")
                        self.connect()
                    }
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let message = try? JSONDecoder().decode(RealtimeMessage.self, from: data) else {
            return
        }
        
        // Handle Heartbeat Reply
        if message.event == "phx_reply" && message.ref == "heartbeat" {
            // Heartbeat ACK
            return
        }
        
        // Handle Postgres Changes
        if message.event == "postgres_changes" {
            // Supabase wraps the actual change data in a "data" key
            let changeData: AnyCodable
            if let data = message.payload["data"] {
                changeData = data
            } else {
                // Fallback or if structure is flat
                changeData = AnyCodable(message.payload)
            }
            
            do {
                let payloadData = try JSONEncoder().encode(changeData)
                if let change = try? JSONDecoder().decode(PostgresChange.self, from: payloadData) {
                    DispatchQueue.main.async {
                        self.eventSubject.send(.postgresChange(change))
                    }
                } else {
            DispatchQueue.main.async { [weak self] in
                self?.log("Failed to decode PostgresChange from payload")
            }
                }
            } catch {
            DispatchQueue.main.async { [weak self] in
                self?.log("Error encoding PostgresChange payload: \(error.localizedDescription)")
            }
            }
        }
        
        // Pass generic message
        DispatchQueue.main.async {
            self.eventSubject.send(.message(message))
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            let message: [String: Any] = [
                "topic": "phoenix",
                "event": "heartbeat",
                "payload": [:],
                "ref": "heartbeat"
            ]
            self?.sendMessage(message)
        }
    }
}
