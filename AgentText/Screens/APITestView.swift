//
//  APITestView.swift
//  AgentText
//
//  Created by Nirav Jaiswal on 11/27/25.
//


//
//  APITestView.swift
//  AgentText
//
//  Test view for AgentText API integration
//

import SwiftUI

struct APITestView: View {
    @EnvironmentObject var apiServerManager: APIServerManager
    @State private var recipient = ""
    @State private var message = ""
    @State private var statusMessage = ""
    @State private var isLoading = false
    @State private var showServerLogs = false
    @State private var isHoveredSend = false
    @State private var isHoveredServerToggle = false
    @State private var isHoveredLogs = false
    @State private var isHoveredUnread = false
    @State private var isHoveredHealth = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                serverStatusCard
                GlowingDivider()
                sendMessageForm
                statusMessageView
                quickActionsSection
                Spacer()
            }
            .padding(28)
        }
        .background(Color.black)
        .sheet(isPresented: $showServerLogs) {
            ServerLogsView()
                .environmentObject(apiServerManager)
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("API Test Console")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(white: 0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text("Test your AgentText API integration")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }
    
    // MARK: - Server Status Card
    
    @ViewBuilder
    private var serverStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                serverStatusIndicator
                Spacer()
                serverControlButtons
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    @ViewBuilder
    private var serverStatusIndicator: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(apiServerManager.isRunning ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color(red: 1.0, green: 0.3, blue: 0.3))
                .frame(width: 10, height: 10)
                .shadow(color: apiServerManager.isRunning ? Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.6) : Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.6), radius: 6)

            Text(apiServerManager.isRunning ? "API Server Running" : "API Server Stopped")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(white: 0.7))
        }
    }
    
    @ViewBuilder
    private var serverControlButtons: some View {
        HStack(spacing: 12) {
            Button(action: toggleServer) {
                Text(apiServerManager.isRunning ? "Stop" : "Start")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(smallButtonBackground(isHovered: isHoveredServerToggle))
                    .shadow(color: isHoveredServerToggle ? Color.white.opacity(0.1) : .clear, radius: 10)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoveredServerToggle = hovering
                }
            }

            Button(action: { showServerLogs.toggle() }) {
                Image(systemName: "doc.text")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(smallButtonBackground(isHovered: isHoveredLogs))
                    .shadow(color: isHoveredLogs ? Color.white.opacity(0.1) : .clear, radius: 10)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoveredLogs = hovering
                }
            }
        }
    }
    
    // MARK: - Send Message Form
    
    @ViewBuilder
    private var sendMessageForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("SEND MESSAGE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.45))
                .tracking(1.2)

            VStack(spacing: 16) {
                formField(label: "RECIPIENT", placeholder: "Phone or email", text: $recipient)
                formField(label: "MESSAGE", placeholder: "Your message", text: $message)
            }

            sendButton
        }
        .padding(20)
        .background(cardBackground)
    }
    
    @ViewBuilder
    private func formField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(white: 0.4))
                .tracking(1)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(textFieldBackground)
        }
    }
    
    @ViewBuilder
    private var sendButton: some View {
        Button(action: sendMessageDirect) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 12))
                    Text("Send Message")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(sendButtonBackground)
            .shadow(color: canSend && isHoveredSend ? Color.white.opacity(0.15) : .clear, radius: 15)
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .opacity(canSend ? 1.0 : 0.5)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHoveredSend = hovering
            }
        }
    }
    
    // MARK: - Status Message
    
    @ViewBuilder
    private var statusMessageView: some View {
        if !statusMessage.isEmpty {
            HStack(spacing: 10) {
                statusIcon
                Text(statusMessage.replacingOccurrences(of: "✅ ", with: "").replacingOccurrences(of: "❌ ", with: ""))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(white: 0.8))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(cardBackground)
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        if statusMessage.contains("✅") || statusMessage.contains("success") {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
        } else if statusMessage.contains("❌") || statusMessage.contains("Error") {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
        } else {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color(white: 0.6))
        }
    }
    
    // MARK: - Quick Actions
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QUICK ACTIONS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.45))
                .tracking(1.2)

            HStack(spacing: 12) {
                quickActionButton(
                    icon: "envelope.badge",
                    title: "Get Unread",
                    action: getUnreadMessages,
                    isHovered: isHoveredUnread,
                    isDisabled: !apiServerManager.isRunning || isLoading,
                    onHover: { isHoveredUnread = $0 }
                )
                
                quickActionButton(
                    icon: "heart.fill",
                    title: "Health Check",
                    action: checkServerHealth,
                    isHovered: isHoveredHealth,
                    isDisabled: isLoading,
                    onHover: { isHoveredHealth = $0 }
                )
            }
        }
        .padding(20)
        .background(cardBackground)
    }
    
    @ViewBuilder
    private func quickActionButton(icon: String, title: String, action: @escaping () -> Void, isHovered: Bool, isDisabled: Bool, onHover: @escaping (Bool) -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(quickActionBackground(isHovered: isHovered))
            .shadow(color: isHovered ? Color.white.opacity(0.1) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                onHover(hovering)
            }
        }
    }
    
    // MARK: - Background Helpers
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
    
    private func smallButtonBackground(isHovered: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(isHovered ? 0.12 : 0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(isHovered ? 0.25 : 0.12), lineWidth: 1)
            )
    }
    
    private var sendButtonBackground: some View {
        let fillOpacity = canSend ? (isHoveredSend ? 0.12 : 0.06) : 0.02
        let strokeOpacity = canSend ? (isHoveredSend ? 0.3 : 0.15) : 0.05
        return RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(fillOpacity))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
    }
    
    private func quickActionBackground(isHovered: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(isHovered ? 0.1 : 0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 1)
            )
    }
    
    // MARK: - Computed Properties
    
    private var canSend: Bool {
        apiServerManager.isRunning && !recipient.isEmpty && !message.isEmpty && !isLoading
    }
    
    // MARK: - Actions
    
    private func toggleServer() {
        Task {
            do {
                if apiServerManager.isRunning {
                    apiServerManager.stopServer()
                } else {
                    try await apiServerManager.startServer()
                }
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func sendMessageDirect() {
        isLoading = true
        statusMessage = "Sending message..."

        Task {
            do {
                let result = try await AgentTextClient.shared.sendMessage(
                    to: recipient,
                    content: message
                )

                await MainActor.run {
                    isLoading = false
                    if result.success == true {
                        statusMessage = "✅ Message sent successfully!"
                        message = ""
                    } else {
                        statusMessage = "❌ Error: \(result.error ?? "Unknown error")"
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "❌ Error: \(error.localizedDescription)"
                }
            }
        }
    }

    // Removed Python-based send; using direct API client instead.

    private func getUnreadMessages() {
        isLoading = true
        statusMessage = "Fetching unread messages..."

        Task {
            do {
                let result = try await AgentTextClient.shared.getUnreadMessages()

                await MainActor.run {
                    isLoading = false
                    statusMessage = "✅ Found \(result.total) unread messages from \(result.senderCount) senders"
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func checkServerHealth() {
        isLoading = true
        statusMessage = "Checking server health..."

        Task {
            do {
                let isHealthy = try await AgentTextClient.shared.checkHealth()

                await MainActor.run {
                    isLoading = false
                    if isHealthy {
                        statusMessage = "✅ Server is healthy!"
                    } else {
                        statusMessage = "❌ Server is not responding. Make sure it's running."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Server Logs View

struct ServerLogsView: View {
    @EnvironmentObject var apiServerManager: APIServerManager
    @Environment(\.dismiss) var dismiss
    @State private var isHoveredClear = false
    @State private var isHoveredClose = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server Logs")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("\(apiServerManager.serverOutput.count) entries")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    Button(action: { apiServerManager.clearOutput() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            Text("Clear")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(isHoveredClear ? 0.1 : 0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(isHoveredClear ? 0.2 : 0.1), lineWidth: 1)
                                )
                        )
                        .shadow(color: isHoveredClear ? Color.white.opacity(0.1) : .clear, radius: 8)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHoveredClear = hovering
                        }
                    }
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(isHoveredClose ? 0.12 : 0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(isHoveredClose ? 0.25 : 0.12), lineWidth: 1)
                                    )
                            )
                            .shadow(color: isHoveredClose ? Color.white.opacity(0.1) : .clear, radius: 8)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHoveredClose = hovering
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(white: 0.04))
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Logs content
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(apiServerManager.serverOutput.enumerated()), id: \.offset) { index, log in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color(white: 0.35))
                                    .frame(width: 36, alignment: .trailing)
                                
                                Text(log)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(log.contains("ERROR") ? Color(red: 1.0, green: 0.4, blue: 0.4) : Color(white: 0.75))
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(index % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)
                            .id(index)
                        }
                    }
                    .onChange(of: apiServerManager.serverOutput.count) { _ in
                        if let lastIndex = apiServerManager.serverOutput.indices.last {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black)
        .frame(minWidth: 700, minHeight: 450)
    }
}

#Preview {
    APITestView()
        .environmentObject(APIServerManager())
}
