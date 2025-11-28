import SwiftUI
import Foundation

@main
struct AgentTextApp: App {
    @StateObject private var apiServerManager = APIServerManager()
    @StateObject private var messageWatcher = MessageWatcherService.shared
    
    init() {
        // Configure Firebase
        FirebaseService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(apiServerManager)
                .environmentObject(messageWatcher)
        }
    }
}

struct AppRootView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var hasAccess = hasFullDiskAccess()
    @State private var showSignIn = false
    
    var body: some View {
        Group {
            if hasAccess {
                // Check if user is already logged in
                if authManager.isAuthenticated {
                    // Main app view (to be implemented)
                    MainView()
                        .frame(minWidth: 600, minHeight: 400)
                        .environmentObject(authManager)
                } else {
                    if showSignIn {
                        SignInView(onSignIn: {
                            // Auth state will update automatically via listener
                        }, onShowLogin: {
                            showSignIn = false
                        })
                        .frame(minWidth: 600, minHeight: 700)
                        .transition(.opacity)
                    } else {
                        LoginView(onLogin: {
                            // Auth state will update automatically via listener
                        }, onShowSignIn: {
                            showSignIn = true
                        })
                        .frame(minWidth: 600, minHeight: 700)
                        .transition(.opacity)
                    }
                }
            } else {
                PermissionView()
                    .frame(minWidth: 360, minHeight: 220)
                    .onAppear {
                        // Check access periodically in case user grants it
                        checkAccessPeriodically()
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            // Re-check access when app becomes active
            hasAccess = hasFullDiskAccess()
        }
    }
    
    private func checkAccessPeriodically() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if hasFullDiskAccess() {
                hasAccess = true
            } else {
                checkAccessPeriodically()
            }
        }
    }
}

func hasFullDiskAccess() -> Bool {
    let chatDB = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Messages/chat.db")

    // Try reading 1 byte — safe, fast, works
    if let handle = try? FileHandle(forReadingFrom: chatDB) {
        handle.closeFile()
        return true
    } else {
        return false
    }
}

// Main app view with Dashboard
struct MainView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var messageWatcher: MessageWatcherService
    @EnvironmentObject var apiServerManager: APIServerManager
    @State private var showMentionAlert = false
    @State private var currentMention: DetectedMention?
    @State private var serverStarted = false
    @State private var isHoveredLogout = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern top bar with user info and logout
            HStack(spacing: 16) {
                // User info with icon
                HStack(spacing: 12) {
                    // User avatar with glow
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Text(userInitials)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.white.opacity(0.1), radius: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let userData = authManager.userData,
                           let firstName = userData["firstName"] as? String,
                           let lastName = userData["lastName"] as? String {
                            Text("\(firstName) \(lastName)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        if let macUsername = authManager.userData?["macUsername"] as? String {
                            Text(macUsername)
                                .font(.system(size: 11))
                                .foregroundColor(Color(white: 0.5))
                        }
                    }
                }
                
                Spacer()
                
                // Watcher status indicator with modern pill design
                StatusIndicator(
                    status: watcherStatus,
                    text: watcherStatusText
                )
                
                // Modern logout button
                Button(action: handleLogout) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 13, weight: .medium))
                        Text("Log Out")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(isHoveredLogout ? .white : Color(white: 0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(isHoveredLogout ? 0.1 : 0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(isHoveredLogout ? 0.2 : 0.1), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHoveredLogout = hovering
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(white: 0.04))
            
            // Subtle glowing divider
            GlowingDivider(opacity: 0.1)
            
            // Dashboard
            DashboardView()
                .environmentObject(authManager)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task {
            // Auto-start API server when user is authenticated and MainView appears
            if !serverStarted {
                serverStarted = true
                print("[MainView] Starting API server...")
                try? await apiServerManager.startServer()
                print("[MainView] API server started, isRunning: \(apiServerManager.isRunning)")
            }
            
            // Always try to start watching if not already watching
            if !messageWatcher.isWatching {
                print("[MainView] Starting message watcher...")
                await messageWatcher.startWatching()
                print("[MainView] Message watcher status: \(messageWatcher.connectionStatus)")
            }
        }
        .onDisappear {
            // Stop watching when view disappears
            Task {
                await messageWatcher.stopWatching()
            }
        }
        .onChange(of: messageWatcher.latestMention) { oldValue, newMention in
            if let mention = newMention, mention != oldValue {
                currentMention = mention
                showMentionAlert = true
            }
        }
        .alert("Mention Detected!", isPresented: $showMentionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let mention = currentMention {
                Text(formatMentionMessage(mention))
            }
        }
    }
    
    private var userInitials: String {
        guard let userData = authManager.userData,
              let firstName = userData["firstName"] as? String,
              let lastName = userData["lastName"] as? String else {
            return "?"
        }
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func handleLogout() {
        apiServerManager.stopServer()
        Task {
            await messageWatcher.stopWatching()
        }
        do {
            try authManager.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    private var watcherStatus: StatusIndicator.Status {
        switch messageWatcher.connectionStatus {
        case .connected:
            return .connected
        case .connecting:
            return .connecting
        case .disconnected:
            return .disconnected
        case .error:
            return .error
        }
    }
    
    private var watcherStatusText: String {
        switch messageWatcher.connectionStatus {
        case .connected:
            return "Watching"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Not watching"
        case .error(let msg):
            return "Error: \(msg)"
        }
    }
    
    private func formatMentionMessage(_ mention: DetectedMention) -> String {
        print("[MainView] formatMentionMessage called")
        print("[MainView] mention.mention: \(mention.mention)")
        print("[MainView] mention.contextCount: \(mention.contextCount)")
        print("[MainView] mention.contextMessages.count: \(mention.contextMessages.count)")
        
        var message = "@\(mention.mention)"
        
        if mention.contextCount > 0 && !mention.contextMessages.isEmpty {
            message += "\n\nLast \(mention.contextMessages.count) message(s):\n"
            
            for msg in mention.contextMessages {
                let sender = msg.isFromMe ? "You" : (msg.sender ?? "Other")
                message += "\n\(sender): \(msg.text)"
            }
        } else if mention.contextCount > 0 {
            print("[MainView] contextCount > 0 but contextMessages is empty!")
            message += "\n\n(No context messages found)"
        }
        
        print("[MainView] Final message: \(message)")
        return message
    }
}