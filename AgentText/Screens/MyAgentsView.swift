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
            HStack {
                Text("Installed Agents")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: refreshAgents) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(24)
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            
            Divider()
            
            // Content
            if isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text("Error loading agents")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Retry") {
                        refreshAgents()
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            } else if agents.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No installed agents")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Browse the marketplace to install agents")
                        .font(.caption)
                        .foregroundColor(.gray)
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
                    .padding(24)
                }
            }
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(agent.agentName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("by \(agent.developerName)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Installed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            
            Text(agent.description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
            
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 12))
                    Text("\(agent.installations)")
                        .font(.system(size: 12))
                }
                .foregroundColor(.gray)
                
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 12))
                        Text("\(agent.likes)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(isLiked ? .green : .gray)
                }
                .buttonStyle(.plain)
                
                Button(action: onDislike) {
                    HStack(spacing: 6) {
                        Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 12))
                        Text("\(agent.dislikes)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(isDisliked ? .red : .gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
        )
    }
}

#Preview {
    InstalledAgentsView()
        .environmentObject(AuthManager.shared)
        .frame(width: 800, height: 600)
}

