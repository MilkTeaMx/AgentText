import SwiftUI
import FirebaseAuth

struct IntegrationDetailView: View {
    let integration: Integration
    let integrationInfo: IntegrationInfo?
    let onBack: () -> Void
    
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var googleOAuth = GoogleOAuthManager.shared
    @StateObject private var notionOAuth = NotionOAuthManager.shared
    
    @State private var apiKey = ""
    @State private var isSaving = false
    @State private var showSuccessMessage = false
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var showKey = false
    
    // OAuth states
    @State private var isConnecting = false
    @State private var oauthErrorMessage: String?
    @State private var showOAuthSuccess = false
    @State private var isConnectingNotion = false
    @State private var oauthErrorMessageNotion: String?
    @State private var showOAuthSuccessNotion = false
    @State private var notionTokenInput = ""
    
    private var isGoogleCalendar: Bool {
        integration.id == "google_calendar"
    }
    
    private var isNotion: Bool {
        integration.id == "notion"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            detailHeader
            GlowingDivider(opacity: 0.1)
            detailContent
        }
        .background(Color.black)
        .onAppear {
            loadIntegrationKey()
        }
    }
    
    private var detailHeader: some View {
        HStack {
            backButton
            Spacer()
            headerTitle
            Spacer()
        }
        .padding(28)
        .background(Color(white: 0.04))
    }
    
    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("Back")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(Color(white: 0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(integration.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(white: 0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            if let info = integrationInfo {
                Text(info.description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
            }
        }
    }
    
    @ViewBuilder
    private var detailContent: some View {
        if isLoading {
            loadingView
        } else {
            ScrollView {
                scrollContent
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                Text("Loading...")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private var scrollContent: some View {
        VStack(spacing: 24) {
            helpTextSection
            if let info = integrationInfo {
                if isGoogleCalendar || isNotion {
                    oauthConnectionSection(info: info)
                } else {
                    integrationConfigSection(info: info)
                }
            }
            if showSuccessMessage {
                successMessage
            }
            if let error = errorMessage {
                errorMessageView(error: error)
            }
        }
        .padding(28)
    }
    
    private var helpTextSection: some View {
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
    }
    
    private func integrationConfigSection(info: IntegrationInfo) -> some View {
        VStack(spacing: 20) {
            integrationLogo
            apiKeyInputSection(info: info)
        }
    }
    
    private var integrationLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .frame(width: 120, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            if let logoURL = integration.logoURL {
                AsyncImage(url: URL(string: logoURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                    case .failure:
                        fallbackIcon
                    @unknown default:
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
    }
    
    private var fallbackIcon: some View {
        Image(systemName: integration.iconName)
            .font(.system(size: 48, weight: .medium))
            .foregroundColor(Color(white: 0.6))
    }
    
    private func apiKeyInputSection(info: IntegrationInfo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            apiKeyHeader(info: info)
            apiKeyInputField(info: info)
            apiKeyHelpText(info: info)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private func apiKeyHeader(info: IntegrationInfo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: info.icon)
                .font(.system(size: 22))
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(info.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(info.description)
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
    }
    
    private func apiKeyInputField(info: IntegrationInfo) -> some View {
        HStack(spacing: 12) {
            Group {
                if showKey {
                    TextField(info.placeholder, text: $apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                } else {
                    SecureField(info.placeholder, text: $apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            
            Button(action: { showKey.toggle() }) {
                Image(systemName: showKey ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
            }
            .buttonStyle(.plain)
            
            Button(action: saveIntegrationKey) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Save")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
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
            .disabled(isSaving)
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
    }
    
    private func apiKeyHelpText(info: IntegrationInfo) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 10))
            Text(helpText(for: info.id))
                .font(.system(size: 11))
        }
        .foregroundColor(Color(white: 0.4))
    }
    
    private var successMessage: some View {
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
    
    private func errorMessageView(error: String) -> some View {
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
    
    private func loadIntegrationKey() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        Task {
            do {
                let userData = try await FirebaseService.shared.getUserData(uid: userId)
                let keys = userData?["integrationKeys"] as? [String: String] ?? [:]
                
                await MainActor.run {
                    apiKey = keys[integration.id] ?? ""
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load integration key: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func saveIntegrationKey() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not authenticated"
            return
        }
        
        isSaving = true
        showSuccessMessage = false
        errorMessage = nil
        
        Task {
            do {
                if apiKey.isEmpty {
                    try await FirebaseService.shared.removeIntegrationKey(uid: userId, integration: integration.id)
                } else {
                    try await FirebaseService.shared.updateIntegrationKey(uid: userId, integration: integration.id, apiKey: apiKey)
                }
                
                await MainActor.run {
                    isSaving = false
                    showSuccessMessage = true
                    
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
    
    // MARK: - OAuth Connection Section
    
    private func oauthConnectionSection(info: IntegrationInfo) -> some View {
        VStack(spacing: 20) {
            integrationLogo
            
            VStack(alignment: .leading, spacing: 20) {
                connectionStatusHeader(info: info)
                GlowingDivider(opacity: 0.08)
                connectionDescription(info: info)
                
                if isGoogleCalendar {
                    googleCalendarConnectionUI
                } else if isNotion {
                    notionConnectionUI
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(white: 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
    
    private func connectionStatusHeader(info: IntegrationInfo) -> some View {
        HStack {
            Image(systemName: info.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text(info.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            
            if (isGoogleCalendar && googleOAuth.isAuthenticated) || (isNotion && notionOAuth.isAuthenticated) {
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
    }
    
    private func connectionDescription(info: IntegrationInfo) -> some View {
        Group {
            if isGoogleCalendar {
                Text(googleOAuth.isAuthenticated
                    ? "Your Google Calendar is connected. You can now access your calendar events."
                    : "Connect your Google account to access Google Calendar and manage your events.")
            } else if isNotion {
                Text(notionOAuth.isAuthenticated
                    ? "Your Notion is connected. You can now access your Notion pages and databases."
                    : "Connect your Notion workspace by entering your integration token.")
            } else {
                Text(info.description)
            }
        }
        .font(.system(size: 13))
        .foregroundColor(Color(white: 0.6))
        .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    private var googleCalendarConnectionUI: some View {
        if let errorMessage = oauthErrorMessage {
            errorMessageView(error: errorMessage)
        }
        
        if showOAuthSuccess {
            successMessageView(text: "Successfully connected to Google Calendar!")
        }
        
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
    
    @ViewBuilder
    private var notionConnectionUI: some View {
        if !notionOAuth.isAuthenticated {
            notionSetupInstructions
            notionTokenInputField
        }
        
        if let errorMessage = oauthErrorMessageNotion {
            errorMessageView(error: errorMessage)
        }
        
        if showOAuthSuccessNotion {
            successMessageView(text: "Successfully connected to Notion!")
        }
        
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
    
    private var notionSetupInstructions: some View {
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
                instructionStep(
                    number: "1",
                    title: "Get your Internal Integration Secret",
                    description: "Go to https://www.notion.com/my-integrations and find your integration. Copy the 'Internal Integration Secret' (starts with 'secret_' or 'ntn_')."
                )
                
                instructionStep(
                    number: "2",
                    title: "Grant Page Access",
                    description: "In Notion, go to each page/database you want to access. Click the '...' menu → 'Add connections' → Select your integration."
                )
                
                instructionStep(
                    number: "3",
                    title: "Paste Token Below",
                    description: "Paste your integration secret token in the field below and click 'Connect Notion'."
                )
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
    
    private func instructionStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number + ".")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(white: 0.5))
                .frame(width: 20, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(white: 0.8))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.5))
            }
        }
    }
    
    private var notionTokenInputField: some View {
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
    
    private func successMessageView(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.green)
        }
        .padding(12)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - OAuth Actions
    
    private func connectGoogle() {
        isConnecting = true
        oauthErrorMessage = nil
        showOAuthSuccess = false
        
        googleOAuth.authenticate { result in
            isConnecting = false
            
            switch result {
            case .success:
                showOAuthSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showOAuthSuccess = false
                }
            case .failure(let error):
                oauthErrorMessage = error.localizedDescription
            }
        }
    }
    
    private func disconnectGoogle() {
        isConnecting = true
        oauthErrorMessage = nil
        
        googleOAuth.revokeAccess { result in
            isConnecting = false
            
            switch result {
            case .success:
                break
            case .failure(let error):
                oauthErrorMessage = error.localizedDescription
            }
        }
    }
    
    private func connectNotion() {
        guard !notionTokenInput.isEmpty else {
            oauthErrorMessageNotion = "Please enter your Notion integration token"
            return
        }
        
        isConnectingNotion = true
        oauthErrorMessageNotion = nil
        showOAuthSuccessNotion = false
        
        notionOAuth.setInternalIntegrationToken(notionTokenInput) { result in
            isConnectingNotion = false
            
            switch result {
            case .success:
                showOAuthSuccessNotion = true
                notionTokenInput = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showOAuthSuccessNotion = false
                }
            case .failure(let error):
                oauthErrorMessageNotion = error.localizedDescription
            }
        }
    }
    
    private func disconnectNotion() {
        isConnectingNotion = true
        oauthErrorMessageNotion = nil
        
        notionOAuth.revokeAccess { result in
            isConnectingNotion = false
            
            switch result {
            case .success:
                break
            case .failure(let error):
                oauthErrorMessageNotion = error.localizedDescription
            }
        }
    }
}

