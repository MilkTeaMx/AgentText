import Foundation
import Combine
import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore

/// Manager for handling Google OAuth 2.0 authentication flow
/// Provides secure access to Google Calendar API
class GoogleOAuthManager: NSObject, ObservableObject {
    static let shared = GoogleOAuthManager()

    @Published var isAuthenticated = false
    @Published var userEmail: String?

    // OAuth Configuration
    // Using iOS client type since Desktop apps don't support custom redirect URIs
    // and localhost doesn't work reliably with ASWebAuthenticationSession on macOS
    private let clientId = "33481136950-mlphghoqv09jd84c99k6pugarc2qffov.apps.googleusercontent.com"

    // Reverse DNS notation redirect URI (required for iOS OAuth clients)
    private let redirectUri = "com.googleusercontent.apps.33481136950-mlphghoqv09jd84c99k6pugarc2qffov:/oauth2redirect"

    // OAuth Scopes for Google Calendar
    private let scopes = [
        "https://www.googleapis.com/auth/calendar"
    ]

    // Token storage
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiryDate: Date?

    private var authSession: ASWebAuthenticationSession?

    private override init() {
        super.init()
        loadTokensFromFirestore()
    }

    // MARK: - OAuth Flow

    /// Start the Google OAuth authentication flow
    /// - Parameter completion: Called with success/failure result
    func authenticate(completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(OAuthError.notSignedIn))
            return
        }

        // Validate client ID is configured
        if clientId.contains("YOUR_CLIENT_ID") {
            completion(.failure(OAuthError.clientIdNotConfigured))
            return
        }

        print("[GoogleOAuth] Starting authentication flow")
        print("[GoogleOAuth] Client ID: \(clientId)")
        print("[GoogleOAuth] Redirect URI: \(redirectUri)")

        // Build authorization URL with proper encoding
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "access_type", value: "offline"), // Request refresh token
            URLQueryItem(name: "prompt", value: "consent"), // Force consent to get refresh token
            URLQueryItem(name: "include_granted_scopes", value: "true")
        ]

        guard let authURL = components.url else {
            completion(.failure(OAuthError.invalidURL))
            return
        }

        print("[GoogleOAuth] Authorization URL: \(authURL.absoluteString)")

        // Extract the callback scheme from redirect URI (everything before ://)
        let callbackScheme = "com.googleusercontent.apps.33481136950-mlphghoqv09jd84c99k6pugarc2qffov"
        print("[GoogleOAuth] Callback scheme: \(callbackScheme)")

        // Create authentication session
        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }

            if let error = error {
                print("[GoogleOAuth] Authentication error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let callbackURL = callbackURL else {
                print("[GoogleOAuth] No callback URL received")
                DispatchQueue.main.async {
                    completion(.failure(OAuthError.noCallback))
                }
                return
            }

            print("[GoogleOAuth] Callback URL received: \(callbackURL.absoluteString)")

            // Extract authorization code from callback URL
            guard let code = self.extractAuthCode(from: callbackURL) else {
                print("[GoogleOAuth] Failed to extract authorization code")
                DispatchQueue.main.async {
                    completion(.failure(OAuthError.noAuthCode))
                }
                return
            }

            print("[GoogleOAuth] Authorization code extracted successfully")

            // Exchange code for tokens
            self.exchangeCodeForTokens(code: code, userId: userId, redirectUri: self.redirectUri) { result in
                switch result {
                case .success(let accessToken):
                    print("[GoogleOAuth] Token exchange successful")
                    DispatchQueue.main.async {
                        completion(.success(accessToken))
                    }
                case .failure(let error):
                    print("[GoogleOAuth] Token exchange failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false

        // Start the session
        let started = authSession!.start()
        if !started {
            print("[GoogleOAuth] Failed to start authentication session")
            completion(.failure(OAuthError.sessionStartFailed))
        } else {
            print("[GoogleOAuth] Authentication session started")
            print("[GoogleOAuth] Safari should now open with Google consent screen...")
        }
    }

    /// Extract authorization code from callback URL
    private func extractAuthCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        return queryItems.first(where: { $0.name == "code" })?.value
    }

    /// Exchange authorization code for access and refresh tokens
    private func exchangeCodeForTokens(code: String, userId: String, redirectUri: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        print("[GoogleOAuth] Exchanging code for tokens...")
        print("[GoogleOAuth] Using redirect URI: \(redirectUri)")

        // SECURITY NOTE: In production, you should exchange the code on your backend
        // to avoid exposing the client secret. For this implementation, we'll use
        // a public client (no client secret) which is less secure but works for demo.

        let parameters = [
            "code": code,
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code"
        ]

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        print("[GoogleOAuth] Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(OAuthError.noData))
                }
                return
            }

            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

                // Store tokens
                self.accessToken = tokenResponse.access_token
                self.refreshToken = tokenResponse.refresh_token

                if let expiresIn = tokenResponse.expires_in {
                    self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                }

                // Save to Firestore
                self.saveTokensToFirestore(userId: userId, tokenResponse: tokenResponse)

                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    completion(.success(tokenResponse.access_token))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Token Management

    /// Get a valid access token, refreshing if necessary
    func getValidAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        // Check if we have a valid token
        if let accessToken = accessToken,
           let expiryDate = tokenExpiryDate,
           expiryDate > Date().addingTimeInterval(60) { // 1 minute buffer
            completion(.success(accessToken))
            return
        }

        // Token expired or missing, try to refresh
        guard let refreshToken = refreshToken else {
            completion(.failure(OAuthError.noRefreshToken))
            return
        }

        refreshAccessToken(refreshToken: refreshToken, completion: completion)
    }

    /// Refresh the access token using the refresh token
    private func refreshAccessToken(refreshToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters = [
            "client_id": clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(OAuthError.noData))
                }
                return
            }

            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

                // Update access token
                self.accessToken = tokenResponse.access_token

                if let expiresIn = tokenResponse.expires_in {
                    self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                }

                // Update in Firestore
                if let userId = Auth.auth().currentUser?.uid {
                    self.updateAccessTokenInFirestore(userId: userId, accessToken: tokenResponse.access_token, expiresIn: tokenResponse.expires_in ?? 3600)
                }

                DispatchQueue.main.async {
                    completion(.success(tokenResponse.access_token))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    /// Revoke OAuth access
    func revokeAccess(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let accessToken = accessToken else {
            completion(.failure(OAuthError.noAccessToken))
            return
        }

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/revoke")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters = ["token": accessToken]
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            // Clear local tokens
            self.accessToken = nil
            self.refreshToken = nil
            self.tokenExpiryDate = nil

            // Remove from Firestore
            if let userId = Auth.auth().currentUser?.uid {
                self.removeTokensFromFirestore(userId: userId)
            }

            DispatchQueue.main.async {
                self.isAuthenticated = false
                completion(.success(()))
            }
        }.resume()
    }

    // MARK: - Firestore Integration

    /// Save tokens to Firestore under the user's document
    private func saveTokensToFirestore(userId: String, tokenResponse: TokenResponse) {
        let db = Firestore.firestore()

        var tokenData: [String: Any] = [
            "accessToken": tokenResponse.access_token,
            "tokenType": tokenResponse.token_type ?? "Bearer",
            "scope": tokenResponse.scope ?? scopes.joined(separator: " "),
            "expiresAt": Timestamp(date: Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in ?? 3600))),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let refreshToken = tokenResponse.refresh_token {
            tokenData["refreshToken"] = refreshToken
        }

        db.collection("users").document(userId).updateData([
            "googleOAuth": tokenData,
            // Also save to integrationKeys so agents can access it
            "integrationKeys.google_calendar": tokenResponse.access_token
        ]) { error in
            if let error = error {
                print("❌ [GoogleOAuth] Error saving tokens to Firestore: \(error.localizedDescription)")
            } else {
                print("✅ [GoogleOAuth] Tokens saved to Firestore successfully")
            }
        }
    }

    /// Update access token in Firestore
    private func updateAccessTokenInFirestore(userId: String, accessToken: String, expiresIn: Int) {
        let db = Firestore.firestore()

        db.collection("users").document(userId).updateData([
            "googleOAuth.accessToken": accessToken,
            "googleOAuth.expiresAt": Timestamp(date: Date().addingTimeInterval(TimeInterval(expiresIn))),
            "googleOAuth.updatedAt": FieldValue.serverTimestamp(),
            // Also update integrationKeys so agents always have the latest token
            "integrationKeys.google_calendar": accessToken
        ]) { error in
            if let error = error {
                print("❌ [GoogleOAuth] Error updating token in Firestore: \(error.localizedDescription)")
            } else {
                print("✅ [GoogleOAuth] Token updated in Firestore successfully")
            }
        }
    }

    /// Load tokens from Firestore
    private func loadTokensFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ [GoogleOAuth] Error loading tokens from Firestore: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(),
                  let oauthData = data["googleOAuth"] as? [String: Any] else {
                print("ℹ️ [GoogleOAuth] No stored tokens found")
                return
            }

            self.accessToken = oauthData["accessToken"] as? String
            self.refreshToken = oauthData["refreshToken"] as? String

            if let expiresAt = oauthData["expiresAt"] as? Timestamp {
                self.tokenExpiryDate = expiresAt.dateValue()
            }

            DispatchQueue.main.async {
                self.isAuthenticated = self.accessToken != nil
                print("✅ [GoogleOAuth] Tokens loaded from Firestore")
            }
        }
    }

    /// Remove tokens from Firestore
    private func removeTokensFromFirestore(userId: String) {
        let db = Firestore.firestore()

        db.collection("users").document(userId).updateData([
            "googleOAuth": FieldValue.delete(),
            // Also remove from integrationKeys
            "integrationKeys.google_calendar": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("❌ [GoogleOAuth] Error removing tokens from Firestore: \(error.localizedDescription)")
            } else {
                print("✅ [GoogleOAuth] Tokens removed from Firestore successfully")
            }
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension GoogleOAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// MARK: - Data Models

struct TokenResponse: Codable {
    let access_token: String
    let expires_in: Int?
    let refresh_token: String?
    let scope: String?
    let token_type: String?
}

enum OAuthError: LocalizedError {
    case notSignedIn
    case invalidURL
    case noCallback
    case noAuthCode
    case noData
    case noAccessToken
    case noRefreshToken
    case clientIdNotConfigured
    case sessionStartFailed

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in to connect Google Calendar"
        case .invalidURL:
            return "Invalid OAuth URL"
        case .noCallback:
            return "No callback URL received"
        case .noAuthCode:
            return "No authorization code in callback"
        case .noData:
            return "No data received from server"
        case .noAccessToken:
            return "No access token available"
        case .noRefreshToken:
            return "No refresh token available. Please re-authenticate."
        case .clientIdNotConfigured:
            return "Google Client ID not configured. Please update GoogleOAuthManager.swift with your Client ID from Google Cloud Console."
        case .sessionStartFailed:
            return "Failed to start authentication session"
        }
    }
}
