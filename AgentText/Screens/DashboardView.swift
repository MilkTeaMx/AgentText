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
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 250)
            
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
    }
}

struct SidebarView: View {
    @Binding var selectedSection: DashboardView.DashboardSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo/Header
            VStack(alignment: .leading, spacing: 8) {
                Text("AgentText")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("Marketplace")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Navigation Items
            VStack(alignment: .leading, spacing: 4) {
                ForEach(DashboardView.DashboardSection.allCases, id: \.self) { section in
                    SidebarButton(
                        title: section.rawValue,
                        icon: section.icon,
                        isSelected: selectedSection == section
                    ) {
                        selectedSection = section
                    }
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 14))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
        .frame(width: 1000, height: 700)
}

