import SwiftUI
import FirebaseAuth

struct MarketplaceView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var agents: [Agent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Marketplace")
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
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No agents available")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Be the first to publish an agent!")
                        .font(.caption)
                        .foregroundColor(.gray)
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
                
                Button(action: onInstall) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Install")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
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
                
                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 12))
                    Text("\(agent.likes)")
                        .font(.system(size: 12))
                }
                .foregroundColor(.green)
                
                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsdown")
                        .font(.system(size: 12))
                    Text("\(agent.dislikes)")
                        .font(.system(size: 12))
                }
                .foregroundColor(.red)
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
    MarketplaceView()
        .environmentObject(AuthManager.shared)
        .frame(width: 800, height: 600)
}

