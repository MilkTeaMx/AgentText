import SwiftUI
import AppKit

struct PermissionView: View {
    @State private var isHoveredButton = false
    
    var body: some View {
        ZStack {
            // Animated dark background
            AnimatedBackground()
            
            // Main card with luminescent outline
            LuminescentCard {
                VStack(spacing: 40) {
                    // Logo with enhanced glow
                    LogoView(size: 88)
                    
                    VStack(spacing: 16) {
                        Text("AgentText Setup")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(white: 0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("To enable message processing, please grant Full Disk Access.")
                            .font(.system(size: 15))
                            .foregroundColor(Color(white: 0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Permission button with glow
                    Button(action: openFullDiskAccess) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Open Full Disk Access")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .offset(x: isHoveredButton ? 4 : 0)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(isHoveredButton ? 0.15 : 0.08))
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(isHoveredButton ? 0.4 : 0.2),
                                                Color.white.opacity(isHoveredButton ? 0.15 : 0.08)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color.white.opacity(isHoveredButton ? 0.2 : 0.1), radius: isHoveredButton ? 25 : 15)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 340)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHoveredButton = hovering
                        }
                    }
                    
                    // Info text
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        Text("This permission is required to access your messages")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(white: 0.4))
                }
                .padding(48)
                .frame(width: 520)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(white: 0.06))
                )
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            checkMessagesAccess()
        }
    }

    private func openFullDiskAccess() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func checkMessagesAccess() {
        let messagesPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Messages")
            .appendingPathComponent("chat.db")
        
        if FileManager.default.fileExists(atPath: messagesPath.path) {
            _ = try? Data(contentsOf: messagesPath)
        }
    }
}

#Preview {
    PermissionView()
}

