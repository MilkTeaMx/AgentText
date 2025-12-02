import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var googleOAuth = GoogleOAuthManager.shared
    @StateObject private var notionOAuth = NotionOAuthManager.shared

    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var isConnectingNotion = false
    @State private var errorMessageNotion: String?
    @State private var showSuccessNotion = false
    @State private var notionTokenInput = ""

    private var currentUser: User? {
        Auth.auth().currentUser
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("Manage your account settings")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(Color(white: 0.04))

            GlowingDivider(opacity: 0.1)

            // Profile content
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Card
                    GlassCard {
                        VStack(spacing: 20) {
                            // User Avatar
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(white: 0.2), Color(white: 0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.white.opacity(0.1), radius: 10)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(Color(white: 0.7))
                            }

                            VStack(spacing: 8) {
                                if let user = currentUser {
                                    Text(user.email ?? "No email")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text("User ID: \(user.uid)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(white: 0.5))
                                } else {
                                    Text("Not signed in")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(white: 0.5))
                                }
                            }
                        }
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                    }

                    // Account Information
                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Account Information")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            GlowingDivider(opacity: 0.08)

                            if let user = currentUser {
                                ProfileInfoRow(label: "Email", value: user.email ?? "N/A")
                                ProfileInfoRow(label: "User ID", value: user.uid)
                                ProfileInfoRow(label: "Account Created", value: formatDate(user.metadata.creationDate))
                                ProfileInfoRow(label: "Last Sign In", value: formatDate(user.metadata.lastSignInDate))
                            } else {
                                Text("No user information available")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.5))
                            }
                        }
                        .padding(24)
                    }

                    // Google Calendar Integration
                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Google Calendar")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()

                                if googleOAuth.isAuthenticated {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                        Text("Connected")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color.green)
                                    }
                                }
                            }

                            GlowingDivider(opacity: 0.08)

                            Text(googleOAuth.isAuthenticated
                                ? "Your Google Calendar is connected. You can now access your calendar events."
                                : "Connect your Google account to access Google Calendar and manage your events.")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.6))
                                .fixedSize(horizontal: false, vertical: true)

                            // Error message
                            if let errorMessage = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }

                            // Success message
                            if showSuccess {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Successfully connected to Google Calendar!")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                }
                                .padding(12)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }

                            // Action button
                            if googleOAuth.isAuthenticated {
                                GlowingButton(
                                    "Disconnect",
                                    icon: nil,
                                    isLoading: isConnecting,
                                    style: .secondary
                                ) {
                                    disconnectGoogle()
                                }
                            } else {
                                GlowingButton(
                                    "Connect Google Calendar",
                                    icon: nil,
                                    isLoading: isConnecting,
                                    style: .primary
                                ) {
                                    connectGoogle()
                                }
                            }
                        }
                        .padding(24)
                    }

                    // Notion Integration
                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Notion")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()

                                if notionOAuth.isAuthenticated {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                        Text("Connected")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color.green)
                                    }
                                }
                            }

                            GlowingDivider(opacity: 0.08)

                            Text(notionOAuth.isAuthenticated
                                ? "Your Notion is connected. You can now access your Notion pages and databases."
                                : "Connect your Notion workspace by entering your integration token.")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.6))
                                .fixedSize(horizontal: false, vertical: true)

                            // Setup instructions (shown when not connected)
                            if !notionOAuth.isAuthenticated {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                                        Text("Setup Instructions")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("1.")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(Color(white: 0.5))
                                                .frame(width: 20, alignment: .leading)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Get your Internal Integration Secret")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(Color(white: 0.8))
                                                Text("Go to https://www.notion.com/my-integrations and find your integration. Copy the 'Internal Integration Secret' (starts with 'secret_' or 'ntn_').")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color(white: 0.5))
                                            }
                                        }
                                        
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("2.")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(Color(white: 0.5))
                                                .frame(width: 20, alignment: .leading)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Grant Page Access")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(Color(white: 0.8))
                                                Text("In Notion, go to each page/database you want to access. Click the '...' menu → 'Add connections' → Select your integration.")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color(white: 0.5))
                                            }
                                        }
                                        
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("3.")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(Color(white: 0.5))
                                                .frame(width: 20, alignment: .leading)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Paste Token Below")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(Color(white: 0.8))
                                                Text("Paste your integration secret token in the field below and click 'Connect Notion'.")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color(white: 0.5))
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }

                            // Token input field (shown when not connected)
                            if !notionOAuth.isAuthenticated {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Integration Token")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(white: 0.7))
                                    
                                    SecureField("secret_...", text: $notionTokenInput)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "link")
                                            .font(.system(size: 10))
                                        Link("Get your token from Notion", destination: URL(string: "https://www.notion.com/my-integrations")!)
                                            .font(.system(size: 11))
                                    }
                                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                                }
                            }

                            // Error message
                            if let errorMessageNotion = errorMessageNotion {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMessageNotion)
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }

                            // Success message
                            if showSuccessNotion {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Successfully connected to Notion!")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                }
                                .padding(12)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }

                            // Action button
                            if notionOAuth.isAuthenticated {
                                GlowingButton(
                                    "Disconnect",
                                    icon: nil,
                                    isLoading: isConnectingNotion,
                                    style: .secondary
                                ) {
                                    disconnectNotion()
                                }
                            } else {
                                GlowingButton(
                                    "Connect Notion",
                                    icon: nil,
                                    isLoading: isConnectingNotion,
                                    style: .primary
                                ) {
                                    connectNotion()
                                }
                            }
                        }
                        .padding(24)
                    }

                    // App Settings
                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("App Settings")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            GlowingDivider(opacity: 0.08)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("App Version")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(white: 0.7))
                                    Text("1.0.0")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(white: 0.5))
                                }
                                Spacer()
                            }
                        }
                        .padding(24)
                    }
                }
                .padding(28)
            }
        }
        .background(Color.black)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Google OAuth Actions

    private func connectGoogle() {
        isConnecting = true
        errorMessage = nil
        showSuccess = false

        googleOAuth.authenticate { result in
            isConnecting = false

            switch result {
            case .success:
                showSuccess = true
                // Hide success message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSuccess = false
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func disconnectGoogle() {
        isConnecting = true
        errorMessage = nil

        googleOAuth.revokeAccess { result in
            isConnecting = false

            switch result {
            case .success:
                break
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Notion Actions

    private func connectNotion() {
        guard !notionTokenInput.isEmpty else {
            errorMessageNotion = "Please enter your Notion integration token"
            return
        }

        isConnectingNotion = true
        errorMessageNotion = nil
        showSuccessNotion = false

        notionOAuth.setInternalIntegrationToken(notionTokenInput) { result in
            isConnectingNotion = false

            switch result {
            case .success:
                showSuccessNotion = true
                notionTokenInput = "" // Clear input
                // Hide success message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSuccessNotion = false
                }
            case .failure(let error):
                errorMessageNotion = error.localizedDescription
            }
        }
    }

    private func disconnectNotion() {
        isConnectingNotion = true
        errorMessageNotion = nil

        notionOAuth.revokeAccess { result in
            isConnectingNotion = false

            switch result {
            case .success:
                break
            case .failure(let error):
                errorMessageNotion = error.localizedDescription
            }
        }
    }
}

struct ProfileInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(white: 0.5))
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(white: 0.85))
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
        .frame(width: 800, height: 600)
}
