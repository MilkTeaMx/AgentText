//
//  MessageWatcherService.swift
//  AgentText
//
//  Watches for messages via SSE stream and detects @mentions
//

import Foundation
import Combine

/// Represents a context message from the chat history
struct ContextMessage: Identifiable, Equatable {
    let id: String
    let text: String
    let isFromMe: Bool
    let sender: String?
    let date: Date
}

/// Represents a detected mention from a message
struct DetectedMention: Identifiable, Equatable {
    let id = UUID()
    let mention: String
    let fullText: String
    let timestamp: Date
    let contextMessages: [ContextMessage]
    let contextCount: Int
    
    init(mention: String, fullText: String, timestamp: Date = Date(), contextMessages: [ContextMessage] = [], contextCount: Int = 0) {
        self.mention = mention
        self.fullText = fullText
        self.timestamp = timestamp
        self.contextMessages = contextMessages
        self.contextCount = contextCount
    }
    
    static func == (lhs: DetectedMention, rhs: DetectedMention) -> Bool {
        lhs.id == rhs.id
    }
}

/// Service that watches messages via Server-Sent Events and detects @mentions
class MessageWatcherService: NSObject, ObservableObject, URLSessionDataDelegate {
    static let shared = MessageWatcherService()
    
    @Published var isWatching = false
    @Published var latestMention: DetectedMention?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    enum ConnectionStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    private var streamTask: URLSessionDataTask?
    private var session: URLSession?
    private let baseURL = "http://localhost:3000"
    private var buffer = ""
    
    override init() {
        super.init()
    }
    
    /// Start watching for messages
    func startWatching() async {
        guard !isWatching else { 
            print("[MessageWatcher] Already watching, skipping start")
            return 
        }
        
        print("[MessageWatcher] Starting watcher...")
        
        await MainActor.run {
            connectionStatus = .connecting
        }
        
        // Wait for server to be available (retry a few times)
        var serverReady = false
        for attempt in 1...5 {
            do {
                let health = try await AgentTextClient.shared.checkHealth()
                if health {
                    serverReady = true
                    break
                }
            } catch {
                print("[MessageWatcher] Server not ready (attempt \(attempt)/5): \(error.localizedDescription)")
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
        
        guard serverReady else {
            print("[MessageWatcher] Server not available after 5 attempts")
            await MainActor.run {
                connectionStatus = .error("Server not available")
            }
            return
        }
        
        // Start the watcher on the server
        do {
            let result = try await AgentTextClient.shared.startWatcher()
            print("[MessageWatcher] Watcher started successfully: \(result)")
        } catch {
            print("[MessageWatcher] Error starting watcher: \(error.localizedDescription)")
            // Check if it's already running
            do {
                let status = try await AgentTextClient.shared.getWatcherStatus()
                if status.active {
                    print("[MessageWatcher] Watcher was already active, continuing...")
                } else {
                    await MainActor.run {
                        connectionStatus = .error("Failed to start watcher")
                    }
                    return
                }
            } catch {
                print("[MessageWatcher] Could not check status: \(error)")
                await MainActor.run {
                    connectionStatus = .error("Failed to start watcher")
                }
                return
            }
        }
        
        // Connect to SSE stream
        print("[MessageWatcher] Connecting to SSE stream...")
        connectToStream()
    }
    
    /// Stop watching for messages
    func stopWatching() async {
        streamTask?.cancel()
        streamTask = nil
        session?.invalidateAndCancel()
        session = nil
        buffer = ""
        
        await MainActor.run {
            isWatching = false
            connectionStatus = .disconnected
        }
        
        // Stop the server watcher
        do {
            let _ = try await AgentTextClient.shared.stopWatcher()
        } catch {
            print("[MessageWatcher] Error stopping watcher: \(error)")
        }
    }
    
    private func connectToStream() {
        guard let url = URL(string: "\(baseURL)/watcher/stream") else {
            print("[MessageWatcher] Invalid stream URL!")
            Task { @MainActor in
                connectionStatus = .error("Invalid URL")
            }
            return
        }
        
        print("[MessageWatcher] Connecting to: \(url)")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(Int.max)
        config.timeoutIntervalForResource = TimeInterval(Int.max)
        
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        streamTask = session?.dataTask(with: request)
        streamTask?.resume()
        print("[MessageWatcher] Stream task started")
    }
    
    // MARK: - URLSessionDataDelegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("[MessageWatcher] Received response: \(response)")
        if let httpResponse = response as? HTTPURLResponse {
            print("[MessageWatcher] HTTP status: \(httpResponse.statusCode)")
            if httpResponse.statusCode == 200 {
                Task { @MainActor in
                    self.isWatching = true
                    self.connectionStatus = .connected
                    print("[MessageWatcher] ✅ Connected and watching!")
                }
            }
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        print("[MessageWatcher] Received data: \(chunk.prefix(100))...")
        
        buffer += chunk
        processBuffer()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("[MessageWatcher] Task completed with error: \(String(describing: error))")
        Task { @MainActor in
            self.isWatching = false
            if let error = error {
                print("[MessageWatcher] ❌ Connection error: \(error.localizedDescription)")
                if (error as NSError).code != NSURLErrorCancelled {
                    self.connectionStatus = .error(error.localizedDescription)
                    // Try to reconnect after a delay
                    print("[MessageWatcher] Will retry in 3 seconds...")
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                    if self.connectionStatus != .disconnected {
                        self.connectToStream()
                    }
                }
            } else {
                print("[MessageWatcher] Connection closed normally")
                self.connectionStatus = .disconnected
            }
        }
    }
    
    // MARK: - SSE Parsing
    
    private func processBuffer() {
        // SSE format: "data: {...}\n\n"
        let lines = buffer.components(separatedBy: "\n\n")
        
        // Keep the last incomplete chunk in buffer
        if !buffer.hasSuffix("\n\n") && lines.count > 1 {
            buffer = lines.last ?? ""
        } else if buffer.hasSuffix("\n\n") {
            buffer = ""
        } else {
            // Not enough data yet
            return
        }
        
        for line in lines.dropLast() {
            processSSELine(line)
        }
        
        // If buffer ended with \n\n, process all lines
        if buffer.isEmpty && !lines.isEmpty {
            for line in lines where !line.isEmpty {
                processSSELine(line)
            }
        }
    }
    
    private func processSSELine(_ line: String) {
        // Skip heartbeat comments
        if line.hasPrefix(":") { return }
        
        // Parse "data: {...}" format
        guard line.hasPrefix("data: ") else { return }
        
        let jsonString = String(line.dropFirst(6)) // Remove "data: "
        guard let jsonData = jsonString.data(using: .utf8) else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                handleSSEEvent(json)
            }
        } catch {
            print("[MessageWatcher] JSON parse error: \(error)")
        }
    }
    
    private func handleSSEEvent(_ event: [String: Any]) {
        guard let eventType = event["event"] as? String else { return }
        
        switch eventType {
        case "message":
            if let messageData = event["message"] as? [String: Any] {
                processMessage(messageData)
            }
        case "connected":
            print("[MessageWatcher] Connected to stream")
        case "error":
            if let errorMsg = event["error"] as? String {
                print("[MessageWatcher] Stream error: \(errorMsg)")
            }
        default:
            break
        }
    }
    
    private func processMessage(_ messageData: [String: Any]) {
        // Debug: print the entire message data
        print("[MessageWatcher] Received messageData: \(messageData)")
        
        // Only process messages sent by the user (isFromMe = true)
        guard let isFromMe = messageData["isFromMe"] as? Bool, isFromMe else {
            print("[MessageWatcher] Skipping message: isFromMe=\(messageData["isFromMe"] ?? "nil")")
            return
        }
        
        guard let text = messageData["text"] as? String else {
            print("[MessageWatcher] Skipping message: no text")
            return
        }
        
        // Get the chatId for fetching context messages
        let chatId = messageData["chatId"] as? String
        
        // Look for @mentions with optional count in the text
        let mentionResults = extractMentionsWithCount(from: text)
        print("[MessageWatcher] Found \(mentionResults.count) mentions in: \(text)")
        for (m, c) in mentionResults {
            print("[MessageWatcher] - mention: '\(m)', count: \(c)")
        }
        
        for (mention, count) in mentionResults {
            print("[MessageWatcher] Processing mention '\(mention)' with count \(count), chatId: \(chatId ?? "nil")")
            // If there's a count and a chatId, fetch context messages
            if count > 0, let chatId = chatId {
                print("[MessageWatcher] Fetching \(count) context messages for chat: \(chatId)")
                Task {
                    // Small delay to ensure the trigger message is in the database
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    
                    let contextMessages = await fetchContextMessages(chatId: chatId, count: count)
                    print("[MessageWatcher] Fetched \(contextMessages.count) context messages")
                    for (i, ctx) in contextMessages.enumerated() {
                        print("[MessageWatcher] Context[\(i)]: \(ctx.text)")
                    }
                    
                    let detected = DetectedMention(
                        mention: mention,
                        fullText: text,
                        timestamp: Date(),
                        contextMessages: contextMessages,
                        contextCount: count
                    )
                    
                    await MainActor.run {
                        self.latestMention = detected
                    }
                }
            } else {
                let detected = DetectedMention(
                    mention: mention,
                    fullText: text,
                    timestamp: Date()
                )
                
                Task { @MainActor in
                    self.latestMention = detected
                }
            }
        }
    }
    
    /// Fetch the last N messages from a specific chat
    private func fetchContextMessages(chatId: String, count: Int) async -> [ContextMessage] {
        do {
            // Fetch more messages than needed since:
            // 1. We'll exclude the trigger message
            // 2. Some messages might not have text (reactions, edits, etc.)
            // We request 3x the count to ensure we get enough messages with actual text
            let fetchLimit = count * 3 + 1
            print("[MessageWatcher] Calling API to get \(fetchLimit) messages for chat: \(chatId)")
            let messages = try await AgentTextClient.shared.getMessages(
                chatId: chatId,
                limit: fetchLimit,
                excludeOwnMessages: false
            )
            print("[MessageWatcher] API returned \(messages.count) messages")
            for (i, msg) in messages.enumerated() {
                print("[MessageWatcher] Message \(i): id=\(msg.id ?? "nil"), text=\(msg.text ?? "nil"), isFromMe=\(msg.isFromMe ?? false)")
            }
            
            // Skip the first message (the trigger message) and filter to messages with text
            let messagesWithText = messages.dropFirst().filter { $0.text != nil && !$0.text!.isEmpty }
            let messagesToProcess = Array(messagesWithText.prefix(count))
            print("[MessageWatcher] After filtering for text and taking \(count): \(messagesToProcess.count) messages")
            
            // Convert to ContextMessage
            let contextMessages: [ContextMessage] = messagesToProcess.compactMap { msg in
                guard let id = msg.id, let text = msg.text else {
                    return nil
                }
                
                // Parse the date string
                var messageDate = Date()
                if let dateString = msg.date {
                    let formatter = ISO8601DateFormatter()
                    if let parsed = formatter.date(from: dateString) {
                        messageDate = parsed
                    }
                }
                
                return ContextMessage(
                    id: id,
                    text: text,
                    isFromMe: msg.isFromMe ?? false,
                    sender: msg.sender,
                    date: messageDate
                )
            }
            
            // Reverse to show oldest first
            return contextMessages.reversed()
        } catch {
            print("[MessageWatcher] Error fetching context messages: \(error)")
            return []
        }
    }
    
    /// Extract words that come after @ symbols, with optional count
    /// e.g., "Hello @world 4" -> [("world", 4)]
    /// e.g., "@hello" -> [("hello", 0)]
    private func extractMentionsWithCount(from text: String) -> [(String, Int)] {
        var results: [(String, Int)] = []
        
        // Use regex to find @word followed by optional number
        // Pattern: @(\w+)(?:\s+(\d+))?
        let pattern = "@(\\w+)(?:\\s+(\\d+))?"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                if let mentionRange = Range(match.range(at: 1), in: text) {
                    let mention = String(text[mentionRange])
                    var count = 0
                    
                    // Check if there's a count following the mention
                    if match.numberOfRanges > 2,
                       let countRange = Range(match.range(at: 2), in: text),
                       let parsedCount = Int(text[countRange]) {
                        count = parsedCount
                    }
                    
                    results.append((mention, count))
                }
            }
        } catch {
            print("[MessageWatcher] Regex error: \(error)")
        }
        
        return results
    }
    
    /// Extract words that come after @ symbols (legacy, for compatibility)
    /// e.g., "Hello @world how are you @today" -> ["world", "today"]
    private func extractMentions(from text: String) -> [String] {
        var mentions: [String] = []
        
        // Use regex to find @word patterns
        let pattern = "@(\\w+)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                if let mentionRange = Range(match.range(at: 1), in: text) {
                    let mention = String(text[mentionRange])
                    mentions.append(mention)
                }
            }
        } catch {
            print("[MessageWatcher] Regex error: \(error)")
        }
        
        return mentions
    }
}
