import SwiftUI
import FirebaseAuth

struct InstalledAgentsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var agents: [Agent] = []
    @State private var agentReactions: [String: (isLiked: Bool, isDisliked: Bool)] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Installed Agents")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("Manage your installed AI agents")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }
                Spacer()
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
                        Image(systemName: "app.badge")
                            .font(.system(size: 32))
                            .foregroundColor(Color(white: 0.4))
                    }
                    Text("No installed agents")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Browse the marketplace to install agents")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(agents) { agent in
                            InstalledAgentCard(
                                agent: agent,
                                isLiked: agentReactions[agent.id]?.isLiked ?? false,
                                isDisliked: agentReactions[agent.id]?.isDisliked ?? false,
                                onLike: {
                                    toggleLike(agent)
                                },
                                onDislike: {
                                    toggleDislike(agent)
                                }
                            )
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
    }
    
    private func refreshAgents() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not authenticated"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedAgents = try await FirebaseService.shared.fetchInstalledAgents(userId: userId)
                
                // Fetch reactions for all agents
                var reactions: [String: (isLiked: Bool, isDisliked: Bool)] = [:]
                for agent in fetchedAgents {
                    let reaction = try await FirebaseService.shared.getUserReaction(agentId: agent.id, userId: userId)
                    reactions[agent.id] = reaction
                }
                
                await MainActor.run {
                    agents = fetchedAgents
                    agentReactions = reactions
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
    
    private func toggleLike(_ agent: Agent) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                _ = try await FirebaseService.shared.toggleLikeAgent(agentId: agent.id, userId: userId)
                // Refresh to get updated counts and reactions
                await MainActor.run {
                    refreshAgents()
                }
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }
    
    private func toggleDislike(_ agent: Agent) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                _ = try await FirebaseService.shared.toggleDislikeAgent(agentId: agent.id, userId: userId)
                // Refresh to get updated counts and reactions
                await MainActor.run {
                    refreshAgents()
                }
            } catch {
                print("Error toggling dislike: \(error)")
            }
        }
    }
}

struct InstalledAgentCard: View {
    let agent: Agent
    let isLiked: Bool
    let isDisliked: Bool
    let onLike: () -> Void
    let onDislike: () -> Void
    
    @State private var isHovered = false
    @State private var isHoveredLike = false
    @State private var isHoveredDislike = false
    
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
                
                // Installed badge with glow
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    Text("Installed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15))
                )
            }
            
            Text(agent.description)
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.7))
                .lineLimit(3)
            
            // Stats and reaction buttons
            HStack(spacing: 24) {
                StatBadge(icon: "arrow.down.circle", value: "\(agent.installations)", color: Color(white: 0.5))
                
                // Like button
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 13))
                        Text("\(agent.likes)")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(isLiked ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color(white: isHoveredLike ? 0.7 : 0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isLiked ? Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15) : Color.white.opacity(isHoveredLike ? 0.08 : 0))
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHoveredLike = hovering
                    }
                }
                
                // Dislike button
                Button(action: onDislike) {
                    HStack(spacing: 6) {
                        Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 13))
                        Text("\(agent.dislikes)")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(isDisliked ? Color(red: 0.9, green: 0.3, blue: 0.3) : Color(white: isHoveredDislike ? 0.7 : 0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isDisliked ? Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.15) : Color.white.opacity(isHoveredDislike ? 0.08 : 0))
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHoveredDislike = hovering
                    }
                }
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

#Preview {
    InstalledAgentsView()
        .environmentObject(AuthManager.shared)
        .frame(width: 800, height: 600)
}

