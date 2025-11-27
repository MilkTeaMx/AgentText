import Foundation
import Combine
import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var userData: [String: Any]?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                
                if let user = user {
                    Task {
                        await self?.loadUserData(uid: user.uid)
                    }
                } else {
                    self?.userData = nil
                }
            }
        }
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        print("   [AuthManager] signIn called")
        let user = try await FirebaseService.shared.signIn(email: email, password: password)
        print("   [AuthManager] Sign in successful, loading user data...")
        await loadUserData(uid: user.uid)
        print("   [AuthManager] User data loaded!")
    }
    
    @MainActor
    func signUp(email: String, password: String, macUsername: String, firstName: String, lastName: String) async throws {
        print("   [AuthManager] signUp called")
        let user = try await FirebaseService.shared.createUser(
            email: email,
            password: password,
            macUsername: macUsername,
            firstName: firstName,
            lastName: lastName
        )
        print("   [AuthManager] User created, loading user data...")
        await loadUserData(uid: user.uid)
        print("   [AuthManager] User data loaded!")
    }
    
    @MainActor
    func signOut() throws {
        try FirebaseService.shared.signOut()
        userData = nil
        isAuthenticated = false
    }
    
    @MainActor
    private func loadUserData(uid: String) async {
        do {
            userData = try await FirebaseService.shared.getUserData(uid: uid)
        } catch {
            print("Error loading user data: \(error)")
        }
    }
    
    @MainActor
    func updateDownloadedApps(_ appIds: [String]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await FirebaseService.shared.updateDownloadedApps(uid: uid, appIds: appIds)
        await loadUserData(uid: uid)
    }
    
    @MainActor
    func updateEnabledApps(_ appIds: [String]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await FirebaseService.shared.updateEnabledApps(uid: uid, appIds: appIds)
        await loadUserData(uid: uid)
    }
}

