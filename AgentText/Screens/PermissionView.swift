import SwiftUI
import AppKit

struct PermissionView: View {
    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.1, green: 0.1, blue: 0.12)
                .ignoresSafeArea()
            
            // Main card with luminescent outline
            LuminescentCard {
                VStack(spacing: 32) {
                    // Logo
                    LogoView(size: 80)
                    
                    VStack(spacing: 16) {
                        Text("AgentText Setup")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("To enable message processing, please grant Full Disk Access.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button(action: openFullDiskAccess) {
                        Text("Open Full Disk Access")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.22))
                            )
                    }
                    .buttonStyle(.plain)
                    .frame(width: 320)
                }
                .padding(40)
                .frame(width: 480)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
                )
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            // Attempt to access Messages database to trigger macOS to add app to Full Disk Access list
            checkMessagesAccess()
        }
    }

    private func openFullDiskAccess() {
        // Use the correct URL for macOS 13+ System Settings
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func checkMessagesAccess() {
        // Attempt to access the Messages database
        // This will fail without permission, but makes macOS aware the app needs Full Disk Access
        let messagesPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Messages")
            .appendingPathComponent("chat.db")
        
        // Try to read from the database - this triggers macOS to add app to Full Disk Access list
        if FileManager.default.fileExists(atPath: messagesPath.path) {
            // Attempt to open the database file
            // This will fail without Full Disk Access, but makes macOS aware
            _ = try? Data(contentsOf: messagesPath)
        }
    }
}

#Preview {
    PermissionView()
}

