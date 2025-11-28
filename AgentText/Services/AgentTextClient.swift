//
//  AgentTextClient.swift
//  AgentText
//
//  Native Swift client for AgentText API Server
//  No Python dependencies - communicates directly with Node.js API
//

import Foundation

// MARK: - Error Types

enum AgentTextError: Error, LocalizedError {
    case invalidURL
    case serverNotRunning
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .serverNotRunning:
            return "AgentText API server is not running on http://localhost:3000"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Response Models

struct APIResponse<T: Codable>: Codable {
    let data: T?
    let error: String?
    let message: String?
}

struct SendMessageResponse: Codable {
    let sentAt: String?
    let message: Message?
    let error: String?
    
    /// Returns true if the message was sent successfully (has a sentAt timestamp)
    var success: Bool {
        return sentAt != nil
    }
}

struct UnreadMessagesResponse: Codable {
    let total: Int
    let senderCount: Int
    let groups: [UnreadGroup]?

    struct UnreadGroup: Codable {
        let sender: String
        let count: Int
        let lastMessage: String?
    }
}

struct MessagesResponse: Codable {
    let messages: [Message]
    let total: Int
    let unreadCount: Int
}

struct Message: Codable {
    let id: String?
    let guid: String?
    let text: String?
    let sender: String?
    let senderName: String?
    let date: String?
    let isFromMe: Bool?
    let isRead: Bool?
    let chatId: String?
    let isGroupChat: Bool?
    let service: String?
    let attachments: [MessageAttachment]?
}

struct MessageAttachment: Codable {
    let id: String?
    let filename: String?
    let mimeType: String?
    let path: String?
    let size: Int?
    let isImage: Bool?
    let createdAt: String?
}

struct Chat: Codable {
    let chatId: String
    let displayName: String?
    let isGroup: Bool?
    let participants: [String]?
    let lastMessageAt: String?
    let unreadCount: Int?
}

struct WatcherStatus: Codable {
    let active: Bool
    let connections: Int
    let timestamp: String
}

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
}

// MARK: - AgentText Client

class AgentTextClient {
    static let shared = AgentTextClient()

    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "http://localhost:3000") {
        self.baseURL = baseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Health Check

    /// Check if the API server is running and healthy
    func checkHealth() async throws -> Bool {
        let url = try makeURL(path: "/health")

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }

            if httpResponse.statusCode == 200 {
                let healthResponse = try? JSONDecoder().decode(HealthResponse.self, from: data)
                return healthResponse?.status == "ok"
            }

            return false
        } catch {
            return false
        }
    }

    // MARK: - Send Messages

    /// Send a text message to a recipient
    /// - Parameters:
    ///   - to: Phone number (e.g., "+1234567890") or email address
    ///   - content: Message text to send
    func sendMessage(to: String, content: String) async throws -> SendMessageResponse {
        let url = try makeURL(path: "/send")

        let body: [String: Any] = [
            "to": to,
            "content": content
        ]

        return try await post(url: url, body: body)
    }

    /// Send a file to a recipient
    /// - Parameters:
    ///   - to: Phone number or email
    ///   - filePath: Absolute path to the file
    ///   - text: Optional message text to accompany the file
    func sendFile(to: String, filePath: String, text: String? = nil) async throws -> SendMessageResponse {
        let url = try makeURL(path: "/send/file")

        var body: [String: Any] = [
            "to": to,
            "filePath": filePath
        ]

        if let text = text {
            body["text"] = text
        }

        return try await post(url: url, body: body)
    }

    /// Send multiple files to a recipient
    /// - Parameters:
    ///   - to: Phone number or email
    ///   - filePaths: Array of absolute file paths
    ///   - text: Optional message text
    func sendFiles(to: String, filePaths: [String], text: String? = nil) async throws -> SendMessageResponse {
        let url = try makeURL(path: "/send/files")

        var body: [String: Any] = [
            "to": to,
            "filePaths": filePaths
        ]

        if let text = text {
            body["text"] = text
        }

        return try await post(url: url, body: body)
    }

    /// Send multiple messages in one request
    /// - Parameter messages: Array of message objects with "to" and "content" fields
    func sendBatch(messages: [[String: Any]]) async throws -> [String: Any] {
        let url = try makeURL(path: "/send/batch")

        let body: [String: Any] = [
            "messages": messages
        ]

        return try await post(url: url, body: body)
    }

    // MARK: - Get Messages

    /// Query messages with optional filters
    /// - Parameters:
    ///   - sender: Filter by sender phone/email
    ///   - chatId: Filter by chat ID (for getting messages from specific conversation)
    ///   - unreadOnly: Only return unread messages
    ///   - limit: Maximum number of messages to return
    ///   - since: Only messages since this date
    ///   - search: Search message text
    ///   - hasAttachments: Only messages with attachments
    ///   - excludeOwnMessages: Exclude messages sent by current user (default: true)
    func getMessages(
        sender: String? = nil,
        chatId: String? = nil,
        unreadOnly: Bool = false,
        limit: Int? = nil,
        since: Date? = nil,
        search: String? = nil,
        hasAttachments: Bool? = nil,
        excludeOwnMessages: Bool = true
    ) async throws -> [Message] {
        var components = URLComponents(string: baseURL + "/messages")!
        var queryItems: [URLQueryItem] = []

        if let sender = sender {
            queryItems.append(URLQueryItem(name: "sender", value: sender))
        }

        if let chatId = chatId {
            queryItems.append(URLQueryItem(name: "chatId", value: chatId))
        }

        if unreadOnly {
            queryItems.append(URLQueryItem(name: "unreadOnly", value: "true"))
        }

        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        if let since = since {
            let formatter = ISO8601DateFormatter()
            queryItems.append(URLQueryItem(name: "since", value: formatter.string(from: since)))
        }

        if let search = search {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        if let hasAttachments = hasAttachments {
            queryItems.append(URLQueryItem(name: "hasAttachments", value: String(hasAttachments)))
        }

        if !excludeOwnMessages {
            queryItems.append(URLQueryItem(name: "excludeOwnMessages", value: "false"))
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw AgentTextError.invalidURL
        }

        print("[AgentTextClient] Fetching messages from URL: \(url.absoluteString)")
        let response: MessagesResponse = try await get(url: url)
        print("[AgentTextClient] Got \(response.messages.count) messages")
        return response.messages
    }

    /// Get unread messages grouped by sender
    func getUnreadMessages() async throws -> UnreadMessagesResponse {
        let url = try makeURL(path: "/messages/unread")
        return try await get(url: url)
    }

    // MARK: - Chats

    /// List chats with optional filters
    /// - Parameters:
    ///   - type: Filter by chat type ("group" or "direct")
    ///   - hasUnread: Only chats with unread messages
    ///   - sortBy: Sort order ("recent" or "name")
    ///   - search: Search chat names
    ///   - limit: Maximum number of chats
    func listChats(
        type: String? = nil,
        hasUnread: Bool? = nil,
        sortBy: String? = nil,
        search: String? = nil,
        limit: Int? = nil
    ) async throws -> [Chat] {
        var components = URLComponents(string: baseURL + "/chats")!
        var queryItems: [URLQueryItem] = []

        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }

        if let hasUnread = hasUnread {
            queryItems.append(URLQueryItem(name: "hasUnread", value: String(hasUnread)))
        }

        if let sortBy = sortBy {
            queryItems.append(URLQueryItem(name: "sortBy", value: sortBy))
        }

        if let search = search {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw AgentTextError.invalidURL
        }

        return try await get(url: url)
    }

    // MARK: - Watcher

    /// Start the message watcher
    func startWatcher() async throws -> [String: Any] {
        let url = try makeURL(path: "/watcher/start")
        return try await post(url: url, body: [:])
    }

    /// Stop the message watcher
    func stopWatcher() async throws -> [String: Any] {
        let url = try makeURL(path: "/watcher/stop")
        return try await post(url: url, body: [:])
    }

    /// Get watcher status
    func getWatcherStatus() async throws -> WatcherStatus {
        let url = try makeURL(path: "/watcher/status")
        return try await get(url: url)
    }

    // MARK: - Utility

    /// Send a test message (to the default test number in API server)
    func sendTestMessage() async throws -> [String: Any] {
        let url = try makeURL(path: "/test")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentTextError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentTextError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AgentTextError.invalidResponse
        }

        return json
    }

    // MARK: - Private Helpers

    private func makeURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw AgentTextError.invalidURL
        }
        return url
    }

    private func get<T: Codable>(url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AgentTextError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorData = try? JSONDecoder().decode([String: String].self, from: data)
                let errorMessage = errorData?["message"] ?? errorData?["error"] ?? "Unknown error"
                throw AgentTextError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            let decoder = JSONDecoder()
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("[AgentTextClient] JSON decode error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[AgentTextClient] Raw JSON: \(jsonString.prefix(500))")
                }
                throw error
            }
        } catch let error as AgentTextError {
            throw error
        } catch {
            throw AgentTextError.networkError(error)
        }
    }

    private func post<T: Codable>(url: URL, body: [String: Any]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AgentTextError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorData = try? JSONDecoder().decode([String: String].self, from: data)
                let errorMessage = errorData?["message"] ?? errorData?["error"] ?? "Unknown error"
                throw AgentTextError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let error as AgentTextError {
            throw error
        } catch {
            throw AgentTextError.networkError(error)
        }
    }

    private func post(url: URL, body: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AgentTextError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorData = try? JSONDecoder().decode([String: String].self, from: data)
                let errorMessage = errorData?["message"] ?? errorData?["error"] ?? "Unknown error"
                throw AgentTextError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw AgentTextError.invalidResponse
            }

            return json
        } catch let error as AgentTextError {
            throw error
        } catch {
            throw AgentTextError.networkError(error)
        }
    }
}
