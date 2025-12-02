import SwiftUI
import FirebaseAuth

struct IntegrationsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var integrationKeys: [String: String] = [:]
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSuccessMessage = false
    @State private var errorMessage: String?

    // Temporary state for editing keys
    @State private var googleCalendarKey = ""
    @State private var notionKey = ""

    // Available integrations
    let availableIntegrations = [
        IntegrationInfo(
            id: "google_calendar",
            name: "Google Calendar",
            icon: "calendar",
            description: "Access and manage your Google Calendar events",
            placeholder: "Enter your Google Calendar API key"
        ),
        IntegrationInfo(
            id: "notion",
            name: "Notion",
            icon: "doc.text",
            description: "Access and manage your Notion pages and databases",
            placeholder: "Enter your Notion integration token (secret_...)"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Integrations")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("Configure your API keys for agent integrations")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }
                Spacer()
            }
            .padding(28)
            .background(Color(white: 0.04))

            GlowingDivider(opacity: 0.1)

            // Content
            if isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    Text("Loading integrations...")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Help text
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Why do I need API keys?")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Agents use your API keys to access services on your behalf. Your keys are stored securely and only shared with agents you've installed.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(white: 0.6))
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.2), lineWidth: 1)
                                )
                        )

                        // Integrations list
                        VStack(spacing: 16) {
                            ForEach(availableIntegrations) { integration in
                                IntegrationKeyField(
                                    integration: integration,
                                    apiKey: binding(for: integration.id),
                                    onSave: {
                                        saveIntegrationKey(integration.id, key: binding(for: integration.id).wrappedValue)
                                    }
                                )
                            }
                        }

                        // Success message
                        if showSuccessMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                                Text("Integration key saved successfully")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }

                        // Error message
                        if let error = errorMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(28)
                }
            }
        }
        .background(Color.black)
        .onAppear {
            loadIntegrationKeys()
        }
    }

    private func binding(for integrationId: String) -> Binding<String> {
        switch integrationId {
        case "google_calendar":
            return $googleCalendarKey
        case "notion":
            return $notionKey
        default:
            return .constant("")
        }
    }

    private func loadIntegrationKeys() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }

        Task {
            do {
                let userData = try await FirebaseService.shared.getUserData(uid: userId)
                let keys = userData?["integrationKeys"] as? [String: String] ?? [:]

                await MainActor.run {
                    integrationKeys = keys
                    googleCalendarKey = keys["google_calendar"] ?? ""
                    notionKey = keys["notion"] ?? ""
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load integration keys: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    private func saveIntegrationKey(_ integrationId: String, key: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not authenticated"
            return
        }

        isSaving = true
        showSuccessMessage = false
        errorMessage = nil

        Task {
            do {
                if key.isEmpty {
                    // Remove the key if empty
                    try await FirebaseService.shared.removeIntegrationKey(uid: userId, integration: integrationId)
                } else {
                    // Update the key
                    try await FirebaseService.shared.updateIntegrationKey(uid: userId, integration: integrationId, apiKey: key)
                }

                await MainActor.run {
                    isSaving = false
                    showSuccessMessage = true

                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showSuccessMessage = false
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct IntegrationInfo: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let placeholder: String
}

struct IntegrationKeyField: View {
    let integration: IntegrationInfo
    @Binding var apiKey: String
    let onSave: () -> Void

    @State private var isEditing = false
    @State private var isHovered = false
    @State private var showKey = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: integration.icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(integration.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(integration.description)
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()

                if !apiKey.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                }
            }

            // API Key input
            HStack(spacing: 12) {
                if showKey {
                    TextField(integration.placeholder, text: $apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                } else {
                    SecureField(integration.placeholder, text: $apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                }

                // Show/Hide button
                Button(action: { showKey.toggle() }) {
                    Image(systemName: showKey ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }
                .buttonStyle(.plain)

                // Save button
                Button(action: onSave) {
                    Text("Save")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.4), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )

            // Help text
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 10))
                Text(helpText(for: integration.id))
                    .font(.system(size: 11))
            }
            .foregroundColor(Color(white: 0.4))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(isHovered ? 0.12 : 0.06), lineWidth: 1)
                )
        )
        .shadow(color: Color.white.opacity(isHovered ? 0.05 : 0), radius: 15)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }

    private func helpText(for integrationId: String) -> String {
        switch integrationId {
        case "google_calendar":
            return "Get your API key from the Google Calendar API console"
        case "notion":
            return "Get your token from https://www.notion.com/my-integrations"
        default:
            return "Get your API key from the service provider"
        }
    }
}

#Preview {
    IntegrationsView()
        .environmentObject(AuthManager.shared)
        .frame(width: 800, height: 600)
}
