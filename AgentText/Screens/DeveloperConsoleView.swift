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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Published Agents")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(white: 0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Text("Manage your published agents")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.5))
                    }
                    Spacer()
                    GlowingIconButton(icon: "arrow.clockwise") {
                        refreshAgents()
                    }
                    .opacity(isLoading ? 0.5 : 1)
                    .disabled(isLoading)
                }
                .padding(24)
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
                                .frame(width: 64, height: 64)
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 28))
                                .foregroundColor(.red)
                        }
                        Text("Error loading agents")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.5))
                        GlowingButton("Retry", icon: "arrow.clockwise", style: .secondary) {
                            refreshAgents()
                        }
                        .frame(width: 120)
                    }
                    Spacer()
                } else if developerAgents.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 64, height: 64)
                            Image(systemName: "tray")
                                .font(.system(size: 28))
                                .foregroundColor(Color(white: 0.4))
                        }
                        Text("No agents published")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Create your first agent using the form")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.5))
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
                        .padding(24)
                    }
                }
            }
            .frame(minWidth: 400)
            .background(Color.black)
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
    @State private var isHovered = false
    @State private var isHoveredDelete = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(agent.agentName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let createdAt = agent.createdAt {
                        Text("Created \(formatDate(createdAt))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(white: 0.45))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(isHoveredDelete ? .red : Color(white: 0.5))
                        .font(.system(size: 14))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(isHoveredDelete ? Color.red.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHoveredDelete = hovering
                    }
                }
            }
            
            Text(agent.description)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.6))
                .lineLimit(2)
            
            HStack(spacing: 20) {
                StatBadge(icon: "arrow.down.circle", value: "\(agent.installations)", color: Color(white: 0.5))
                StatBadge(icon: "hand.thumbsup.fill", value: "\(agent.likes)", color: Color(red: 0.2, green: 0.8, blue: 0.4))
                StatBadge(icon: "hand.thumbsdown.fill", value: "\(agent.dislikes)", color: Color(red: 0.9, green: 0.3, blue: 0.3))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(isHovered ? 0.12 : 0.06), lineWidth: 1)
                )
        )
        .shadow(color: Color.white.opacity(isHovered ? 0.05 : 0), radius: 15)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
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

