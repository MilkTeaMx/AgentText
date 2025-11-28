import SwiftUI
import FirebaseAuth

struct MarketplaceView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var agents: [Agent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var testButtonLoading = false
    @State private var testResult: String?
    @State private var showTestResult = false
    @State private var isHoveredTest = false
    @State private var isHoveredRefresh = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with modern styling
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Marketplace")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("Discover and install AI agents")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }
                
                Spacer()

                // Test AgentText Button with glow
                Button(action: runSimpleTest) {
                    HStack(spacing: 8) {
                        if testButtonLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 12))
                        }
                        Text("Test AgentText")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(isHoveredTest ? 0.9 : 0.8))
                    )
                    .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.4).opacity(isHoveredTest ? 0.4 : 0.2), radius: isHoveredTest ? 15 : 8)
                }
                .buttonStyle(.plain)
                .disabled(testButtonLoading)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHoveredTest = hovering
                    }
                }

                // Refresh button
                GlowingIconButton(icon: "arrow.clockwise") {
                    refreshAgents()
                }
                .opacity(isLoading ? 0.5 : 1)
                .disabled(isLoading)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(Color(white: 0.04))
            
            GlowingDivider(opacity: 0.1)
            
            // Content
            if isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    Text("Loading agents...")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                }
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                    }
                    Text("Error loading agents")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                        .multilineTextAlignment(.center)
                    
                    GlowingButton("Retry", icon: "arrow.clockwise", style: .secondary) {
                        refreshAgents()
                    }
                    .frame(width: 140)
                }
                .padding(40)
                Spacer()
            } else if agents.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 80, height: 80)
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundColor(Color(white: 0.4))
                    }
                    Text("No agents available")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Be the first to publish an agent!")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(agents) { agent in
                            AgentCard(agent: agent, onInstall: {
                                installAgent(agent)
                            })
                        }
                    }
                    .padding(28)
                }
            }
        }
        .background(Color.black)
        .onAppear {
            refreshAgents()
        }
        .alert("Test Result", isPresented: $showTestResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(testResult ?? "")
        }
    }

    private func runSimpleTest() {
        testButtonLoading = true
        testResult = nil

        Task {
            do {
                // First check if server is running
                let isHealthy = try await AgentTextClient.shared.checkHealth()

                if !isHealthy {
                    await MainActor.run {
                        testButtonLoading = false
                        testResult = "❌ API Server Not Running\n\nPlease start the API server:\ncd AgentText/APIServer\nnode api-server.ts"
                        showTestResult = true
                    }
                    return
                }

                // Send test message
                let result = try await AgentTextClient.shared.sendMessage(
                    to: "+19255776728",
                    content: "Hello from AgentText! 🎉"
                )

                await MainActor.run {
                    testButtonLoading = false
                    if result.success {
                        testResult = "✅ Success!\n\nTest message sent to +1 9255776728"
                    } else {
                        testResult = "❌ Failed\n\n\(result.error ?? "Unknown error")"
                    }
                    showTestResult = true
                }
            } catch {
                await MainActor.run {
                    testButtonLoading = false
                    testResult = "❌ Error\n\n\(error.localizedDescription)"
                    showTestResult = true
                }
            }
        }
    }
    
    private func refreshAgents() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedAgents = try await FirebaseService.shared.fetchAllAgents()
                await MainActor.run {
                    agents = fetchedAgents
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func installAgent(_ agent: Agent) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await FirebaseService.shared.installAgent(agentId: agent.id, userId: userId)
                await MainActor.run {
                    // Refresh to update installation count
                    refreshAgents()
                }
            } catch {
                print("Error installing agent: \(error)")
            }
        }
    }
}

struct AgentCard: View {
    let agent: Agent
    let onInstall: () -> Void
    
    @State private var isHovered = false
    @State private var isHoveredInstall = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(agent.agentName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("by \(agent.developerName)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(white: 0.45))
                }
                
                Spacer()
                
                Button(action: onInstall) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 13))
                        Text("Install")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(isHoveredInstall ? 0.15 : 0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(isHoveredInstall ? 0.3 : 0.15), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.white.opacity(isHoveredInstall ? 0.15 : 0), radius: 10)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHoveredInstall = hovering
                    }
                }
            }
            
            Text(agent.description)
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.7))
                .lineLimit(3)
            
            // Stats row with modern styling
            HStack(spacing: 24) {
                StatBadge(icon: "arrow.down.circle", value: "\(agent.installations)", color: Color(white: 0.5))
                StatBadge(icon: "hand.thumbsup.fill", value: "\(agent.likes)", color: Color(red: 0.2, green: 0.8, blue: 0.4))
                StatBadge(icon: "hand.thumbsdown.fill", value: "\(agent.dislikes)", color: Color(red: 0.9, green: 0.3, blue: 0.3))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(isHovered ? 0.12 : 0.06), lineWidth: 1)
                )
        )
        .shadow(color: Color.white.opacity(isHovered ? 0.05 : 0), radius: 20)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(value)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(color)
    }
}

#Preview {
    MarketplaceView()
        .environmentObject(AuthManager.shared)
        .frame(width: 800, height: 600)
}

