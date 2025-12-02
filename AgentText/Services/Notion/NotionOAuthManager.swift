import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Manager for handling Notion Internal Integration Token authentication
/// Provides secure access to Notion API using internal integration tokens
/// Get your token from: https://www.notion.com/my-integrations
class NotionOAuthManager: ObservableObject {
    static let shared = NotionOAuthManager()

    @Published var isAuthenticated = false
    @Published var workspaceName: String?

    // Token storage
    private var accessToken: String?

    private init() {
        loadTokensFromFirestore()
    }

    // MARK: - Internal Integration Token

    /// Set up Notion using an Internal Integration Token
    /// Get your token from: https://www.notion.com/my-integrations
    /// - Parameters:
    ///   - token: The internal integration token from Notion (must start with "secret_" or "ntn_")
    ///   - completion: Called with success/failure result
    func setInternalIntegrationToken(_ token: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NotionOAuthError.notSignedIn))
            return
        }

        // Validate token format (Notion tokens start with "secret_" or "ntn_")
        guard token.hasPrefix("secret_") || token.hasPrefix("ntn_") else {
            completion(.failure(NotionOAuthError.invalidTokenFormat))
            return
        }

        print("[NotionOAuth] Setting internal integration token")

        // Store token (internal tokens never expire)
        self.accessToken = token

        // Save to Firestore
        self.saveTokenToFirestore(userId: userId, token: token)

        DispatchQueue.main.async {
            self.isAuthenticated = true
            completion(.success(token))
        }
    }

    // MARK: - Token Management

    /// Get a valid access token
    /// Internal integration tokens never expire, so we just return the stored token
    func getValidAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        if let accessToken = accessToken {
            completion(.success(accessToken))
            return
        }

        // Token missing
        completion(.failure(NotionOAuthError.noAccessToken))
    }

    /// Revoke/Disconnect Notion access
    func revokeAccess(completion: @escaping (Result<Void, Error>) -> Void) {
        // Clear local token
        self.accessToken = nil

        // Remove from Firestore
        if let userId = Auth.auth().currentUser?.uid {
            self.removeTokenFromFirestore(userId: userId)
        }

        DispatchQueue.main.async {
            self.isAuthenticated = false
            completion(.success(()))
        }
    }

    // MARK: - Firestore Integration

    /// Save token to Firestore under the user's document
    private func saveTokenToFirestore(userId: String, token: String) {
        let db = Firestore.firestore()

        let tokenData: [String: Any] = [
            "accessToken": token,
            "tokenType": "Bearer",
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(userId).updateData([
            "notionOAuth": tokenData,
            // Also save to integrationKeys so agents can access it
            "integrationKeys.notion": token
        ]) { error in
            if let error = error {
                print("❌ [NotionOAuth] Error saving token to Firestore: \(error.localizedDescription)")
            } else {
                print("✅ [NotionOAuth] Token saved to Firestore successfully")
            }
        }
    }

    /// Load token from Firestore
    private func loadTokensFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ [NotionOAuth] Error loading token from Firestore: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(),
                  let oauthData = data["notionOAuth"] as? [String: Any],
                  let accessToken = oauthData["accessToken"] as? String else {
                print("ℹ️ [NotionOAuth] No stored token found")
                return
            }

            self.accessToken = accessToken

            DispatchQueue.main.async {
                self.isAuthenticated = self.accessToken != nil
                print("✅ [NotionOAuth] Token loaded from Firestore")
            }
        }
    }

    /// Remove token from Firestore
    private func removeTokenFromFirestore(userId: String) {
        let db = Firestore.firestore()

        db.collection("users").document(userId).updateData([
            "notionOAuth": FieldValue.delete(),
            // Also remove from integrationKeys
            "integrationKeys.notion": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("❌ [NotionOAuth] Error removing token from Firestore: \(error.localizedDescription)")
            } else {
                print("✅ [NotionOAuth] Token removed from Firestore successfully")
            }
        }
    }
}

// MARK: - Data Models

enum NotionOAuthError: LocalizedError {
    case notSignedIn
    case noAccessToken
    case invalidTokenFormat

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in to connect Notion"
        case .noAccessToken:
            return "No access token available. Please connect Notion first."
        case .invalidTokenFormat:
            return "Invalid Notion token format. Tokens should start with 'secret_' or 'ntn_'. Get your token from https://www.notion.com/my-integrations"
        }
    }
}

