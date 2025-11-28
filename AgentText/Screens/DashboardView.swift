import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedSection: DashboardSection = .marketplace
    
    enum DashboardSection: String, CaseIterable {
        case marketplace = "Marketplace"
        case installedAgents = "Installed Agents"
        case developerConsole = "Developer Console"
        
        var icon: String {
            switch self {
            case .marketplace: return "square.grid.2x2"
            case .installedAgents: return "app.badge"
            case .developerConsole: return "wrench.and.screwdriver"
            }
        }
    }
    
    var body: some View {
        HSplitView {
            // Left Sidebar
            SidebarView(selectedSection: $selectedSection)
                .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)
            
            // Main Content Area
            Group {
                switch selectedSection {
                case .marketplace:
                    MarketplaceView()
                        .environmentObject(authManager)
                case .installedAgents:
                    InstalledAgentsView()
                        .environmentObject(authManager)
                case .developerConsole:
                    DeveloperConsoleView()
                        .environmentObject(authManager)
                }
            }
            .frame(minWidth: 600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct SidebarView: View {
    @Binding var selectedSection: DashboardView.DashboardSection
    @State private var logoGlow: CGFloat = 0.3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo/Header with glow
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    LogoView(size: 36)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AgentText")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(white: 0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Text("Marketplace")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(white: 0.45))
                            .tracking(0.5)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 28)
            
            // Glowing divider
            GlowingDivider(opacity: 0.15)
                .padding(.horizontal, 16)
            
            // Navigation Items
            VStack(alignment: .leading, spacing: 6) {
                ForEach(DashboardView.DashboardSection.allCases, id: \.self) { section in
                    SidebarButton(
                        title: section.rawValue,
                        icon: section.icon,
                        isSelected: selectedSection == section
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSection = section
                        }
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 12)
            
            Spacer()
            
            // Version info
            Text("v1.0.0")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(white: 0.3))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.04))
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 22)
                    .foregroundColor(isSelected ? .white : Color(white: isHovered ? 0.7 : 0.5))
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : Color(white: isHovered ? 0.7 : 0.5))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.white.opacity(0.1) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.white.opacity(0.15) : Color.clear, lineWidth: 1)
                    )
            )
            .shadow(color: isSelected ? Color.white.opacity(0.08) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
        .frame(width: 1000, height: 700)
}

