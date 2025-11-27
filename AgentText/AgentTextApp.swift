import SwiftUI
import Foundation

@main
struct AgentTextApp: App {
    init() {
        // Configure Firebase
        FirebaseService.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with user info and logout
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let userData = authManager.userData,
                       let firstName = userData["firstName"] as? String,
                       let lastName = userData["lastName"] as? String {
                        Text("Welcome, \(firstName) \(lastName)!")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    if let macUsername = authManager.userData?["macUsername"] as? String {
                        Text(macUsername)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("Log Out") {
                    do {
                        try authManager.signOut()
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            
            Divider()
            
            // Dashboard
            DashboardView()
                .environmentObject(authManager)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
    }
}
