import SwiftUI
import FirebaseAuth

struct DeveloperConsoleView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var developerAgents: [Agent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        HSplitView {
            // Left: Upload Form
            DeveloperUploadForm(onAgentCreated: {
                refreshAgents()
            })
            .environmentObject(authManager)
            .frame(minWidth: 400)
            
            // Right: Developer's Agents List
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("My Published Agents")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: refreshAgents) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
                .padding(20)
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
                            .font(.system(size: 32))
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
                } else if developerAgents.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                        Text("No agents published")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Create your first agent using the form on the left")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(developerAgents) { agent in
                                DeveloperAgentCard(agent: agent, onDelete: {
                                    deleteAgent(agent)
                                })
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .frame(minWidth: 400)
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
                let fetchedAgents = try await FirebaseService.shared.fetchDeveloperAgents(developerId: userId)
                await MainActor.run {
                    developerAgents = fetchedAgents
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
    
    private func deleteAgent(_ agent: Agent) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated")
            return
        }
        
        Task {
            do {
                try await FirebaseService.shared.deleteAgent(agentId: agent.id, developerId: userId)
                await MainActor.run {
                    refreshAgents()
                }
            } catch {
                print("Error deleting agent: \(error)")
                // TODO: Show error to user
            }
        }
    }
}

struct DeveloperAgentCard: View {
    let agent: Agent
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(agent.agentName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let createdAt = agent.createdAt {
                        Text("Created \(formatDate(createdAt))")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
            
            Text(agent.description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 11))
                    Text("\(agent.installations)")
                        .font(.system(size: 11))
                }
                .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 11))
                    Text("\(agent.likes)")
                        .font(.system(size: 11))
                }
                .foregroundColor(.green)
                
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsdown")
                        .font(.system(size: 11))
                    Text("\(agent.dislikes)")
                        .font(.system(size: 11))
                }
                .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
        )
        .alert("Delete Agent", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(agent.agentName)'? This action cannot be undone.")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    DeveloperConsoleView()
        .environmentObject(AuthManager.shared)
        .frame(width: 1000, height: 700)
}

