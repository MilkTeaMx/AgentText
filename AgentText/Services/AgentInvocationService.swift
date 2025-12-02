//
//  AgentInvocationService.swift
//  AgentText
//
//  Service for invoking agents when mentioned in messages
//

import Foundation
import FirebaseAuth

/// Represents the payload sent to an agent's API
struct AgentInvocationPayload: Codable {
    let messages: [MessagePayload]
    let count: Int
    let integrations: [String: String]? // Integration name -> API key
}

/// Represents a message in the payload
struct MessagePayload: Codable {
    let text: String
    let isFromMe: Bool
    let sender: String?
    let date: String
}

/// Represents the expected response from an agent's API
struct AgentResponse: Codable {
    let message: String
}

/// Service responsible for invoking agents via their API endpoints
class AgentInvocationService {
    static let shared = AgentInvocationService()

    private init() {}

    /// Invoke an agent by its name with the given context messages
    /// - Parameters:
    ///   - agentName: The name of the agent to invoke (without @)
    ///   - contextMessages: Array of messages to send to the agent
    ///   - count: Number of messages requested
    ///   - chatId: The chat ID where the mention occurred (optional, for sending response)
    func invokeAgent(agentName: String, contextMessages: [ContextMessage], count: Int, chatId: String? = nil) async {
        print("[AgentInvocation] Invoking agent: \(agentName) with \(contextMessages.count) messages, chatId: \(chatId ?? "nil")")

        // Get current user ID
        guard let userId = Auth.auth().currentUser?.uid else {
            print("[AgentInvocation] Error: No authenticated user")
            return
        }

        // Fetch the agent from Firebase
        guard let agent = await fetchAgent(byName: agentName) else {
            print("[AgentInvocation] Error: Agent '\(agentName)' not found")
            return
        }

        print("[AgentInvocation] Found agent: \(agent.agentName)")
        print("[AgentInvocation] API URL: \(agent.apiUrl)")
        print("[AgentInvocation] Integrations: \(agent.integrations)")

        // Fetch user's integration keys
        let integrationKeys = await fetchUserIntegrationKeys(userId: userId, requiredIntegrations: agent.integrations)
        print("[AgentInvocation] Integration keys fetched: \(integrationKeys.keys)")

        // Prepare the payload
        let messages = contextMessages.map { message in
            let formatter = ISO8601DateFormatter()
            return MessagePayload(
                text: message.text,
                isFromMe: message.isFromMe,
                sender: message.sender,
                date: formatter.string(from: message.date)
            )
        }

        let payload = AgentInvocationPayload(
            messages: messages,
            count: count,
            integrations: integrationKeys.isEmpty ? nil : integrationKeys
        )

        // Call the agent's API and get response
        await callAgentAPI(url: agent.apiUrl, payload: payload, agentName: agent.agentName, chatId: chatId)
    }

    /// Fetch an agent by its name from Firebase
    private func fetchAgent(byName name: String) async -> Agent? {
        do {
            // Sanitize the name to match the document ID format
            let sanitizedName = name
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "\\", with: "_")
                .replacingOccurrences(of: ".", with: "_")

            let agents = try await FirebaseService.shared.fetchAllAgents()

            // Try to find by sanitized name first (document ID)
            if let agent = agents.first(where: { $0.id.lowercased() == sanitizedName.lowercased() }) {
                return agent
            }

            // Fall back to searching by agent name field
            if let agent = agents.first(where: { $0.agentName.lowercased() == name.lowercased() }) {
                return agent
            }

            // Try partial match
            if let agent = agents.first(where: {
                $0.agentName.lowercased().contains(name.lowercased()) ||
                name.lowercased().contains($0.agentName.lowercased())
            }) {
                print("[AgentInvocation] Found partial match: \(agent.agentName)")
                return agent
            }

            return nil
        } catch {
            print("[AgentInvocation] Error fetching agents: \(error)")
            return nil
        }
    }

    /// Fetch the user's integration API keys for the required integrations
    private func fetchUserIntegrationKeys(userId: String, requiredIntegrations: [String]) async -> [String: String] {
        guard !requiredIntegrations.isEmpty else {
            return [:]
        }

        do {
            let userData = try await FirebaseService.shared.getUserData(uid: userId)
            let allKeys = userData?["integrationKeys"] as? [String: String] ?? [:]

            // Filter to only the required integrations
            var result: [String: String] = [:]
            for integration in requiredIntegrations {
                if let key = allKeys[integration] {
                    result[integration] = key
                } else {
                    print("[AgentInvocation] Warning: Missing API key for integration: \(integration)")
                }
            }

            return result
        } catch {
            print("[AgentInvocation] Error fetching user integration keys: \(error)")
            return [:]
        }
    }

    /// Call the agent's API endpoint with the payload
    private func callAgentAPI(url: String, payload: AgentInvocationPayload, agentName: String, chatId: String?) async {
        guard let apiURL = URL(string: url) else {
            print("[AgentInvocation] Error: Invalid API URL: \(url)")
            return
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            request.httpBody = try encoder.encode(payload)

            // Log the request
            if let jsonString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
                print("[AgentInvocation] Calling API for agent '\(agentName)':")
                print("[AgentInvocation] URL: \(url)")
                print("[AgentInvocation] Payload:")
                print(jsonString)
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("[AgentInvocation] Response status: \(httpResponse.statusCode)")

                if let responseString = String(data: data, encoding: .utf8) {
                    print("[AgentInvocation] Response body: \(responseString)")
                }

                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    print("[AgentInvocation] ✅ Agent '\(agentName)' invoked successfully")

                    // Parse the response
                    do {
                        let decoder = JSONDecoder()
                        let agentResponse = try decoder.decode(AgentResponse.self, from: data)
                        print("[AgentInvocation] Agent response message: \(agentResponse.message)")

                        // Send the response message back to the chat
                        if let chatId = chatId {
                            await sendResponseToChat(chatId: chatId, message: agentResponse.message)
                        } else {
                            print("[AgentInvocation] No chatId provided, skipping message send")
                        }
                    } catch {
                        print("[AgentInvocation] Error parsing agent response: \(error)")
                        // Try to extract message from raw JSON if structured parsing fails
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = json["message"] as? String,
                           let chatId = chatId {
                            print("[AgentInvocation] Extracted message from raw JSON: \(message)")
                            await sendResponseToChat(chatId: chatId, message: message)
                        }
                    }
                } else {
                    print("[AgentInvocation] ⚠️ Agent '\(agentName)' returned status \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("[AgentInvocation] Error calling agent API: \(error)")
        }
    }

    /// Send the agent's response message to the chat
    private func sendResponseToChat(chatId: String, message: String) async {
        print("[AgentInvocation] Sending response to chat \(chatId): \(message)")

        do {
            let result = try await AgentTextClient.shared.sendMessage(to: chatId, content: message)
            if result.success {
                print("[AgentInvocation] ✅ Response sent successfully")
            } else {
                print("[AgentInvocation] ❌ Failed to send response: \(result.error ?? "Unknown error")")
            }
        } catch {
            print("[AgentInvocation] Error sending response: \(error)")
        }
    }
}
