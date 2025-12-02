import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    
    private var db: Firestore!
    
    private init() {}
    
    func configure() {
        print("🔵 [FirebaseService] Starting Firebase configuration...")

        guard FirebaseApp.app() == nil else {
            print("✅ [FirebaseService] Firebase already configured")
            if db == nil {
                db = Firestore.firestore()
            }
            return
        }

        // Try to find the plist in the bundle first
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) {
            print("✅ [FirebaseService] GoogleService-Info.plist found at: \(path)")

            // Log some key info (without sensitive data)
            if let projectID = plist["PROJECT_ID"] as? String {
                print("   - Project ID: \(projectID)")
            }
            if let bundleID = plist["BUNDLE_ID"] as? String {
                print("   - Bundle ID: \(bundleID)")
            }

            FirebaseApp.configure()
            print("✅ [FirebaseService] FirebaseApp.configure() called successfully")
        } else {
            // If not in bundle, try to load from source directory (for debug builds)
            print("⚠️ [FirebaseService] GoogleService-Info.plist not found in bundle")
            print("   Bundle path: \(Bundle.main.bundlePath)")
            print("   Current directory: \(FileManager.default.currentDirectoryPath)")
            print("   Attempting to load from source directory...")

            let possiblePaths = [
                Bundle.main.bundlePath + "/../../AgentText/GoogleService-Info.plist",
                Bundle.main.bundlePath + "/../../../AgentText/GoogleService-Info.plist",
                FileManager.default.currentDirectoryPath + "/AgentText/GoogleService-Info.plist",
                NSHomeDirectory() + "/development/AgentText/AgentText/GoogleService-Info.plist"
            ]

            var configured = false
            for path in possiblePaths {
                let expandedPath = (path as NSString).standardizingPath
                print("   Checking: \(expandedPath)")
                if FileManager.default.fileExists(atPath: expandedPath),
                   let plist = NSDictionary(contentsOfFile: expandedPath),
                   let apiKey = plist["API_KEY"] as? String,
                   let gcmSenderID = plist["GCM_SENDER_ID"] as? String,
                   let projectID = plist["PROJECT_ID"] as? String,
                   let bundleID = plist["BUNDLE_ID"] as? String,
                   let googleAppID = plist["GOOGLE_APP_ID"] as? String {

                    print("✅ [FirebaseService] Found GoogleService-Info.plist at: \(expandedPath)")
                    print("   - Project ID: \(projectID)")
                    print("   - Bundle ID: \(bundleID)")

                    // Manually configure Firebase with options
                    let options = FirebaseOptions(googleAppID: googleAppID, gcmSenderID: gcmSenderID)
                    options.apiKey = apiKey
                    options.projectID = projectID
                    options.bundleID = bundleID
                    if let storageBucket = plist["STORAGE_BUCKET"] as? String {
                        options.storageBucket = storageBucket
                    }
                    if let databaseURL = plist["DATABASE_URL"] as? String {
                        options.databaseURL = databaseURL
                    }

                    FirebaseApp.configure(options: options)
                    print("✅ [FirebaseService] Firebase manually configured successfully")
                    configured = true
                    break
                }
            }

            if !configured {
                print("❌ [FirebaseService] ERROR: Could not find or configure Firebase")
                print("   Make sure GoogleService-Info.plist exists in AgentText/ directory")
                return
            }
        }

        db = Firestore.firestore()
        print("✅ [FirebaseService] Firestore initialized")

        // Test Firestore connection
        testFirestoreConnection()
    }
    
    private func testFirestoreConnection() {
        print("🔵 [FirebaseService] Testing Firestore connection...")
        Task {
            do {
                // Try to read from a test collection (this will fail if not configured, but won't crash)
                _ = try await db.collection("_test").document("connection").getDocument()
                print("✅ [FirebaseService] Firestore connection test successful")
            } catch {
                // This is expected if the document doesn't exist, but it means Firestore is accessible
                if let nsError = error as NSError? {
                    // Error code 5 = NOT_FOUND, which is fine - it means Firestore is working
                    if nsError.code == 5 {
                        print("✅ [FirebaseService] Firestore is accessible (test document not found is expected)")
                    } else {
                        print("⚠️ [FirebaseService] Firestore test error: \(error.localizedDescription)")
                        print("   Error code: \(nsError.code),  Domain: \(nsError.domain)")
                    }
                }
            }
        }
    }
     
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> User {
        print("   [FirebaseService] signIn called with email: \(email)")
        print("   [FirebaseService] Creating credential...")
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        print("   [FirebaseService] Credential created, signing in...")
        let result = try await Auth.auth().signIn(with: credential)
        print("   [FirebaseService] Sign in successful! User ID: \(result.user.uid)")
        return result.user
    }
    
    func createUser(email: String, password: String, macUsername: String, firstName: String, lastName: String) async throws -> User {
        print("   [FirebaseService] createUser called")
        print("   [FirebaseService] - Email: \(email)")
        print("   [FirebaseService] - Mac Username: \(macUsername)")
        print("   [FirebaseService] - First Name: \(firstName)")
        print("   [FirebaseService] - Last Name: \(lastName)")
        
        // Create user with email for Firebase Auth
        print("   [FirebaseService] Creating Firebase Auth user...")
        let result: AuthDataResult
        do {
            result = try await Auth.auth().createUser(withEmail: email, password: password)
        } catch let error as NSError {
            // Check for specific Firebase Auth configuration errors
            if error.domain == "FIRAuthErrorDomain" || error.domain == "FIRAuthInternalErrorDomain" {
                if let deserializedResponse = error.userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"] as? [String: Any],
                   let message = deserializedResponse["message"] as? String {
                    if message == "CONFIGURATION_NOT_FOUND" {
                        print("❌ [FirebaseService] ERROR: Email/Password authentication is not enabled in Firebase Console!")
                        print("   → Go to Firebase Console → Authentication → Sign-in method")
                        print("   → Enable 'Email/Password' provider")
                        print("   → Then try again")
                    }
                }
            }
            throw error
        }
        
        let user = result.user
        print("   [FirebaseService] Firebase Auth user created! UID: \(user.uid)")
        
        // Save user data to Firestore (including Mac username)
        print("   [FirebaseService] Saving user data to Firestore...")
        try await saveUserData(
            uid: user.uid,
            email: email,
            macUsername: macUsername,
            firstName: firstName,
            lastName: lastName
        )
        print("   [FirebaseService] User data saved to Firestore successfully!")
        
        return user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    // MARK: - Firestore User Data
    
    private func saveUserData(uid: String, email: String, macUsername: String, firstName: String, lastName: String) async throws {
        print("      [saveUserData] Preparing user data for UID: \(uid)")
        let userData: [String: Any] = [
            "email": email,
            "macUsername": macUsername,
            "firstName": firstName,
            "lastName": lastName,
            "downloadedApps": [],
            "enabledApps": [],
            "likedAgents": [],
            "dislikedAgents": [],
            "integrationKeys": [:], // Store API keys for integrations (e.g., {"google_calendar": "key123"})
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        print("      [saveUserData] Writing to Firestore collection 'users'...")
        try await db.collection("users").document(uid).setData(userData)
        print("      [saveUserData] Firestore write successful!")
    }
    
    func getUserData(uid: String) async throws -> [String: Any]? {
        let document = try await db.collection("users").document(uid).getDocument()
        return document.data()
    }
    
    func updateDownloadedApps(uid: String, appIds: [String]) async throws {
        try await db.collection("users").document(uid).updateData([
            "downloadedApps": appIds
        ])
    }
    
    func updateEnabledApps(uid: String, appIds: [String]) async throws {
        try await db.collection("users").document(uid).updateData([
            "enabledApps": appIds
        ])
    }

    func updateIntegrationKey(uid: String, integration: String, apiKey: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "integrationKeys.\(integration)": apiKey
        ])
    }

    func removeIntegrationKey(uid: String, integration: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "integrationKeys.\(integration)": FieldValue.delete()
        ])
    }

    // MARK: - Agent Management
    
    func createAgent(
        agentName: String,
        description: String,
        apiUrl: String,
        integrations: [String],
        developerId: String,
        developerName: String
    ) async throws {
        print("   [FirebaseService] createAgent called")
        print("   [FirebaseService] - Agent Name: \(agentName)")
        print("   [FirebaseService] - API URL: \(apiUrl)")
        print("   [FirebaseService] - Integrations: \(integrations)")
        print("   [FirebaseService] - Developer ID: \(developerId)")
        print("   [FirebaseService] - Developer Name: \(developerName)")

        // Sanitize agent name for use as Firestore document ID
        // Firestore document IDs can contain letters, numbers, and these characters: -_~!@#$%^&*()
        // We'll replace spaces with underscores and remove invalid characters
        let sanitizedAgentName = agentName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ".", with: "_")

        // Check if agent with this name already exists
        let docRef = db.collection("agents").document(sanitizedAgentName)
        let existingDoc = try? await docRef.getDocument()

        if existingDoc?.exists == true {
            throw NSError(
                domain: "FirebaseService",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: "An agent with this name already exists. Please choose a different name."]
            )
        }

        // Generate unique ID for the agent
        let agentId = UUID().uuidString
        print("   [FirebaseService] Generated unique agent ID: \(agentId)")

        let agentData: [String: Any] = [
            "agent_id": agentId, // Unique identifier
            "agent_name": agentName, // Store original name in the data
            "description": description,
            "api_url": apiUrl, // Hosted API endpoint
            "integrations": integrations, // List of enabled integrations
            "developer_id": developerId,
            "developer_name": developerName,
            "installations": 0, // Installation count
            "likes": 0, // Like count
            "dislikes": 0, // Dislike count
            "created_at": FieldValue.serverTimestamp()
        ]
        
        print("   [FirebaseService] Writing agent to Firestore collection 'agents' with document ID: \(sanitizedAgentName)...")
        do {
            try await docRef.setData(agentData)
            print("   [FirebaseService] Agent created successfully! Document ID: \(sanitizedAgentName)")
        } catch let error as NSError {
            print("❌ [FirebaseService] Error creating agent:")
            print("   - Error Domain: \(error.domain)")
            print("   - Error Code: \(error.code)")
            print("   - Localized Description: \(error.localizedDescription)")
            print("   - User Info: \(error.userInfo)")
            
            // Print all error details
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("   - Underlying Error Domain: \(underlyingError.domain)")
                print("   - Underlying Error Code: \(underlyingError.code)")
                print("   - Underlying Error Description: \(underlyingError.localizedDescription)")
                print("   - Underlying Error User Info: \(underlyingError.userInfo)")
            }
            
            // Check for Firestore-specific errors
            if error.domain == "FIRFirestoreErrorDomain" {
                print("   - This is a Firestore permission error.")
                print("   - Make sure Firestore security rules allow writes to 'agents' collection")
                print("   - Example rule: allow write: if request.auth != null;")
            }
            
            throw error
        }
    }
    
    // MARK: - Agent Queries
    
    func fetchAllAgents() async throws -> [Agent] {
        print("   [FirebaseService] fetchAllAgents called")
        let snapshot = try await db.collection("agents").getDocuments()
        let agents = snapshot.documents.map { doc in
            Agent(id: doc.documentID, data: doc.data())
        }
        print("   [FirebaseService] Fetched \(agents.count) agents")
        return agents
    }
    
    func fetchDeveloperAgents(developerId: String) async throws -> [Agent] {
        print("   [FirebaseService] fetchDeveloperAgents called for developer: \(developerId)")
        let snapshot = try await db.collection("agents")
            .whereField("developer_id", isEqualTo: developerId)
            .getDocuments()
        let agents = snapshot.documents.map { doc in
            Agent(id: doc.documentID, data: doc.data())
        }
        print("   [FirebaseService] Fetched \(agents.count) agents for developer")
        return agents
    }
    
    func deleteAgent(agentId: String, developerId: String) async throws {
        print("   [FirebaseService] deleteAgent called")
        print("   [FirebaseService] - Agent Document ID: \(agentId)")
        print("   [FirebaseService] - Developer ID: \(developerId)")
        
        // Verify the developer owns this agent
        print("   [FirebaseService] Step 1: Verifying developer ownership...")
        let agentDoc = try await db.collection("agents").document(agentId).getDocument()
        
        print("   [FirebaseService] - Agent document exists: \(agentDoc.exists)")
        
        guard agentDoc.exists else {
            print("   [FirebaseService] ❌ ERROR: Agent document does not exist")
            throw NSError(
                domain: "FirebaseService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Agent not found."]
            )
        }
        
        guard let agentData = agentDoc.data() else {
            print("   [FirebaseService] ❌ ERROR: Agent document has no data")
            throw NSError(
                domain: "FirebaseService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Agent data is invalid."]
            )
        }
        
        guard let agentDeveloperId = agentData["developer_id"] as? String else {
            print("   [FirebaseService] ❌ ERROR: Agent document missing developer_id field")
            print("   [FirebaseService] - Agent data keys: \(agentData.keys)")
            throw NSError(
                domain: "FirebaseService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Agent is missing developer information."]
            )
        }
        
        print("   [FirebaseService] - Agent developer_id from Firestore: \(agentDeveloperId)")
        print("   [FirebaseService] - Current user developer_id: \(developerId)")
        print("   [FirebaseService] - Ownership match: \(agentDeveloperId == developerId)")
        
        guard agentDeveloperId == developerId else {
            print("   [FirebaseService] ❌ ERROR: Developer ownership verification failed")
            print("   [FirebaseService] - Expected: \(developerId)")
            print("   [FirebaseService] - Found: \(agentDeveloperId)")
            throw NSError(
                domain: "FirebaseService",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "You can only delete agents that you created."]
            )
        }
        
        print("   [FirebaseService] ✅ Verified developer ownership")
        
        // Delete the agent document from Firestore
        // Note: Dangling installs/likes/dislikes will be cleaned up per-user when they load their installed agents
        print("   [FirebaseService] Step 2: Attempting to delete agent document from Firestore...")
        print("   [FirebaseService] - Collection: 'agents'")
        print("   [FirebaseService] - Document ID: \(agentId)")
        print("   [FirebaseService] - Current authenticated user: \(Auth.auth().currentUser?.uid ?? "nil")")
        
        do {
            try await db.collection("agents").document(agentId).delete()
            print("   [FirebaseService] ✅ Agent deleted successfully from Firestore")
        } catch let error as NSError {
            print("   [FirebaseService] ❌ ERROR: Failed to delete agent document")
            print("   [FirebaseService] - Error Domain: \(error.domain)")
            print("   [FirebaseService] - Error Code: \(error.code)")
            print("   [FirebaseService] - Error Description: \(error.localizedDescription)")
            print("   [FirebaseService] - Error UserInfo: \(error.userInfo)")
            
            if error.domain == "FIRFirestoreErrorDomain" {
                print("   [FirebaseService] - This is a Firestore permission error")
                print("   [FirebaseService] - Firestore security rules are blocking the delete operation")
                print("   [FirebaseService] - Current rule likely only allows: allow delete: if request.auth != null && request.resource.data.developer_id == request.auth.uid")
                print("   [FirebaseService] - But delete operations don't have request.resource.data (that's for updates)")
                print("   [FirebaseService] - Need to use: allow delete: if request.auth != null && resource.data.developer_id == request.auth.uid")
            }
            
            throw error
        }
    }
    
    func installAgent(agentId: String, userId: String) async throws {
        print("   [FirebaseService] installAgent called")
        print("   - Agent Document ID: \(agentId)")
        print("   - User ID: \(userId)")

        // Add to user's installed agents list first (this should always succeed)
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "downloadedApps": FieldValue.arrayUnion([agentId])
        ])

        // Try to increment installation count (may fail if user doesn't have permission)
        do {
            let agentRef = db.collection("agents").document(agentId)
            try await agentRef.updateData([
                "installations": FieldValue.increment(Int64(1))
            ])
            print("   [FirebaseService] Installation count incremented")
        } catch {
            // Log the error but don't fail the installation
            print("   [FirebaseService] Warning: Could not increment installation count: \(error.localizedDescription)")
            print("   [FirebaseService] This is likely due to Firestore security rules. The agent was still added to your library.")
        }

        print("   [FirebaseService] Agent installed successfully")
    }

    func fetchInstalledAgentIds(userId: String) async throws -> Set<String> {
        print("   [FirebaseService] fetchInstalledAgentIds called for user: \(userId)")

        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data() else {
            print("   [FirebaseService] No user data found")
            return []
        }

        let installedIds = userData["downloadedApps"] as? [String] ?? []
        print("   [FirebaseService] Found \(installedIds.count) installed agent IDs")

        return Set(installedIds)
    }

    func fetchInstalledAgents(userId: String) async throws -> [Agent] {
        print("   [FirebaseService] fetchInstalledAgents called for user: \(userId)")
        
        // Get user's installed agent IDs, liked agents, and disliked agents
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data() else {
            print("   [FirebaseService] No user data found")
            return []
        }
        
        let installedIds = userData["downloadedApps"] as? [String] ?? []
        let likedIds = userData["likedAgents"] as? [String] ?? []
        let dislikedIds = userData["dislikedAgents"] as? [String] ?? []
        
        if installedIds.isEmpty {
            print("   [FirebaseService] No installed agents found")
            return []
        }
        
        // Fetch all installed agents and check if they still exist
        var validAgents: [Agent] = []
        var validInstalledIds: [String] = []
        var validLikedIds: [String] = []
        var validDislikedIds: [String] = []
        
        for agentId in installedIds {
            let agentDoc = try await db.collection("agents").document(agentId).getDocument()
            if agentDoc.exists, let data = agentDoc.data() {
                // Agent exists, add it to valid list
                validAgents.append(Agent(id: agentDoc.documentID, data: data))
                validInstalledIds.append(agentId)
                
                // Keep likes/dislikes if agent exists
                if likedIds.contains(agentId) {
                    validLikedIds.append(agentId)
                }
                if dislikedIds.contains(agentId) {
                    validDislikedIds.append(agentId)
                }
            } else {
                // Agent doesn't exist (was deleted), remove from user's lists
                print("   [FirebaseService] Found dangling agent reference: \(agentId), removing from user's lists")
            }
        }
        
        // Clean up dangling references in user's document
        if validInstalledIds.count != installedIds.count ||
           validLikedIds.count != likedIds.count ||
           validDislikedIds.count != dislikedIds.count {
            print("   [FirebaseService] Cleaning up dangling references...")
            var updates: [String: Any] = [:]
            
            if validInstalledIds.count != installedIds.count {
                updates["downloadedApps"] = validInstalledIds
            }
            if validLikedIds.count != likedIds.count {
                updates["likedAgents"] = validLikedIds
            }
            if validDislikedIds.count != dislikedIds.count {
                updates["dislikedAgents"] = validDislikedIds
            }
            
            if !updates.isEmpty {
                try await db.collection("users").document(userId).updateData(updates)
                print("   [FirebaseService] Cleaned up \(installedIds.count - validInstalledIds.count) dangling installed references")
                print("   [FirebaseService] Cleaned up \(likedIds.count - validLikedIds.count) dangling liked references")
                print("   [FirebaseService] Cleaned up \(dislikedIds.count - validDislikedIds.count) dangling disliked references")
            }
        }
        
        print("   [FirebaseService] Fetched \(validAgents.count) installed agents")
        return validAgents
    }
    
    func toggleLikeAgent(agentId: String, userId: String) async throws -> (isLiked: Bool, likes: Int) {
        print("   [FirebaseService] toggleLikeAgent called for document ID: \(agentId), user: \(userId)")
        
        // Get user's current likes/dislikes
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let userData = userDoc.data() ?? [:]
        let likedAgents = userData["likedAgents"] as? [String] ?? []
        let dislikedAgents = userData["dislikedAgents"] as? [String] ?? []
        
        let agentRef = db.collection("agents").document(agentId)
        let agentDoc = try await agentRef.getDocument()
        let currentLikes = (agentDoc.data()?["likes"] as? Int) ?? 0
        let currentDislikes = (agentDoc.data()?["dislikes"] as? Int) ?? 0
        
        let isCurrentlyLiked = likedAgents.contains(agentId)
        let isCurrentlyDisliked = dislikedAgents.contains(agentId)
        
        var newLikes = currentLikes
        var newLikedAgents = likedAgents
        var newDislikedAgents = dislikedAgents
        var isLiked = false
        
        if isCurrentlyLiked {
            // Remove like
            newLikes = max(0, currentLikes - 1)
            newLikedAgents.removeAll { $0 == agentId }
            isLiked = false
        } else {
            // Add like
            newLikes = currentLikes + 1
            if !newLikedAgents.contains(agentId) {
                newLikedAgents.append(agentId)
            }
            isLiked = true
            
            // Remove from dislikes if it was disliked
            if isCurrentlyDisliked {
                let newDislikes = max(0, currentDislikes - 1)
                try await agentRef.updateData([
                    "dislikes": newDislikes
                ])
                newDislikedAgents.removeAll { $0 == agentId }
            }
        }
        
        // Update agent likes
        try await agentRef.updateData([
            "likes": newLikes
        ])
        
        // Update user's liked/disliked agents
        try await db.collection("users").document(userId).updateData([
            "likedAgents": newLikedAgents,
            "dislikedAgents": newDislikedAgents
        ])
        
        print("   [FirebaseService] Agent like toggled. Is liked: \(isLiked), New likes count: \(newLikes)")
        return (isLiked, newLikes)
    }
    
    func toggleDislikeAgent(agentId: String, userId: String) async throws -> (isDisliked: Bool, dislikes: Int) {
        print("   [FirebaseService] toggleDislikeAgent called for document ID: \(agentId), user: \(userId)")
        
        // Get user's current likes/dislikes
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let userData = userDoc.data() ?? [:]
        let likedAgents = userData["likedAgents"] as? [String] ?? []
        let dislikedAgents = userData["dislikedAgents"] as? [String] ?? []
        
        let agentRef = db.collection("agents").document(agentId)
        let agentDoc = try await agentRef.getDocument()
        let currentLikes = (agentDoc.data()?["likes"] as? Int) ?? 0
        let currentDislikes = (agentDoc.data()?["dislikes"] as? Int) ?? 0
        
        let isCurrentlyLiked = likedAgents.contains(agentId)
        let isCurrentlyDisliked = dislikedAgents.contains(agentId)
        
        var newDislikes = currentDislikes
        var newLikedAgents = likedAgents
        var newDislikedAgents = dislikedAgents
        var isDisliked = false
        
        if isCurrentlyDisliked {
            // Remove dislike
            newDislikes = max(0, currentDislikes - 1)
            newDislikedAgents.removeAll { $0 == agentId }
            isDisliked = false
        } else {
            // Add dislike
            newDislikes = currentDislikes + 1
            if !newDislikedAgents.contains(agentId) {
                newDislikedAgents.append(agentId)
            }
            isDisliked = true
            
            // Remove from likes if it was liked
            if isCurrentlyLiked {
                let newLikes = max(0, currentLikes - 1)
                try await agentRef.updateData([
                    "likes": newLikes
                ])
                newLikedAgents.removeAll { $0 == agentId }
            }
        }
        
        // Update agent dislikes
        try await agentRef.updateData([
            "dislikes": newDislikes
        ])
        
        // Update user's liked/disliked agents
        try await db.collection("users").document(userId).updateData([
            "likedAgents": newLikedAgents,
            "dislikedAgents": newDislikedAgents
        ])
        
        print("   [FirebaseService] Agent dislike toggled. Is disliked: \(isDisliked), New dislikes count: \(newDislikes)")
        return (isDisliked, newDislikes)
    }
    
    func getUserReaction(agentId: String, userId: String) async throws -> (isLiked: Bool, isDisliked: Bool) {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let userData = userDoc.data() ?? [:]
        let likedAgents = userData["likedAgents"] as? [String] ?? []
        let dislikedAgents = userData["dislikedAgents"] as? [String] ?? []
        
        return (
            isLiked: likedAgents.contains(agentId),
            isDisliked: dislikedAgents.contains(agentId)
        )
    }
}

