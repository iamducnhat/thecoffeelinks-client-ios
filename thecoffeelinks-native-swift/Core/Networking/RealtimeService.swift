//
//  RealtimeService.swift
//  thecoffeelinks-native-swift
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
        if let x = try? container.decode(String.self) { value = x }
        else if let x = try? container.decode(Int.self) { value = x }
        else if let x = try? container.decode(Double.self) { value = x }
        else if let x = try? container.decode(Bool.self) { value = x }
        else if let x = try? container.decode([String: AnyCodable].self) { value = x.mapValues { $0.value } }
        else if let x = try? container.decode([AnyCodable].self) { value = x.map { $0.value } }
        else if container.decodeNil() { value = NSNull() }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown value") }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let x = value as? String { try container.encode(x) }
        else if let x = value as? Int { try container.encode(x) }
        else if let x = value as? Double { try container.encode(x) }
        else if let x = value as? Bool { try container.encode(x) }
        else if let x = value as? [String: Any] { 
            let anyCodableDict = x.mapValues { AnyCodable($0) }
            try container.encode(anyCodableDict)
        }
        else { try container.encodeNil() }
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
        
        // Re-subscribe to channels
        for channel in channels {
            joinChannel(channel)
        }
    }
    
    func disconnect() {
        socket?.cancel(with: .normalClosure, reason: nil)
        heartbeatTimer?.invalidate()
        isConnected = false
        eventSubject.send(.disconnected(nil))
    }
    
    func subscribe(to table: String, filter: String? = nil) {
        // Topic format: realtime:public:table:filter
        // e.g. realtime:public:orders:user_id=eq.UUID
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
        let payload: [String: Any] = [
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
        
        if let token = accessToken {
            // Send access_token for RLS
            // Format: ["access_token": token] in payload? No, usually separate or in join_ref
            // Supabase Realtime expects access_token in the JOIN payload
             var config = payload["config"] as! [String: Any]
             // Actually, usually it's passed as key "access_token" in payload
        }
        
        // Construct the Phoenix "phx_join" message
        // [JoinRef, Ref, Topic, Event, Payload]
        // But we use JSON object format for better readability using struct
        
        var joinPayload: [String: Any] = [:]
        if let token = accessToken {
            joinPayload["access_token"] = token
        }
        
        // For Postgres Changes, we need to specify what we want in the config
        // Actually, for simplicity we just join the channel and assume the client wants updates on the topic entity
        // Realtime V2 Protocol:
        // Join Payload: { "config": { "postgres_changes": [...] }, "access_token": "..." }
        
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
        
        socket?.send(.string(string)) { error in
            if let error = error {
                print("[Realtime] Send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMessage() // Continue listening
                
            case .failure(let error):
                print("[Realtime] Receive error: \(error)")
                self.isConnected = false
                self.eventSubject.send(.disconnected(error))
                // Retry logic could go here
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.connect()
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
            if let payloadData = try? JSONEncoder().encode(message.payload),
               let change = try? JSONDecoder().decode(PostgresChange.self, from: payloadData) {
                
                DispatchQueue.main.async {
                    self.eventSubject.send(.postgresChange(change))
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
